-- devices.lua
-- Owns the physical arc + grid for the iii mod: connects them, routes their
-- input callbacks to the current owner runtimes, tracks presence, and re-binds
-- after script.clear() runs grid.cleanup()/arc.cleanup() (which wipe callbacks).
--
-- The mod sets the on_* hooks below and decides per-device whether to bind (take
-- over input) or back off (restore the foreground script's callback). devices.lua
-- stays ignorant of runtimes. Unlike gridkeys, iii does NOT block drawing -- the
-- runtime pushes its framebuffer to the real device.

local devices = {}

devices.grid = nil
devices.arc = nil
devices.grid_present = false
devices.arc_present = false

-- set by mod (route to the owning runtime):
devices.on_grid_key = nil    -- function(x, y, z)
devices.on_arc_delta = nil   -- function(n, d)
devices.on_arc_key = nil     -- function(n, z)
devices.on_change = nil      -- function(kind)  -- hotplug notify

function devices.connect()
  if not devices.grid then devices.grid = grid.connect(1) end
  if not devices.arc then devices.arc = arc.connect(1) end
  devices._update_presence()
end

function devices._update_presence()
  local g = devices.grid
  local gp = false
  if g then
    if g.device ~= nil then gp = true
    elseif g.cols and g.cols > 0 and g.name and g.name ~= "none" then gp = true end
  end
  devices.grid_present = gp
  local a = devices.arc
  devices.arc_present = (a and (a.device ~= nil or (a.name and a.name ~= "none"))) and true or false
end

function devices._changed(kind)
  devices._update_presence()
  if devices.on_change then pcall(devices.on_change, kind) end
end

-- overwrite (idempotent, no self-wrapping) each rebind. iii owns hotplug while active.
function devices.install_hotplug()
  grid.add = function(_) devices.grid_present = true; devices._changed("grid") end
  grid.remove = function(_) devices.grid_present = false; devices._changed("grid") end
  arc.add = function(_) devices.arc_present = true; devices._changed("arc") end
  arc.remove = function(_) devices.arc_present = false; devices._changed("arc") end
end

-- true if the foreground script has bound this device's input (back-off signal).
-- Read this BEFORE calling bind_* (which overwrites the callback).
function devices.foreground_bound(kind)
  if kind == "grid" then return devices.grid ~= nil and devices.grid.key ~= nil end
  return devices.arc ~= nil and devices.arc.delta ~= nil
end

-- take over a device's input (enabled=true) or hand it back to the foreground
-- script by restoring its captured callbacks (enabled=false).
function devices.bind_grid(enabled, fg_key)
  local g = devices.grid; if not g then return end
  if enabled then
    g.key = function(x, y, z) if devices.on_grid_key then devices.on_grid_key(x, y, z) end end
  else
    g.key = fg_key
  end
end

function devices.bind_arc(enabled, fg_delta, fg_key)
  local a = devices.arc; if not a then return end
  if enabled then
    a.delta = function(n, d) if devices.on_arc_delta then devices.on_arc_delta(n, d) end end
    a.key = function(n, z) if devices.on_arc_key then devices.on_arc_key(n, z) end end
  else
    a.delta = fg_delta
    a.key = fg_key
  end
end

function devices.get(kind)
  return (kind == "grid") and devices.grid or devices.arc
end

function devices.present(kind)
  return (kind == "grid") and devices.grid_present or devices.arc_present
end

function devices.clear(kind)
  local d = devices.get(kind)
  if d then pcall(function() d:all(0); d:refresh() end) end
end

return devices
