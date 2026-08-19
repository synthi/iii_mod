-- rake_data.lua — data tables + shared render helpers for rake.lua (SCALES,
-- LED designs, piano()/root_scale_view()). Helpers call rake.lua globals (L,
-- root, ...), resolved at call time, so this loading first is fine.
-- loaded by rake.lua via fs_run_file; flash both files to the device.

-- DATA AS BYTE STRINGS: dozens of tiny tables cost a table header + rounded
-- array each; a string is one object read with :byte(i). Formats:
--   pairs (rgroup)    = startLED,count per entry
--   lists (rlist)     = LED bytes, \0 between groups
--   LO/HI (rglyph)    = one byte per selection index
--   flags             = "0"/"1" chars (:byte(i) == 49 tests)
QPULSE = "\3\6\12\24\96" -- quantize grid (32nd..bar) in MIDI-clock pulses; /24 = beats
SPOFS = "\4\3\2\1\0"                -- spread octave offset: :byte(sp) - 2

SCALES = { -- interval bytes per scale; #s = note count
  "\0\2\4\5\7\9\11",
  "\0\2\3\5\7\8\10",
  "\0\2\3\5\7\9\10",
  "\0\2\4\5\7\9\10",
  "\0\2\4\6\7\9\11",
  "\0\1\3\5\7\8\10",
  "\0\2\4\7\9",
  "\0\3\5\7\10",
}

FTICK = "10010010001000010000010000001000000010000000100000111" -- ruler ticks, idx p+1

-- editor param rings (LED_Design/): DEG/NN/ROT rgroup pairs; SPREAD/OCTL rlist
DEG = "\49\1\46\2\42\3\37\4\31\5\24\6\16\7"
NN = "\38\1\35\2\31\3\26\4" -- sel 0 = off (all dim)
ROT = "\1\1\13\1\26\2\37\3\50\4" -- sel = rot+1
SPREAD = "\19\21\0\26\0\32\33\34\0\40\0\45\47\0\63\64\2\3" -- sp 1..6 (+2..-2,UD)
OCTL = "\45\46\48\49\0\40\41\0\32\33\34\0\25\26\0\17\18\20\21" -- by oct+3

-- main-page param designs (LED_Design/Main-*): rlist markers
TRANSP = "\38\39\0\36\0\32\33\34\0\30\0\27\28" -- STRUM r3 by xpose+3
OCTR = "\39\0\36\37\0\32\33\34\0\27\28\29\30"  -- SEQ r3 by arange
-- glyph strips (rglyph): hex brightness over LEDs, selected span [lo,hi] bright.
STYPAT = "4f0f404ff40f44f0fa0af0f6a0af60f6aaf6044f04af0f440fa400fff01f7fa0"
STY_LO = "\1\4\7\12\17\20\23\27\31\38\42\46\50\55\59" -- SEQ r2 by style
STY_HI = "\2\5\10\15\18\21\25\29\36\40\44\48\52\57\63"
SHPAT = "0000000000000000000f2f033f0f3303af0fa30afa0faf"
SHP_LO = "\44\40\36\32\28\24\20" -- LFO r2 by lfo_shape: 1=sine 2=tri 3=saw up
SHP_HI = "\46\42\38\34\30\26\22" -- 4=saw dn 5,6=chord saws 7=square
-- top-track fill arc (render_fill): p=0..52 -> LED 39 CW to 27. SEQ r4 gate,
-- LFO r4 depth. GATEB baseline (unfilled), GATEF the filled gradient.
GATEB = "f1111111111111222222222222522222222222233333333333335"
GATEF = "71122223334444555566677778c89999aaabbbbccccdddeeeefff"
-- settings page 2. quantize (r2) glyph strip over LEDs 17..49, span by qdiv+1.
QPAT = "00000000000000006606606f0ff06ff0f0666f066f60ff0ff"
QZ_LO = "\17\23\29\35\40\45"
QZ_HI = "\22\28\34\39\44\49"
-- BPM (r4) + quantize-amount (r3): fill arc on the LED 39+p track (p=0..50 ->
-- LED 40 CW to 26). *B baseline / *F filled gradient; render_fill draws cursor.
BPMB = "f11114111141122522225222262222622227223373333833338"
BPMF = "b1222c3334c4455d5666d7778e8999faaabfbbccfcdddfeeeff"
QAB = "f11111111111122222222222263333333333332222222222228"
QAF = "b112223333444555666677788e88999aaaabbbcccddddeeefff"
-- external-sync indicator (BPM r4, shown when q_ext): led,bright byte pairs
EXTSYNC = "\29\15\30\10\31\6\33\15\34\10\36\15"
-- settings r2 scale-select: 8 groups of 3 LEDs = binary(scale-1), on=f off=8.
-- rendered by two rglyph calls (LEDs 50..64 and 2..16). SC_LO/HI = selected span.
SCPAT = "0f880f8f0ff80fff000000000000000000000000000000000888088f08f808ff"
SC_LO = "\50\54\58\62\2\6\10\14"
SC_HI = "\52\56\60\64\4\8\12\16"
-- engine-select glyphs (LED_Design/Mode-Select.json): led,bright byte pairs per
-- engine 1..4 = strum / strum-reset / chimes / wind, laid out CCW
MGLYPH = { "\40\15", "\36\15\37\15", "\30\10\31\10\32\15\33\10", "\24\10\25\15\27\15" }
VOICEPAT = "0000f3f393f333f0f33ff3f3f0ff3f3f0ff3ff0ff33f0f33ff0f333f0f3f3f00"
VOIC_LO = "\58\52\46\40\34\27\17\5"
VOIC_HI = "\62\56\50\44\38\32\25\15"

-- editor ring 1 piano octave: KEYL = LED per key 0..12 (idx key+1, low C 43 ..
-- high C 24); WHITEK "1" = white key. WSLOT = MIDI-in white key -> slot (idx
-- d+1, 0 = black); BXPOSE = black key -> transpose+3 (idx d+1, 0 = white).
KEYL = "\43\41\40\38\37\35\33\32\30\29\27\26\24"
WHITEK = "1010110101011"
WSLOT = "\1\0\2\0\3\4\0\5\0\6\0\7\8"
BXPOSE = "\0\1\0\2\0\0\3\0\4\0\5\0\0"

-- arp style -> note order, written into SEQIDX; returns the pattern length.
-- (moved from rake.lua for source-size budget; SEQIDX/SEQMAX are rake globals)
function seq_pattern(st, n)
  local s, m = SEQIDX, 0
  local function put(i) if m < SEQMAX then m = m + 1 s[m] = i end end
  local function run(a, b, c) for i = a, b, c do put(i) end end
  if st == 1 then run(1, n, 1)
  elseif st == 2 then run(n, 1, -1)
  elseif st == 3 then run(1, n, 1) run(n - 1, 2, -1)
  elseif st == 4 then run(n, 1, -1) run(2, n - 1, 1)
  elseif st == 5 then run(1, n, 1) run(n, 1, -1)
  elseif st == 6 then run(n, 1, -1) run(1, n, 1)
  elseif st <= 9 then
    local lo, hi = 1, n
    while lo <= hi do
      put(lo)
      if hi ~= lo then put(hi) end
      lo = lo + 1 hi = hi - 1
    end
    if st == 8 then
      for i = 1, m // 2 do s[i], s[m + 1 - i] = s[m + 1 - i], s[i] end
    elseif st == 9 then
      for i = m - 1, 2, -1 do put(s[i]) end
    end
  elseif st == 10 then for k = 1, n - 1 do put(k) put(n) end
  elseif st == 11 then
    for k = 1, n - 1 do put(k) put(n) end
    for k = n - 2, 2, -1 do put(k) put(n) end
  elseif st == 12 then for k = 2, n do put(1) put(k) end
  elseif st == 13 then
    for k = 2, n do put(1) put(k) end
    for k = n - 1, 3, -1 do put(1) put(k) end
  elseif st == 15 then
    for i = 1, n do s[i] = i end
    m = n
    for i = n, 2, -1 do
      local j = math.random(i)
      s[i], s[j] = s[j], s[i]
    end
  end
  return m
end

-- ring 2 morph detent: hold for a moment after a turn, then ease pmorph onto the
-- nearest chord slot (so the crossfader locks to slots but still morphs between).
-- returns true when pmorph moved this frame, so tick rebuilds the pattern.
function morph_snap()
  if pm_hold > 0 then pm_hold = pm_hold - 1 return end
  local t = math.floor(pmorph + 0.5)
  if t == pmorph then return end
  pmorph = math.abs(t - pmorph) < 0.01 and t or pmorph + (t - pmorph) * MORPH_SNAP
  dirty = true
end

-- gradient fill arc + bright cursor. base/top = hex brightness strings over a
-- np-LED track starting at L-index off; val 0..1 picks the cursor position.
function render_fill(ring, val, base, top, off, np)
  local vp = math.floor(val * np + 0.5)
  for p = 0, np do
    local z = tonumber((p <= vp and top or base):sub(p + 1, p + 1), 16)
    if z > 0 then L(ring, off + p, z) end
  end
  L(ring, off + vp, 15)
end

-- shared lower-piano view (editor ring 1, settings root/scale). pcl[pc] = lit.
-- (L is defined in rake.lua; resolved at call time, so load order is fine.)
function piano(r, pcl)
  for key = 0, 12 do
    local led, lit = KEYL:byte(key + 1), pcl[key % 12]
    if WHITEK:byte(key + 1) == 49 then
      local z = lit and 15 or 4
      L(r, led - 1, z) L(r, led - 2, z)
    else L(r, led - 1, lit and 9 or 1) end
  end
end

-- settings page 1 rings 1+2: root note and scale notes on the lower keyboard,
-- plus the binary scale-select groups on top of ring 2.
function root_scale_view()
  for pc = 0, 11 do PCLIT[pc] = false end
  PCLIT[root] = true
  piano(1, PCLIT)
  for pc = 0, 11 do PCLIT[pc] = false end
  local sc = SCALES[scale_i]
  for i = 1, #sc do PCLIT[(root + sc:byte(i)) % 12] = true end
  piano(2, PCLIT)
  rglyph(2, SCPAT, SC_LO:byte(scale_i), SC_HI:byte(scale_i), 50, 64)
  rglyph(2, SCPAT, SC_LO:byte(scale_i), SC_HI:byte(scale_i), 2, 16)
end
