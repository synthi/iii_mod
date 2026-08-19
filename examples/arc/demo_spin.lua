-- demo_spin -- minimal arc demo for the iii-norns mod
-- a native iii script: turn a ring to set its spin speed; a dot orbits and each
-- lap fires a MIDI note (one channel per ring). push (or the menu arc-button)
-- stops all rings. copy to ~/dust/data/iii/arc/ and pick it on the ARC page.

scale = {0, 2, 4, 5, 7, 9, 11}   -- major
root = 48

sp = {0, 0, 0, 0}                 -- speed per ring (segments/frame)
pos = {0, 0, 0, 0}
last = {}                         -- last note sounding per ring

for i = 1, 4 do arc_res(i, 2) end -- coarser encoder feel

function note_for(n)
  local deg = scale[((n - 1) % #scale) + 1]
  return root + (n - 1) * 3 + deg
end

function fire(n)
  if last[n] then midi_note_off(last[n], 0, n) end
  local nn = note_for(n)
  midi_note_on(nn, 100, n)
  last[n] = nn
end

function tick()
  arc_led_all(0)
  for n = 1, 4 do
    local prev = pos[n]
    pos[n] = (pos[n] + sp[n]) % 64
    if sp[n] ~= 0 and pos[n] < prev then fire(n) end   -- wrapped a lap
    for x = 1, 64, 8 do arc_led(n, x, 3) end            -- tick marks
    arc_led(n, math.floor(pos[n]) + 1, 15)             -- the dot
  end
  arc_refresh()
end

event_arc = function(n, d) sp[n] = clamp(sp[n] + d, -8, 8) end

event_arc_key = function(n, z)
  if z == 1 then
    for i = 1, 4 do
      sp[i] = 0
      if last[i] then midi_note_off(last[i], 0, i); last[i] = nil end
    end
  end
end

m = metro.init(tick, 0.03)
m:start()
print("demo_spin ready")
