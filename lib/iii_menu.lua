-- iii_menu.lua
-- SYSTEM > MODS > iii_mod screen UI.
--
-- Navigation uses only E2/E3/K2/K3 (E1/K1 are reserved by the norns menu):
--   the TOP row is the tab selector. E2 moves the cursor (tab row + page rows),
--   E3 changes the focused thing (on the tab row it switches ARC/GRID/MIDI),
--   K3 activates it, K2 exits.

local mod = require 'core/mods'
local util = require 'util'

local iii_menu = {}

function iii_menu.build(ctl)
  local PAGES = { "arc", "grid", "midi" }
  local PAGE_LABEL = { arc = "ARC", grid = "GRID", midi = "MIDI" }
  local CLOCKS = { "thru", "norns", "off" }

  local pi = 1      -- page index
  local cur = 1     -- 1 = tab row; 2..n = page rows

  local function cycle(list, val, dir)
    local idx = 1
    for i, v in ipairs(list) do if v == val then idx = i break end end
    idx = ((idx - 1 + (dir > 0 and 1 or -1)) % #list) + 1
    return list[idx]
  end

  local function trunc(s, n) if #s > n then return s:sub(1, n) end return s end
  local function portlabel(vp)
    if not vp or vp == 0 then return "none" end
    return vp .. ":" .. trunc(ctl.midi.vport_name(vp), 11)
  end
  -- step a vport within [lo,16], wrapping (lo=1 for out, lo=0 for in where 0=none)
  local function stepport(vp, dir, lo)
    local n = (vp or lo) + (dir > 0 and 1 or -1)
    if n < lo then n = 16 elseif n > 16 then n = lo end
    return n
  end

  local function midi_port_row(label, getf, setf, lo)
    return {
      text = function() return label .. ": " .. portlabel(getf()) end,
      e3 = function(d) if d ~= 0 then setf(stepport(getf(), d, lo)) end end,
      k3 = function(z) if z == 1 then setf(stepport(getf(), 1, lo)) end end,
    }
  end

  -- rows for a page (NOT including the tab row). each row:
  --   text=function()->string, k3=function(z), e3=function(d)
  local function rows_for(page)
    local rows = {}
    if page == "arc" or page == "grid" then
      rows[#rows + 1] = {
        text = function() return "power: " .. (ctl.is_on(page) and "on" or "off") end,
        k3 = function(z) if z == 1 then ctl.toggle(page) end end,
        e3 = function(d) if d ~= 0 then ctl.toggle(page) end end,
      }
      rows[#rows + 1] = {
        text = function() return "takeover: " .. (ctl.force(page) and "forced" or "auto") end,
        k3 = function(z) if z == 1 then ctl.toggle_force(page) end end,
        e3 = function(d) if d ~= 0 then ctl.toggle_force(page) end end,
      }
      if page == "arc" then
        rows[#rows + 1] = {
          text = function() return "arc btn src: " .. ctl.arc_btn() end,
          e3 = function(d) if d ~= 0 then ctl.set_arc_btn(cycle(ctl.arc_btn_opts(), ctl.arc_btn(), d)) end end,
          k3 = function(z) if z == 1 then ctl.set_arc_btn(cycle(ctl.arc_btn_opts(), ctl.arc_btn(), 1)) end end,
        }
        rows[#rows + 1] = { text = function() return "arc button (hold K3)" end, k3 = function(z) ctl.arc_button(z) end }
      end
      local list = ctl.list(page)
      if #list == 0 then
        rows[#rows + 1] = { text = function() return "(drop .lua in data/iii_mod/" .. page .. ")" end }
      else
        for _, name in ipairs(list) do
          rows[#rows + 1] = {
            text = function()
              local mark = "  "
              if ctl.selected(page) == name then mark = ctl.running(page) and "* " or "o " end
              return mark .. name:gsub("%.lua$", "")
            end,
            k3 = function(z) if z == 1 then ctl.select(page, name) end end,
          }
        end
      end
    else -- midi
      rows[#rows + 1] = {
        text = function() return "route: " .. ctl.midi.route() end,
        e3 = function(d) if d ~= 0 then ctl.midi.set_route(cycle(ctl.midi.routes(), ctl.midi.route(), d)) end end,
        k3 = function(z) if z == 1 then ctl.midi.set_route(cycle(ctl.midi.routes(), ctl.midi.route(), 1)) end end,
      }
      rows[#rows + 1] = midi_port_row("arc out", function() return ctl.midi.out("arc") end,
        function(v) ctl.midi.set_out("arc", v) end, 1)
      rows[#rows + 1] = midi_port_row("arc in", function() return ctl.midi.in_port("arc") end,
        function(v) ctl.midi.set_in("arc", v) end, 0)
      rows[#rows + 1] = midi_port_row("grid out", function() return ctl.midi.out("grid") end,
        function(v) ctl.midi.set_out("grid", v) end, 1)
      rows[#rows + 1] = midi_port_row("grid in", function() return ctl.midi.in_port("grid") end,
        function(v) ctl.midi.set_in("grid", v) end, 0)
      rows[#rows + 1] = {
        text = function() return "clock: " .. ctl.midi.clock() end,
        e3 = function(d) if d ~= 0 then ctl.midi.set_clock(cycle(CLOCKS, ctl.midi.clock(), d)) end end,
        k3 = function(z) if z == 1 then ctl.midi.set_clock(cycle(CLOCKS, ctl.midi.clock(), 1)) end end,
      }
    end
    return rows
  end

  local function status(page)
    if page == "midi" then return "" end
    if not ctl.present(page) then return "no dev" end
    if ctl.backoff(page) then return "backoff" end
    if ctl.running(page) then return "run" end
    return "idle"
  end

  local m = {}
  m.init = function() end
  m.deinit = function() end

  m.enc = function(n, d)
    if n == 2 then
      local total = 1 + #rows_for(PAGES[pi])
      cur = util.clamp(cur + (d > 0 and 1 or -1), 1, total)
    elseif n == 3 then
      if cur == 1 then
        pi = ((pi - 1 + (d > 0 and 1 or -1)) % #PAGES) + 1
        cur = 1
      else
        local r = rows_for(PAGES[pi])[cur - 1]
        if r and r.e3 then r.e3(d) end
      end
    end
    mod.menu.redraw()
  end

  m.key = function(n, z)
    if n == 2 and z == 1 then mod.menu.exit(); return end
    if n == 3 then
      if cur == 1 then
        if z == 1 then pi = (pi % #PAGES) + 1; cur = 1 end
      else
        local r = rows_for(PAGES[pi])[cur - 1]
        if r and r.k3 then r.k3(z) end
      end
      mod.menu.redraw()
    end
  end

  m.redraw = function()
    local page = PAGES[pi]
    local prows = rows_for(page)
    local total = 1 + #prows
    if cur > total then cur = total end
    screen.clear()

    -- tab row (cursor position 1)
    screen.move(0, 8)
    if cur == 1 then screen.level(15); screen.text(">") end
    screen.move(8, 8)
    for i = 1, #PAGES do
      screen.level(i == pi and 15 or 3)
      screen.text(PAGE_LABEL[PAGES[i]] .. " ")
    end
    local st = status(page)
    if st ~= "" then screen.level(3); screen.move(128, 8); screen.text_right(st) end

    -- page rows (scrolling window of 5)
    local VIS = 5
    local ys = { 18, 27, 36, 45, 54 }
    local rowcur = (cur >= 2) and (cur - 1) or 0
    local top = 1
    if #prows > VIS and rowcur > 0 then top = util.clamp(rowcur - 2, 1, #prows - VIS + 1) end
    for i = 1, VIS do
      local ri = top + i - 1
      local r = prows[ri]
      if r then
        local sel = (ri == rowcur)
        screen.level(sel and 15 or 4)
        screen.move(0, ys[i]); if sel then screen.text(">") end
        screen.move(8, ys[i]); screen.text(r.text())
      end
    end
    screen.update()
  end

  return m
end

return iii_menu
