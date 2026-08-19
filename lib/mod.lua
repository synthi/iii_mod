-- iii_mod/lib/mod.lua
-- "iii_mod" -- run native monome iii scripts on norns, as a mod.
--
-- Loads unmodified iii arc/grid scripts from ~/dust/data/iii_mod/{arc,grid}/ into an
-- iii-compatibility runtime (see iii_runtime.lua) and runs one arc + one grid
-- script in the background, independent of the foreground norns script, so they
-- can drive an old arc/grid and emit MIDI (to a norns synth via the "virtual"
-- port, or to hardware). Selection is made from SYSTEM > MODS > iii and persists.
--
-- Lifecycle note (why there are two attach paths):
--   script.clear() (every foreground script change) calls metro.free_all() and
--   grid/arc/midi.cleanup(). So our metros die and device callbacks are wiped on
--   each change. We REACQUIRE metros + rebind in script_post_init. A fresh load
--   (startup or menu selection) instead starts live metros, so it only attaches.

local mod = require 'core/mods'
local util = require 'util'
local tab = require 'tabutil'

-- folder-name-agnostic: works whether installed (via maiden `;install`) as
-- iii_mod_norns, or copied as iii_mod, etc. mod.this_name is our dust/code folder.
local NAME = mod.this_name or "iii_mod"

local Runtime = require(NAME .. '/lib/iii_runtime')
local devices = require(NAME .. '/lib/devices')
local midi_router = require(NAME .. '/lib/midi_router')
local iii_menu = require(NAME .. '/lib/iii_menu')

-- ---------------------------------------------------------------------------
-- paths

local ROOT = _path.data .. NAME .. "/"
local DIRS = { arc = ROOT .. "arc/", grid = ROOT .. "grid/" }
local PDATA = ROOT .. "pdata/"
local STATE_FILE = ROOT .. "state.lua"
local BLACKLIST_FILE = ROOT .. "blacklist.txt"
local LIB_PATH = _path.code .. NAME .. "/lib/iii_lib.lua"
local EX_DIR = _path.code .. NAME .. "/examples/"   -- bundled demos, auto-copied to data

-- ---------------------------------------------------------------------------
-- state

local state = {
  sel = { arc = nil, grid = nil },
  on = { arc = true, grid = true },
  force = { arc = false, grid = false },  -- force takeover even if foreground uses the device
  backoff = { arc = false, grid = false },-- computed: foreground owns the device
  arc_btn = "none",                       -- where the arc key-press comes from (keyless arcs)
  midi = nil,
}
local runtimes = { arc = nil, grid = nil }
local fg_cb = { grid_key = nil, arc_delta = nil, arc_key = nil } -- foreground callbacks (for restore)
local blacklist = { ["lib.lua"] = true }
local menu_active = false
local params_present = false              -- our param group currently added to the script
local sync_params                        -- fwd decl: mirrors state into the script params (assigned below)

-- arc key-press source: None, norns keys B1..B3, or a grid corner GTL/GTR/GBL/GBR
local ARC_BTN_OPTS = { "none", "B1", "B2", "B3", "GTL", "GTR", "GBL", "GBR" }

local function fire_arc_button(z)
  local rt = runtimes.arc
  if rt and rt.on then rt:on_arc_key(1, z) end
end

-- does grid (x,y) hit the corner currently chosen as the arc button?
local function arc_corner_hit(x, y)
  local src = state.arc_btn
  if not (src and src:sub(1, 1) == "G") then return false end
  if not (runtimes.arc and runtimes.arc.on) then return false end
  local g = devices.grid
  local cols = (g and g.cols and g.cols > 0) and g.cols or 16
  local rows = (g and g.rows and g.rows > 0) and g.rows or 8
  if src == "GTL" then return x == 1 and y == 1
  elseif src == "GTR" then return x == cols and y == 1
  elseif src == "GBL" then return x == 1 and y == rows
  elseif src == "GBR" then return x == cols and y == rows end
  return false
end

-- ---------------------------------------------------------------------------
-- small fs helpers

local function ensure_dir(p)
  if not util.file_exists(p) then pcall(function() util.make_dir(p) end) end
end

local function ensure_dirs()
  for _, d in ipairs({ ROOT, DIRS.arc, DIRS.grid, PDATA, PDATA .. "arc/", PDATA .. "grid/" }) do ensure_dir(d) end
  if not util.file_exists(BLACKLIST_FILE) then
    local f = io.open(BLACKLIST_FILE, "w")
    if f then
      f:write("# iii mod blacklist -- one filename per line; these won't be selectable.\n")
      f:write("# lib.lua is always excluded automatically.\n")
      f:write("# Add sibling/data files that aren't standalone scripts here, e.g. rake_data.lua\n")
      f:write("rake_data.lua\n")
      f:close()
    end
  end
end

-- copy bundled example scripts into the data folders if not already present
-- (user edits/removals of a copy are respected until the next boot re-copies a
-- missing one; delete the source in examples/ to stop it coming back)
local function copy_examples()
  for _, kind in ipairs({ "arc", "grid" }) do
    local sdir = EX_DIR .. kind .. "/"
    local ok, files = pcall(function() return util.scandir(sdir) end)
    if ok and files then
      for _, fn in ipairs(files) do
        if fn:match("%.lua$") then
          local dst = DIRS[kind] .. fn
          if not util.file_exists(dst) then
            local fi = io.open(sdir .. fn, "r")
            if fi then
              local data = fi:read("*a"); fi:close()
              local fo = io.open(dst, "w")
              if fo then fo:write(data); fo:close(); print("iii_mod: installed example " .. kind .. "/" .. fn) end
            end
          end
        end
      end
    end
  end
end

local function load_blacklist()
  blacklist = { ["lib.lua"] = true }
  if util.file_exists(BLACKLIST_FILE) then
    for line in io.lines(BLACKLIST_FILE) do
      local s = line:gsub("^%s+", ""):gsub("%s+$", "")
      if s ~= "" and s:sub(1, 1) ~= "#" then blacklist[s] = true end
    end
  end
end

local function list_scripts(kind)
  local out = {}
  local ok, files = pcall(function() return util.scandir(DIRS[kind]) end)
  if ok and files then
    for _, fn in ipairs(files) do
      if fn:match("%.lua$") and not blacklist[fn] then out[#out + 1] = fn end
    end
    table.sort(out)
  end
  return out
end

-- ---------------------------------------------------------------------------
-- persistence

local function save_state()
  state.midi = midi_router.get_state()
  local data = { sel = state.sel, on = state.on, force = state.force, arc_btn = state.arc_btn, midi = state.midi }
  pcall(function() tab.save(data, STATE_FILE) end)
end

local function load_state()
  local data
  if util.file_exists(STATE_FILE) then pcall(function() data = tab.load(STATE_FILE) end) end
  data = data or {}
  state.sel = data.sel or { arc = nil, grid = nil }
  state.on = data.on or { arc = true, grid = true }
  state.force = data.force or { arc = false, grid = false }
  state.arc_btn = data.arc_btn or "none"
  state.midi = data.midi
  if state.midi then
    midi_router.set_state(state.midi)
  else
    local d = midi_router.default_out()   -- first assigned vport, else 1
    midi_router.out.arc = d
    midi_router.out.grid = d
  end
end

-- ---------------------------------------------------------------------------
-- redraw

local function menu_redraw()
  if menu_active then pcall(function() mod.menu.redraw() end) end
end

-- ---------------------------------------------------------------------------
-- build / attach / teardown

local function backoff_active(kind)
  return state.backoff[kind] and not state.force[kind]
end

-- we need to own grid input if we route it to an iii grid script OR if the arc
-- button is a grid corner (so we can catch that corner even under a foreground
-- grid script -- our dispatcher then delegates the other keys back to it).
local function grid_corner_active()
  return (state.arc_btn and state.arc_btn:sub(1, 1) == "G") and (runtimes.arc ~= nil and runtimes.arc.on)
end

local function apply_arc_binding()
  local rt = runtimes.arc
  local take = (rt ~= nil and rt.on and not backoff_active("arc"))
  devices.bind_arc(take, fg_cb.arc_delta, fg_cb.arc_key)
  if rt and rt.on then
    if take then rt:set_suspended(false); rt:set_device(devices.get("arc")); rt:repush()
    else rt:set_suspended(true) end
  end
end

local function apply_grid_binding()
  local rt = runtimes.grid
  local take = (rt ~= nil and rt.on and not backoff_active("grid"))
  devices.bind_grid(take or grid_corner_active(), fg_cb.grid_key) -- wrapper delegates when not taking
  if rt and rt.on then
    if take then rt:set_suspended(false); rt:set_device(devices.get("grid")); rt:repush()
    else rt:set_suspended(true) end
  end
end

local function apply_bindings() apply_arc_binding(); apply_grid_binding() end

-- create + load a runtime for the current selection (starts LIVE metros), attach
local function build(kind)
  local name = state.sel[kind]
  if not name or not state.on[kind] then return false end
  local data_dir = PDATA .. kind .. "/" .. name:gsub("%.lua$", "") .. "/"
  ensure_dir(data_dir)
  local rt = Runtime.new(kind, {
    script_name = name,
    script_path = DIRS[kind] .. name,
    source_dir = DIRS[kind],
    data_dir = data_dir,
    lib_path = LIB_PATH,
    router = midi_router.for_kind(kind),
    dev = devices.get(kind),
  })
  runtimes[kind] = rt
  local ok = rt:load()
  apply_bindings()
  if not ok then print("iii: '" .. name .. "' failed to load (see above)") end
  return ok
end

local function unbuild(kind)
  local rt = runtimes[kind]
  if rt then rt:teardown() end
  runtimes[kind] = nil
  devices.clear(kind)
  apply_bindings()   -- hands the device back to the foreground (keeps our wrapper only if still needed)
end

-- re-establish everything after a foreground script change (metros were freed)
local function reassert()
  devices.connect()
  -- capture foreground device callbacks BEFORE we overwrite them
  fg_cb.grid_key = (devices.grid and devices.grid.key) or nil
  fg_cb.arc_delta = (devices.arc and devices.arc.delta) or nil
  fg_cb.arc_key = (devices.arc and devices.arc.key) or nil
  local fg_grid = devices.foreground_bound("grid")
  local fg_arc = devices.foreground_bound("arc")

  midi_router.rebind()
  devices.install_hotplug()

  state.backoff.grid = fg_grid
  state.backoff.arc = fg_arc

  for _, kind in ipairs({ "arc", "grid" }) do
    local rt = runtimes[kind]
    if rt and rt.on then rt:reacquire_metros() end
  end
  apply_bindings()
  menu_redraw()
end

-- ---------------------------------------------------------------------------
-- callback wiring (set once)

local function wire_callbacks()
  devices.on_grid_key = function(x, y, z)
    if arc_corner_hit(x, y) then fire_arc_button(z); return end -- grid corner acts as arc button
    local rt = runtimes.grid
    if rt and rt.on and not backoff_active("grid") then
      rt:on_grid_key(x, y, z)
    elseif fg_cb.grid_key then
      fg_cb.grid_key(x, y, z)  -- delegate to the foreground script's grid handler
    end
  end
  devices.on_arc_delta = function(n, d)
    local rt = runtimes.arc
    if rt and rt.on and not backoff_active("arc") then rt:on_arc_delta(n, d) end
  end
  devices.on_arc_key = function(n, z)
    local rt = runtimes.arc
    if rt and rt.on and not backoff_active("arc") then rt:on_arc_key(n, z) end
  end
  devices.on_change = function(kind)
    local rt = runtimes[kind]
    if rt and rt.on then rt:set_device(devices.get(kind)) end
    apply_bindings()
    menu_redraw()
  end
  midi_router.on_midi_in = function(kind, b1, b2, b3)
    local rt = runtimes[kind]
    if rt and rt.on then rt:dispatch_midi(b1, b2, b3) end
  end
end

-- ---------------------------------------------------------------------------
-- controller API for the menu

local ctl = {}

function ctl.list(kind) return list_scripts(kind) end
function ctl.selected(kind) return state.sel[kind] end
function ctl.is_on(kind) return state.on[kind] end
function ctl.present(kind) return devices.present(kind) end
function ctl.backoff(kind) return backoff_active(kind) end
function ctl.force(kind) return state.force[kind] end
function ctl.running(kind) local rt = runtimes[kind]; return rt ~= nil and rt.on end
function ctl.grid_size() local g = devices.grid; if g and g.cols and g.cols > 0 then return g.cols, g.rows end return nil end

function ctl.select(kind, name)   -- name == nil clears the selection
  unbuild(kind)
  state.sel[kind] = name
  if name then state.on[kind] = true end
  save_state()
  build(kind)                     -- self-guards on name/on
  sync_params()
  menu_redraw()
end

function ctl.toggle(kind)
  state.on[kind] = not state.on[kind]
  save_state()
  if state.on[kind] then
    if not runtimes[kind] then build(kind) end
  else
    unbuild(kind)
  end
  sync_params()
  menu_redraw()
end

function ctl.toggle_force(kind)
  state.force[kind] = not state.force[kind]
  save_state()
  apply_bindings()
  sync_params()
  menu_redraw()
end

function ctl.arc_button(z) fire_arc_button(z) end
function ctl.arc_btn() return state.arc_btn end
function ctl.set_arc_btn(v) state.arc_btn = v; save_state(); apply_bindings(); sync_params(); menu_redraw() end
function ctl.arc_btn_opts() return ARC_BTN_OPTS end

ctl.midi = {}
function ctl.midi.out(kind) return midi_router.out[kind] end
function ctl.midi.set_out(kind, vp) midi_router.out[kind] = vp; midi_router.rebind(); save_state(); sync_params() end
function ctl.midi.in_port(kind) return midi_router.in_port[kind] end
function ctl.midi.set_in(kind, vp) midi_router.in_port[kind] = vp; midi_router.rebind(); save_state(); sync_params() end
function ctl.midi.clock() return midi_router.clock end
function ctl.midi.set_clock(m) midi_router.clock = m; midi_router.rebind(); save_state(); sync_params() end
function ctl.midi.vport_name(i) return midi_router.vport_name(i) end

-- ---------------------------------------------------------------------------
-- script param group (added to the TOP of the running script's PARAMS via
-- script_pre_init) -- mirrors the mod menu. Actions are guarded so params:bang()
-- at script load is a no-op (defaults already equal current state).

local OFF_ON = { "off", "on" }
local CLOCK_OPTS = { "thru", "norns", "off" }
local TAKEOVER_OPTS = { "auto", "forced" }
local GROUP_N = 13   -- params inside the iii_mod group (2 devices x 5 + clock + arc_btn + arc_key)
local arc_script_opts, grid_script_opts

local function index_of(list, val, default)
  for i, v in ipairs(list) do if v == val then return i end end
  return default or 1
end

local function script_opts(kind) return (kind == "arc") and arc_script_opts or grid_script_opts end
local function script_index(kind)
  return index_of(script_opts(kind) or { "none" }, state.sel[kind] or "none", 1)
end

sync_params = function()
  if not params_present then return end
  pcall(function()
    for _, k in ipairs({ "arc", "grid" }) do
      params:set("iii_" .. k .. "_enable", state.on[k] and 2 or 1, true)
      params:set("iii_" .. k .. "_script", script_index(k), true)
      params:set("iii_" .. k .. "_out", midi_router.out[k], true)
      params:set("iii_" .. k .. "_in", midi_router.in_port[k], true)
      params:set("iii_" .. k .. "_takeover", state.force[k] and 2 or 1, true)
    end
    params:set("iii_clock", index_of(CLOCK_OPTS, midi_router.clock, 1), true)
    params:set("iii_arc_btn", index_of(ARC_BTN_OPTS, state.arc_btn, 1), true)
  end)
end

local function add_device_params(kind)
  local label = kind
  local sopts = { "none" }
  for _, n in ipairs(list_scripts(kind)) do sopts[#sopts + 1] = n end
  if kind == "arc" then arc_script_opts = sopts else grid_script_opts = sopts end

  params:add_option("iii_" .. kind .. "_enable", label .. " enable", OFF_ON, state.on[kind] and 2 or 1)
  params:set_action("iii_" .. kind .. "_enable", function(v)
    local want = (v == 2)
    if want ~= state.on[kind] then ctl.toggle(kind) end
  end)

  params:add_option("iii_" .. kind .. "_script", label .. " script", sopts, script_index(kind))
  params:set_action("iii_" .. kind .. "_script", function(v)
    local name = sopts[v]
    if name == "none" then name = nil end
    if name ~= state.sel[kind] then ctl.select(kind, name) end
  end)

  params:add { type = "number", id = "iii_" .. kind .. "_out", name = label .. " out port",
    min = 1, max = 16, default = midi_router.out[kind] }
  params:set_action("iii_" .. kind .. "_out", function(v)
    if v ~= midi_router.out[kind] then ctl.midi.set_out(kind, v) end
  end)

  params:add { type = "number", id = "iii_" .. kind .. "_in", name = label .. " in port (0=none)",
    min = 0, max = 16, default = midi_router.in_port[kind] }
  params:set_action("iii_" .. kind .. "_in", function(v)
    if v ~= midi_router.in_port[kind] then ctl.midi.set_in(kind, v) end
  end)

  params:add_option("iii_" .. kind .. "_takeover", label .. " takeover", TAKEOVER_OPTS, state.force[kind] and 2 or 1)
  params:set_action("iii_" .. kind .. "_takeover", function(v)
    local want = (v == 2)
    if want ~= state.force[kind] then ctl.toggle_force(kind) end
  end)
end

local function add_params()
  -- a collapsible sub-menu (folder) holding the next GROUP_N params
  if not pcall(function() params:add_group("iii_mod", "iii_mod", GROUP_N) end) then
    pcall(function() params:add_group("iii_mod", GROUP_N) end)
  end
  add_device_params("arc")
  add_device_params("grid")

  params:add_option("iii_clock", "iii clock", CLOCK_OPTS, index_of(CLOCK_OPTS, midi_router.clock, 1))
  params:set_action("iii_clock", function(v)
    if CLOCK_OPTS[v] ~= midi_router.clock then ctl.midi.set_clock(CLOCK_OPTS[v]) end
  end)

  params:add_option("iii_arc_btn", "arc button src", ARC_BTN_OPTS, index_of(ARC_BTN_OPTS, state.arc_btn, 1))
  params:set_action("iii_arc_btn", function(v)
    if ARC_BTN_OPTS[v] ~= state.arc_btn then ctl.set_arc_btn(ARC_BTN_OPTS[v]) end
  end)

  params:add_trigger("iii_arc_key", "arc key (K3 here)")
  params:set_action("iii_arc_key", function() fire_arc_button(1); fire_arc_button(0) end)

  params_present = true
end

-- intercept norns keys B1..B3 for the arc button, only in play mode (never in a
-- menu), never swallowing K1 (its menu behavior must survive). _norns.key is the
-- stable dispatcher and is not reset by script.clear.
local key_hooked = false
local function install_key_hook()
  if key_hooked then return end
  if type(_norns) ~= "table" or type(_norns.key) ~= "function" then return end
  local orig = _norns.key
  _norns.key = function(n, z)
    local src = state.arc_btn
    if src and src:sub(1, 1) == "B" and _menu and _menu.mode == false then
      if tonumber(src:sub(2)) == n and runtimes.arc and runtimes.arc.on then
        fire_arc_button(z)
        if n ~= 1 then return end
      end
    end
    return orig(n, z)
  end
  key_hooked = true
end

-- ---------------------------------------------------------------------------
-- mod hooks

mod.hook.register("system_post_startup", "iii-startup", function()
  ensure_dirs()
  copy_examples()
  load_blacklist()
  load_state()
  wire_callbacks()
  devices.connect()
  midi_router.rebind()
  devices.install_hotplug()
  -- fresh load of selected scripts (live metros); no foreground script yet
  state.backoff.arc = false
  state.backoff.grid = false
  for _, kind in ipairs({ "arc", "grid" }) do
    if state.sel[kind] and state.on[kind] then build(kind) end
  end
  install_key_hook()   -- wrap _norns.key once for the B1..B3 arc-button option
end)

-- add our param group at the TOP of the script's params (before its own init runs)
mod.hook.register("script_pre_init", "iii-script-pre-init", function()
  add_params()
end)

mod.hook.register("script_post_init", "iii-script-post-init", function()
  reassert()
end)

mod.hook.register("script_post_cleanup", "iii-script-post-cleanup", function()
  -- metros already freed by script.clear's metro.free_all(); MIDI still bound here
  params_present = false   -- params:clear() has (or will) wipe our group
  for _, kind in ipairs({ "arc", "grid" }) do
    local rt = runtimes[kind]
    if rt and rt.on then rt:all_notes_off(); rt:drop_real_metros() end
  end
end)

mod.hook.register("system_pre_shutdown", "iii-shutdown", function()
  for _, kind in ipairs({ "arc", "grid" }) do
    local rt = runtimes[kind]
    if rt then rt:teardown() end
    runtimes[kind] = nil
  end
end)

-- ---------------------------------------------------------------------------
-- menu registration

local base_menu = iii_menu.build(ctl)
local m = {
  init = function() menu_active = true; if base_menu.init then base_menu.init() end end,
  deinit = function() menu_active = false; if base_menu.deinit then base_menu.deinit() end end,
  key = base_menu.key,
  enc = base_menu.enc,
  redraw = base_menu.redraw,
}
mod.menu.register(mod.this_name, m)
