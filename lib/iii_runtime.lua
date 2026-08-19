-- iii_runtime.lua
-- The iii-compatibility runtime: runs ONE native iii script (arc or grid) inside
-- an isolated sandbox _ENV, implementing the iii firmware "C primitives" on top of
-- norns. See the plan / README for the full design.
--
-- A Runtime owns:
--   * env         : the script's sandbox table (its globals + callbacks land here)
--   * framebuffer : arc 4x64 or grid gx*gy, honoring the additive `rel` flag
--   * vmetros     : iii virtual metros (1..12) mapped lazily to real norns metros
--   * active_notes: MIDI notes we've sent on, for guaranteed all-notes-off
--
-- Only the matching device kind is driven: an "arc" runtime's grid_* calls are
-- safe no-ops and vice versa.

local util = require 'util'

local _print = print         -- real norns print (env.print is a prefixed wrapper)
local flr = math.floor

local Runtime = {}
Runtime.__index = Runtime

-- consecutive-ish error budget before a misbehaving script is disabled
local ERROR_BUDGET = 24

-- ---------------------------------------------------------------------------
-- shared, read-only base environment (Lua stdlib subset only).
-- NOT a _G fallthrough: iii scripts probe globals by existence
-- (e.g. seq.lua: `if grid_led_all==nil`, `type(grid_intensity)`), so leaking
-- norns globals would both break those probes and hand scripts os/io/params.
local base_env = {
  string = string, math = math, table = table, coroutine = coroutine,
  pairs = pairs, ipairs = ipairs, next = next, select = select,
  type = type, tostring = tostring, tonumber = tonumber,
  error = error, assert = assert, pcall = pcall, xpcall = xpcall,
  setmetatable = setmetatable, getmetatable = getmetatable,
  rawget = rawget, rawset = rawset, rawequal = rawequal, rawlen = rawlen,
  collectgarbage = collectgarbage,
  unpack = table.unpack, -- some scripts assume the 5.1 global
}

local function nowtime()
  if util and util.time then return util.time() end
  return os.clock()
end

-- ---------------------------------------------------------------------------
-- construction

-- kind: "arc" | "grid"
-- opts: { script_path=, script_name=, source_dir=, data_dir=, lib_path=, router=, dev= }
function Runtime.new(kind, opts)
  local self = setmetatable({}, Runtime)
  self.kind = kind
  self.opts = opts or {}
  self.script_name = self.opts.script_name
  self.script_path = self.opts.script_path
  self.source_dir = self.opts.source_dir
  self.data_dir = self.opts.data_dir
  self.lib_path = self.opts.lib_path
  self.router = self.opts.router
  self.dev = self.opts.dev
  self.on = false
  self.suspended = false  -- backed off: keep running, but don't draw to the device
  self.errs = 0
  self.vmetros = {}       -- [iii_id] = {time=, count=, running=bool, real=<norns metro|nil>}
  self.active_notes = {}  -- [ch*128+note] = true
  self.ares = {1, 1, 1, 1}
  self.aacc = {0, 0, 0, 0}
  return self
end

-- ---------------------------------------------------------------------------
-- framebuffers

function Runtime:_init_fb()
  if self.kind == "arc" then
    self.afb = {}; self.ashadow = {}
    for n = 1, 4 do
      self.afb[n] = {}; self.ashadow[n] = {}
      for x = 1, 64 do self.afb[n][x] = 0; self.ashadow[n][x] = -1 end
    end
  else
    local gx, gy = 16, 8
    if self.dev and self.dev.cols and self.dev.cols > 0 then gx, gy = self.dev.cols, self.dev.rows end
    self.gx, self.gy = gx, gy
    self.gfb = {}; self.gshadow = {}
    for x = 1, gx do
      self.gfb[x] = {}; self.gshadow[x] = {}
      for y = 1, gy do self.gfb[x][y] = 0; self.gshadow[x][y] = -1 end
    end
  end
end

-- set / swap the norns device handle; resize a grid framebuffer if needed
function Runtime:set_device(dev)
  self.dev = dev
  if self.kind == "grid" and dev and dev.cols and dev.cols > 0 then
    if dev.cols ~= self.gx or dev.rows ~= self.gy then
      local ngx, ngy = dev.cols, dev.rows
      local nf, ns = {}, {}
      for x = 1, ngx do
        nf[x] = {}; ns[x] = {}
        for y = 1, ngy do
          nf[x][y] = (self.gfb and self.gfb[x] and self.gfb[x][y]) or 0
          ns[x][y] = -1
        end
      end
      self.gx, self.gy, self.gfb, self.gshadow = ngx, ngy, nf, ns
    end
  end
end

-- force a full redraw on next refresh (after attach / hotplug)
function Runtime:repush()
  if self.kind == "arc" then
    if not self.ashadow then return end
    for n = 1, 4 do for x = 1, 64 do self.ashadow[n][x] = -1 end end
    self:refresh_arc()
  else
    if not self.gshadow then return end
    for x = 1, self.gx do for y = 1, self.gy do self.gshadow[x][y] = -1 end end
    self:refresh_grid()
  end
end

-- backed off: hand LED drawing to the foreground script (metros/MIDI keep running)
function Runtime:set_suspended(b)
  self.suspended = b and true or false
  if self.suspended then self:clear_device() end
end

function Runtime:clear_device()
  local dev = self.dev
  if dev then pcall(function() dev:all(0); dev:refresh() end) end
  if self.kind == "arc" and self.afb then
    for n = 1, 4 do for x = 1, 64 do self.afb[n][x] = 0; self.ashadow[n][x] = -1 end end
  elseif self.gfb then
    for x = 1, self.gx do for y = 1, self.gy do self.gfb[x][y] = 0; self.gshadow[x][y] = -1 end end
  end
end

-- ---------------------------------------------------------------------------
-- error boundary

function Runtime:_guard(fn, label)
  local ok, err = pcall(fn)
  if not ok then
    self.errs = self.errs + 1
    _print("iii/" .. self.kind .. ": error in " .. tostring(label) .. ": " .. tostring(err))
    if self.errs >= ERROR_BUDGET then
      _print("iii/" .. self.kind .. ": error budget exceeded -> disabling")
      self:disable()
    end
  end
end

-- ---------------------------------------------------------------------------
-- metro layer (iii virtual metros -> real norns metros, lazily)

function Runtime:_metro_set(id, time, count)
  local vm = self.vmetros[id]
  if not vm then vm = { count = -1 }; self.vmetros[id] = vm end
  if (time or 0) <= 0 then                 -- iii metro:stop() sends time 0
    vm.running = false
    if vm.real then
      pcall(function() vm.real:stop() end)
      pcall(metro.free, vm.real.id)
      vm.real = nil
    end
    return
  end
  vm.time = time
  if count ~= nil then vm.count = count end -- a bare `m.time=` change carries no count; keep the old one
  vm.running = true
  self:_metro_ensure(id)
end

function Runtime:_metro_ensure(id)
  local vm = self.vmetros[id]
  if not vm or not vm.running then return end
  if not vm.real then
    local m = metro.init(function(stage) self:_metro_fire(id, stage) end, vm.time, vm.count)
    if not m then
      _print("iii/" .. self.kind .. ": metro pool exhausted (virtual id " .. tostring(id) .. ")")
      return
    end
    vm.real = m
  end
  vm.real:start(vm.time, vm.count)         -- norns :start(time,count) updates the interval
end

function Runtime:_metro_fire(id, stage)
  local env = self.env
  if env then
    self:_guard(function() if env.metro_event then env.metro_event(id, stage) end end, "metro " .. id)
  end
  local vm = self.vmetros[id]
  if vm and vm.count and vm.count > 0 and stage >= vm.count then
    vm.running = false           -- norns auto-stopped a finite metro; return slot to pool
    if vm.real then pcall(metro.free, vm.real.id); vm.real = nil end
  end
end

-- after script.clear() has freed our real metros: drop stale handles, restart the running ones
function Runtime:reacquire_metros()
  for id, vm in pairs(self.vmetros) do
    vm.real = nil
    if vm.running then self:_metro_ensure(id) end
  end
end

-- post-cleanup: metros were already freed by script.clear's metro.free_all();
-- just forget the stale handles so we never free a slot the next script reused
function Runtime:drop_real_metros()
  for _, vm in pairs(self.vmetros) do vm.real = nil end
end

-- teardown/disable when the metros are genuinely ours (no script.clear involved)
function Runtime:free_all_metros()
  for _, vm in pairs(self.vmetros) do
    if vm.real then
      pcall(function() vm.real:stop() end)
      pcall(metro.free, vm.real.id)
    end
    vm.real = nil
    vm.running = false
  end
end

-- ---------------------------------------------------------------------------
-- MIDI

function Runtime:_midi_tx(b1, b2, b3)
  if b1 then
    local st = b1 & 0xf0
    if st == 0x90 and b3 and b3 > 0 then
      self.active_notes[(b1 & 0x0f) * 128 + (b2 or 0)] = true
    elseif st == 0x80 or (st == 0x90 and (b3 == nil or b3 == 0)) then
      self.active_notes[(b1 & 0x0f) * 128 + (b2 or 0)] = nil
    end
  end
  if self.router then self.router.tx(b1, b2, b3) end
end

function Runtime:all_notes_off()
  local r = self.router
  if r then
    for key, _ in pairs(self.active_notes) do
      r.tx(0x80 + (key // 128), key % 128, 0)
    end
    for ch = 0, 15 do r.tx(0xb0 + ch, 123, 0); r.tx(0xb0 + ch, 120, 0) end
  end
  self.active_notes = {}
end

-- ---------------------------------------------------------------------------
-- LED framebuffer writes

local function lev(cur, z, rel)
  -- iii scripts sometimes pass a boolean brightness, e.g. wake's `grid_led(x,y,true)`
  -- (true = on). Coerce anything non-numeric so LED writes never throw.
  if type(z) == "boolean" then z = z and 15 or 0
  elseif type(z) ~= "number" then z = tonumber(z) or 0 end
  if type(cur) ~= "number" then cur = tonumber(cur) or 0 end
  local v = rel and (cur + z) or z
  v = flr(v + 0.5)
  if v < 0 then return 0 elseif v > 15 then return 15 else return v end
end

function Runtime:_arc_led(n, x, z, rel)
  if self.kind ~= "arc" or not (n and x) then return end
  n = flr(n); x = flr(x)
  if n < 1 or n > 4 or x < 1 or x > 64 then return end
  self.afb[n][x] = lev(self.afb[n][x], z, rel)
end

function Runtime:_arc_led_ring(n, z, rel)
  if self.kind ~= "arc" or not n then return end
  n = flr(n)
  if n < 1 or n > 4 then return end
  local row = self.afb[n]
  for x = 1, 64 do row[x] = lev(row[x], z, rel) end
end

function Runtime:_arc_led_all(z, rel)
  if self.kind ~= "arc" then return end
  for n = 1, 4 do
    local row = self.afb[n]
    for x = 1, 64 do row[x] = lev(row[x], z, rel) end
  end
end

function Runtime:refresh_arc()
  if self.kind ~= "arc" or self.suspended then return end
  local dev = self.dev
  if not dev then return end
  local fb, sh = self.afb, self.ashadow
  for n = 1, 4 do
    local fbn, shn = fb[n], sh[n]
    for x = 1, 64 do
      if fbn[x] ~= shn[x] then shn[x] = fbn[x]; dev:led(n, x, fbn[x]) end
    end
  end
  pcall(function() dev:refresh() end)
end

function Runtime:_grid_led(x, y, z, rel)
  if self.kind ~= "grid" or not (x and y) then return end
  x = flr(x); y = flr(y)
  if x < 1 or x > self.gx or y < 1 or y > self.gy then return end
  self.gfb[x][y] = lev(self.gfb[x][y], z, rel)
end

function Runtime:_grid_led_all(z, rel)
  if self.kind ~= "grid" then return end
  for x = 1, self.gx do
    local col = self.gfb[x]
    for y = 1, self.gy do col[y] = lev(col[y], z, rel) end
  end
end

function Runtime:_grid_led_get(x, y)
  if self.kind ~= "grid" or not (x and y) then return 0 end
  x = flr(x); y = flr(y)
  if x < 1 or x > self.gx or y < 1 or y > self.gy then return 0 end
  return self.gfb[x][y]
end

function Runtime:refresh_grid()
  if self.kind ~= "grid" or self.suspended then return end
  local dev = self.dev
  if not dev then return end
  local fb, sh = self.gfb, self.gshadow
  for x = 1, self.gx do
    local fbx, shx = fb[x], sh[x]
    for y = 1, self.gy do
      if fbx[y] ~= shx[y] then shx[y] = fbx[y]; dev:led(x, y, fbx[y]) end
    end
  end
  pcall(function() dev:refresh() end)
end

-- ---------------------------------------------------------------------------
-- filesystem primitives (scoped: read = data_dir then source_dir; write = data_dir)

function Runtime:_resolve_read(name)
  if self.data_dir then
    local p = self.data_dir .. name
    local f = io.open(p, "r"); if f then f:close(); return p end
  end
  if self.source_dir then
    local p = self.source_dir .. name
    local f = io.open(p, "r"); if f then f:close(); return p end
  end
  return nil
end

function Runtime:_fs_read(name)
  local p = self:_resolve_read(name); if not p then return nil end
  local f = io.open(p, "r"); if not f then return nil end
  local s = f:read("*a"); f:close(); return s
end

function Runtime:_fs_write(name, str)
  if not self.data_dir then return end
  local f = io.open(self.data_dir .. name, "w"); if not f then return end
  f:write(str or ""); f:close()
end

function Runtime:_fs_remove(name)
  if self.data_dir then os.remove(self.data_dir .. name) end
end

function Runtime:_fs_list()
  local seen, out = {}, {}
  local function add(dir)
    if not dir then return end
    local ok, files = pcall(function() return util.scandir(dir) end)
    if ok and files then
      for _, fn in ipairs(files) do
        if not seen[fn] then seen[fn] = true; out[#out + 1] = fn end
      end
    end
  end
  add(self.data_dir)
  add(self.source_dir)
  return out
end

function Runtime:_fs_run(name)
  local p = self:_resolve_read(name); if not p then return nil end
  local f = io.open(p, "r"); if not f then return nil end
  local src = f:read("*a"); f:close()
  local chunk, err = load(src, "@" .. name, "t", self.env)
  if not chunk then _print("iii/" .. self.kind .. ": fs_run_file(" .. name .. "): " .. tostring(err)); return nil end
  local ok, ret = pcall(chunk)
  if not ok then _print("iii/" .. self.kind .. ": fs_run_file(" .. name .. "): " .. tostring(ret)); return nil end
  return ret
end

-- ---------------------------------------------------------------------------
-- environment construction + primitive injection

function Runtime:_build_env()
  local env = setmetatable({}, { __index = base_env })
  self.env = env
  local S = self

  env.print = function(...) return _print("iii/" .. S.kind .. ":", ...) end
  env.get_time = function() return nowtime() end
  env.device_id = function() return (S.dev and S.dev.name) or S.kind end

  -- MIDI
  env.midi_tx = function(b1, b2, b3) S:_midi_tx(b1, b2, b3) end
  -- metro
  env.metro_set = function(id, time, count) S:_metro_set(id, time, count) end

  -- arc LEDs
  env.arc_led = function(n, x, z, rel) S:_arc_led(n, x, z, rel) end
  env.arc_led_ring = function(n, z, rel) S:_arc_led_ring(n, z, rel) end
  env.arc_led_all = function(z, rel) S:_arc_led_all(z, rel) end
  env.arc_refresh = function() S:refresh_arc() end
  env.arc_res = function(n, div) if n and n >= 1 and n <= 4 then S.ares[n] = (div and div >= 1) and div or 1 end end
  env.arc_intensity = function(_) end -- norns arc has no global-intensity API

  -- grid LEDs
  env.grid_led = function(x, y, z, rel) S:_grid_led(x, y, z, rel) end
  env.grid_led_all = function(z, rel) S:_grid_led_all(z, rel) end
  env.grid_led_get = function(x, y) return S:_grid_led_get(x, y) end
  env.grid_refresh = function() S:refresh_grid() end
  env.grid_intensity = function(b) if S.dev and S.dev.intensity then pcall(function() S.dev:intensity(b) end) end end
  env.grid_size_x = function() return S.gx or 0 end
  env.grid_size_y = function() return S.gy or 0 end

  -- filesystem
  env.fs_write_file = function(name, str) S:_fs_write(name, str) end
  env.fs_read_file = function(name) return S:_fs_read(name) end
  env.fs_remove_file = function(name) S:_fs_remove(name) end
  env.fs_list_files = function() return S:_fs_list() end
  env.fs_run_file = function(name) return S:_fs_run(name) end

  return env
end

function Runtime:_load_source(path, name)
  local f = io.open(path, "r")
  if not f then return false, "cannot open " .. tostring(path) end
  local src = f:read("*a"); f:close()
  local chunk, err = load(src, name, "t", self.env)
  if not chunk then return false, err end
  local ok, ret = pcall(chunk)
  if not ok then return false, ret end
  return true, ret
end

-- ---------------------------------------------------------------------------
-- lifecycle

function Runtime:load()
  self.on = true
  self.errs = 0
  self.vmetros = {}
  self.active_notes = {}
  self.ares = {1, 1, 1, 1}
  self.aacc = {0, 0, 0, 0}
  self:_init_fb()
  self:_build_env()

  local ok, err = self:_load_source(self.lib_path, "@iii_lib")
  if not ok then
    _print("iii/" .. self.kind .. ": FAILED to load iii_lib: " .. tostring(err))
    self.on = false
    return false, err
  end

  ok, err = self:_load_source(self.script_path, "@" .. (self.script_name or "script"))
  if not ok then
    _print("iii/" .. self.kind .. ": script error: " .. tostring(err))
    self:all_notes_off()
    self.on = false
    return false, err
  end

  collectgarbage()
  return true
end

-- stop everything but keep the env (recoverable by re-selecting)
function Runtime:disable()
  if self._disabled then return end
  self._disabled = true
  self.on = false
  self:free_all_metros()
  pcall(function() if self.env and self.env.cleanup then self.env.cleanup() end end)
  self:all_notes_off()
  self:clear_device()
end

-- full teardown; drop the env. Safe only when NOT in a script.clear transition.
function Runtime:teardown()
  self.on = false
  self:free_all_metros()
  pcall(function() if self.env and self.env.cleanup then self.env.cleanup() end end)
  pcall(function() if self.env and self.env.slew then self.env.slew.allstop() end end)
  self:all_notes_off()
  self:clear_device()
  self.env = nil
  collectgarbage()
end

-- ---------------------------------------------------------------------------
-- input dispatch (guarded)

function Runtime:dispatch_grid(x, y, z)
  if self.kind ~= "grid" then return end
  local fn = self.env and self.env.event_grid
  if type(fn) == "function" then self:_guard(function() fn(x, y, z) end, "event_grid") end
end

function Runtime:dispatch_arc(n, d)
  if self.kind ~= "arc" then return end
  local fn = self.env and self.env.event_arc
  if type(fn) == "function" then self:_guard(function() fn(n, d) end, "event_arc") end
end

-- snows.lua defines event_arc_key(z) [1 arg]; rake.lua defines (a,b) [2 args].
function Runtime:dispatch_arc_key(n, z)
  if self.kind ~= "arc" then return end
  local fn = self.env and self.env.event_arc_key
  if type(fn) ~= "function" then return end
  local np = 2
  local ok, info = pcall(debug.getinfo, fn, "u")
  if ok and info and info.nparams and not info.isvararg then np = info.nparams end
  self:_guard(function() if np == 1 then fn(z) else fn(n, z) end end, "event_arc_key")
end

function Runtime:dispatch_midi(b1, b2, b3)
  local fn = self.env and self.env.event_midi
  if type(fn) == "function" then self:_guard(function() fn(b1, b2, b3) end, "event_midi") end
end

-- raw arc encoder in from norns; apply arc_res divisor then dispatch
function Runtime:on_arc_delta(n, d)
  if self.kind ~= "arc" or not n then return end
  local div = self.ares[n] or 1
  if div <= 1 then self:dispatch_arc(n, d); return end
  self.aacc[n] = (self.aacc[n] or 0) + d
  local a = self.aacc[n]
  local step = (a >= 0) and flr(a / div) or -flr(-a / div)
  if step ~= 0 then
    self.aacc[n] = a - step * div
    self:dispatch_arc(n, step)
  end
end

function Runtime:on_arc_key(n, z) self:dispatch_arc_key(n, z) end
function Runtime:on_grid_key(x, y, z) self:dispatch_grid(x, y, z) end

return Runtime
