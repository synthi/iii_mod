-- midi_router.lua
-- Per-device MIDI plumbing. arc and grid each get their OWN output port and
-- input port (they're often doing very different things), chosen by norns vport
-- (1..16) exactly like any norns script. No "virtual vs hardware" abstraction --
-- if you've assigned norns' "virtual" device to a vport, just pick that vport
-- (and set the receiving script's MIDI-in to the same one).
--
-- rebind() must run at startup AND on every script_post_init, because
-- script.clear() -> midi.cleanup()/clock.cleanup() wipes callbacks + coroutines.

local midi_router = {}

midi_router.out = { arc = 1, grid = 1 }     -- output vport per device (1..16)
midi_router.in_port = { arc = 0, grid = 0 } -- input vport per device (0 = none)
midi_router.clock = "thru"                  -- "thru" | "norns" | "off"
midi_router.on_midi_in = nil                -- function(kind, b1, b2, b3), set by mod

local out_conns = {}   -- [vport] = midi handle
local in_conns = {}    -- [vport] = midi handle
local clock_id = nil

local KINDS = { "arc", "grid" }

-- ---------------------------------------------------------------------------
-- vport helpers

function midi_router.vport_name(i)
  if i == nil or i < 1 or i > 16 then return "none" end
  local vp = midi.vports and midi.vports[i]
  if not vp then return "none" end
  return vp.name or "none"
end

function midi_router.vport_list()
  local t = {}
  for i = 1, 16 do t[i] = { i = i, name = midi_router.vport_name(i) } end
  return t
end

-- first assigned (non-"none") vport, else 1 -- used as a sensible first-run default
function midi_router.default_out()
  for i = 1, 16 do
    local n = midi_router.vport_name(i)
    if n and n ~= "none" then return i end
  end
  return 1
end

-- ---------------------------------------------------------------------------
-- output

local function out_conn(vp)
  if not vp or vp < 1 or vp > 16 then return nil end
  if not out_conns[vp] then out_conns[vp] = midi.connect(vp) end
  return out_conns[vp]
end

-- is this vport assigned to a norns "virtual" device?
local function vport_virtual(vp)
  local vport = midi.vports and midi.vports[vp]
  if not vport then return false, nil end
  local nm = vport.name
  return (nm and nm:lower():find("virt")) and true or false, vport
end

function midi_router.tx(kind, b1, b2, b3)
  if b1 == nil then return end
  local vp = midi_router.out[kind]
  local data
  if b3 ~= nil then data = { b1, b2, b3 }
  elseif b2 ~= nil then data = { b1, b2 }
  else data = { b1 } end
  local is_virt, vport = vport_virtual(vp)
  if is_virt then
    -- Deliver in-process to whatever norns script listens on this virtual port.
    -- norns' virtual send-loopback is unreliable; calling the vport's event is how
    -- gridkeys reliably feeds another script. No-op if nobody is listening yet.
    if vport and vport.event then pcall(function() vport.event(data) end) end
  else
    local c = out_conn(vp)
    if c then pcall(function() c:send(data) end) end
  end
end

-- a per-kind sink handed to each Runtime (its midi_tx routes here)
function midi_router.for_kind(kind)
  return { tx = function(b1, b2, b3) midi_router.tx(kind, b1, b2, b3) end }
end

function midi_router.all_notes_off()
  for _, kind in ipairs(KINDS) do
    for ch = 0, 15 do midi_router.tx(kind, 0xb0 + ch, 123, 0); midi_router.tx(kind, 0xb0 + ch, 120, 0) end
  end
end

-- ---------------------------------------------------------------------------
-- input

local function on_in(vport, data)
  if not data or not data[1] then return end
  local b1 = data[1]
  if midi_router.clock ~= "thru" then
    if b1 == 0xF8 or b1 == 0xFA or b1 == 0xFB or b1 == 0xFC then return end
  end
  if not midi_router.on_midi_in then return end
  for _, kind in ipairs(KINDS) do
    if midi_router.in_port[kind] == vport then
      midi_router.on_midi_in(kind, b1, data[2], data[3])
    end
  end
end

function midi_router._rebind_in()
  local want = {}
  for _, kind in ipairs(KINDS) do
    local vp = midi_router.in_port[kind]
    if vp and vp >= 1 then want[vp] = true end
  end
  for vp = 1, 16 do
    if want[vp] then
      local c = in_conns[vp] or midi.connect(vp)
      in_conns[vp] = c
      c.event = function(data) on_in(vp, data) end
    elseif in_conns[vp] then
      in_conns[vp].event = function() end
    end
  end
end

-- ---------------------------------------------------------------------------
-- clock

function midi_router._rebind_clock()
  if clock_id then pcall(function() clock.cancel(clock_id) end); clock_id = nil end
  if midi_router.clock == "norns" then
    clock_id = clock.run(function()
      while true do
        clock.sync(1 / 24)
        if midi_router.on_midi_in then
          midi_router.on_midi_in("arc", 0xF8)
          midi_router.on_midi_in("grid", 0xF8)
        end
      end
    end)
  end
end

-- ---------------------------------------------------------------------------
-- lifecycle

function midi_router.rebind()
  for _, kind in ipairs(KINDS) do out_conn(midi_router.out[kind]) end
  midi_router._rebind_in()
  midi_router._rebind_clock()
end

-- ---------------------------------------------------------------------------
-- state (persistence + menu)

function midi_router.get_state()
  return {
    out = { arc = midi_router.out.arc, grid = midi_router.out.grid },
    in_port = { arc = midi_router.in_port.arc, grid = midi_router.in_port.grid },
    clock = midi_router.clock,
  }
end

function midi_router.set_state(t)
  if type(t) ~= "table" then return end
  if t.out then
    midi_router.out.arc = t.out.arc or midi_router.out.arc
    midi_router.out.grid = t.out.grid or midi_router.out.grid
  end
  if t.in_port then
    midi_router.in_port.arc = t.in_port.arc or 0
    midi_router.in_port.grid = t.in_port.grid or 0
  end
  if t.clock then midi_router.clock = t.clock end
end

return midi_router
