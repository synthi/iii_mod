-- demo_keys -- minimal grid keyboard for the iii-norns mod
-- a native iii script: each pad sends a MIDI note and lights while held.
-- copy to ~/dust/data/iii/grid/ and pick it on the GRID page.

ch = 1
vel = 100
base = 36                 -- C2 at bottom-left

function note_at(x, y)
  return base + (x - 1) + (grid_size_y() - y) * 5   -- 5ths-per-row isomorphic
end

held = {}

function draw()
  grid_led_all(0)
  -- faint row guide
  for x = 1, grid_size_x() do grid_led(x, grid_size_y(), 2) end
  for k, _ in pairs(held) do
    local x = k % 32
    local y = (k - x) // 32
    grid_led(x, y, 15)
  end
  grid_refresh()
end

event_grid = function(x, y, z)
  local key = x + y * 32
  if z == 1 then
    held[key] = true
    midi_note_on(note_at(x, y), vel, ch)
  else
    held[key] = nil
    midi_note_off(note_at(x, y), 0, ch)
  end
  draw()
end

draw()
m = metro.init(draw, 0.05)
m:start()
print("demo_keys ready")
