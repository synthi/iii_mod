-- rake
-- physics chord strummer for arc (iii). see README.md

pset_init("rake")
fs_run_file("rake_data.lua") -- SCALES + LED tables (flash both files)
collectgarbage() -- free the data-file compile spike before allocating banks

-- ==== TUNABLES ====
FPS       = 60      -- frame/physics rate
GAIN      = 0.045   -- ring 1 delta -> omega (segments/frame)
OMEGA_MAX = 14      -- |omega| clamp; keep < 32 so crossed() sees < half rev/frame
FR_MIN    = 0.90    -- damping at FULL friction: heavy, short coast
FR_MAX    = 1.0     -- damping at ZERO friction: the pick never slows
EPS       = 0.01    -- |omega| below this snaps to 0
VEL_K     = 11      -- |omega| -> MIDI velocity scale
VEL_FLOOR = 22      -- velocity offset before clamp
VEL_MIN   = 20
VEL_MAX   = 127
GATE_MIN  = 0.06    -- shortest gate (s)
GATE_MAX  = 0.90    -- longest gate (s)
CLICK_WINDOW = 0.28 -- max gap for double click (s)
HOLD_TIME    = 0.45 -- press duration that becomes a hold (s)
HOLD_SECONDARY_LATCH = true -- false = momentary: secondary only while held
XFADE_TIME = 0.35   -- s: crossfade on stepped param changes
GMIN      = 0.1     -- notes below this crossfade gain don't strike
RES_STRUM = 2       -- ring 1 encoder resolution divisor on play pages
RES_MENU  = 8       -- encoder resolution divisor on menu-ish rings
ACC_TH    = 6       -- accumulated delta per detent step on stepped params
MORPH_SENS = 0.03   -- ring 2 delta -> progression position
MORPH_SNAP = 0.35   -- ring 2 morph detent: ease/frame onto the nearest slot
EXPR_SENS  = 0.02   -- ring 4 delta -> friction/gate 0..1
CH_HIT  = 0.5       -- chimes: playhead speed -> sway impulse on strike
CH_K    = 0.06      -- chimes: base sway spring rate (scales with pitch^2)
CH_CVM  = 0.4       -- chimes: sway velocity cap, fraction of gap/frame
CH_CW   = 0.4       -- chimes: contact width, fraction of resting gap
CH_REST = 0.75      -- chimes: collision/limit restitution
CH_VELK = 60        -- chimes: impact speed -> MIDI velocity
LFO_RMIN = 0.002    -- LFO phase incr/frame at rate 0 (~0.1 Hz)
LFO_RMAX = 0.15     -- LFO phase incr/frame at rate 1 (~9 Hz)
LFO_DMAX = 16       -- LFO swing amplitude (segments) at depth 1
LFO_SENS = 0.02     -- ring 3/4 delta -> LFO rate/depth 0..1
BPM_SENS = 0.4      -- settings ring 4 delta -> BPM
QAMT_SENS = 0.02    -- settings ring 3 delta -> quantize amount 0..1
Q_TIMEOUT = 2       -- s of MIDI-clock silence before reverting to internal
SR_PAD  = 0.25      -- strum-reset home gap past end notes: small so soft flicks fire note 1
MORPH_C = 36        -- slot-1 key (Ableton C1); white keys -> slots 1..8,
                    -- black keys -> transpose
MCH_MORPH = 1       -- morph/transpose notes
MCH_ROOT  = 2       -- root/octave notes

-- ==== state ====
MAIN, SETTINGS, SECONDARY = 1, 2, 3
STRUM, SEQ, LFO = 1, 2, 3
NMAIN = 3
mode = MAIN
main_page = STRUM
theta = 0
omega = 0
dirn = 1
fr = 0.985
gate = 0.25
midi_ch = 1
lfo_shape = 1
NSHAPE = 7
lfo_rate = 0.3
lfo_depth = 0
lfo_ph = 0
lfo_off = 0
phead = 0
engine = 1
NENG = 4
set_page = 1
NSETPG = 2

bpm = 120
qdiv = 0
NQDIV = 5
qamt = 1      -- quantize amount 0..1 (1 = full snap, the default)
q_frac = 0    -- fraction into the current grid cell (qamt window)
q_acc = 0
q_ext = false
q_pulse = 0
q_last = 0
q_clk = 0

-- 3 crossfade banks (BA/BB/BO): bank[field][k], 10 arrays of MAXB per bank
-- (per-field beats per-slot tables and one flat array on the RP2040 heap; the
-- fragmentation/shape story is in DESIGN 24/26).
-- fields: seg midi lit gain cx cv offmidi offch offtime qv. OT > 0 = ringing.
SG, MD, LT, GN, CX, CV, OM, OC, OT, QV = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
NF = 10
MAXB = 32 -- max notes/pattern
function newbank()
  local b = { n = 0 }
  for f = 1, NF do
    local a = {}
    for k = 1, MAXB do a[k] = 0 end
    b[f] = a
  end
  return b
end
BA, BB, BO = newbank(), newbank(), newbank()
BKS = { BA, BB, BO }
w_o = 0
rampin = 1
dirty = false
function bmul(i) return i == 3 and w_o or rampin end

-- ==== harmony (OMX-27 interval slots) ====
NSLOT = 8
VOICN = 8
slots = {}
do -- defaults: I vi7 IV V7 ii7 iii7 vi vii7 (all 8 enabled)
  local defs = { { 1, 3 }, { 6, 4 }, { 4, 3 }, { 5, 4 },
    { 2, 4 }, { 3, 4 }, { 6, 3 }, { 7, 4 } }
  for k = 1, NSLOT do
    local df = defs[k]
    slots[k] = { d = df[1], nn = df[2], voic = 1, rot = 0, sp = 3, oct = 0 }
  end
end
root = 0
scale_i = 1
oct = 4
xpose = 0
pmorph = 0
pm_hold = 0   -- morph detent countdown
fricv = 0.15
gatev = 0.35
style = 1
arange = 2
NSTYLE = 15
SEQMAX = MAXB
SEQIDX = {}
NA = {}
npath = 4

function sort_asc(t, n)
  for i = 2, n do
    local v = t[i]
    local j = i - 1
    while j > 0 and t[j] > v do t[j + 1] = t[j] j = j - 1 end
    t[j + 1] = v
  end
end

-- realize slot si -> out (OMX interval port); returns note count
function realize(si, out)
  local sl = slots[si]
  local n = sl.nn
  if n < 1 then return 0 end
  local sc = SCALES[scale_i]
  local ns = #sc
  local base = 12 * (oct + 1) + root + 12 * xpose
  local d0 = sl.d - 1
  local function dn(st, o)
    st = d0 + st
    return base + sc:byte(st % ns + 1) + 12 * (st // ns) + 12 * (o or 0)
  end
  for i = 1, n do out[i] = dn((i - 1) * 2) end
  local v = sl.voic
  if v == 2 then
    if n > 1 then out[2] = dn(4) end
    if n > 2 then out[3] = out[2] + 12 n = 3 end
  elseif v == 3 then if n > 1 then out[2] = dn(1) end
  elseif v == 4 then if n > 1 then out[2] = dn(3) end
  elseif v == 5 then
    if n > 1 then out[2] = dn(1) end
    if n > 2 then out[3] = dn(3) end
  elseif v == 6 then n = n + 1 out[n] = dn(5)
  elseif v == 7 then out[n + 1] = dn(5) out[n + 2] = dn(8) n = n + 2
  elseif v == 8 and n > 1 then
    out[2] = dn(4) n = 2
    if sl.nn > 2 then out[3] = dn(8) n = 3 end
    if sl.nn > 3 then out[4] = dn(9) out[5] = dn(6, 1) out[6] = dn(10, 1) n = 6 end
  end
  if sl.sp == 6 then
    for i = 1, n do out[i] = out[i] + (i % 2 == 1 and -12 or 12) end
  else
    local so = SPOFS:byte(sl.sp) - 2
    if so < 0 then for i = 1, n, 2 do out[i] = out[i] + 12 * so end
    elseif so > 0 then for i = 2, n, 2 do out[i] = out[i] + 12 * so end end
  end
  if sl.rot > 0 then
    for i = 1, sl.rot % n do out[i] = out[i] + 12 end
  end
  sort_asc(out, n)
  local sum = 0
  for i = 1, n do sum = sum + out[i] end
  local shift = round((base + 7 - sum / n) / 12) * 12 + 12 * sl.oct
  if shift ~= 0 then for i = 1, n do out[i] = out[i] + shift end end
  return n
end

EN = {} function build_path()
  local ne = 0
  for k = 1, NSLOT do
    if slots[k].nn > 0 then ne = ne + 1 EN[ne] = k end
  end
  return ne
end

function pathpos(si)   local ne = build_path()
  for i = 1, ne do if EN[i] == si then return i - 1 end end
end

function lay(k, n)
  local stepw = 64 / n
  return (32 - (n - 1) * stepw * 0.5 + (k - 1) * stepw) % 64
end

function segdist(a, b)
  local d = (a - b) % 64
  if d > 32 then d = 64 - d end
  return d
end

-- seq_pattern (arp style -> SEQIDX order) lives in rake_data.lua

function build_seq(si, bank, gain)
  local h = realize(si, NA)
  if h < 1 then bank.n = 0 return end
  local m
  if style == 14 then
    local total = h * arange
    if total > MAXB then total = MAXB end
    local hits = (total + h - 1) // h
    m = 0
    for o = 1, hits do
      local sg = lay(o, hits)
      for i = 1, h do
        if m < total then
          m = m + 1
          bank[SG][m], bank[MD][m], bank[GN][m] = sg, NA[i] + 12 * (o - 1), gain
        end
      end
    end
  else
    local p = seq_pattern(style, h)
    m = p * arange
    if m > SEQMAX then m = SEQMAX end
    for k = 1, m do
      bank[SG][k] = lay(k, m)
      bank[MD][k] = NA[SEQIDX[(k - 1) % p + 1]] + 12 * ((k - 1) // p)
      bank[GN][k] = gain
    end
  end
  bank.n = m
end

function merge_dups()
  for k2 = 1, BB.n do
    if BB[GN][k2] > 0 then
      for k1 = 1, BA.n do
        if BA[MD][k1] == BB[MD][k2] and segdist(BA[SG][k1], BB[SG][k2]) < 0.75 then
          BA[GN][k1] = clamp(BA[GN][k1] + BB[GN][k2], 0, 1) BB[GN][k2] = 0
          break
        end
      end
    end
  end
end

-- chord -> arp -> ring 1; pmorph crossfades between slots
function update_voices()
  local ne = build_path()
  npath = ne
  if ne == 0 then BA.n = 0 BB.n = 0 return end
  pmorph = pmorph % ne
  local pi = math.floor(pmorph)
  local frac = pmorph - pi
  build_seq(EN[pi + 1], BA, 1 - frac)
  if frac > 0 then build_seq(EN[(pi + 1) % ne + 1], BB, frac) else BB.n = 0 end
  merge_dups()
end

function grab_bank(bank, mul, m)
  for k = 1, bank.n do
    local g = bank[GN][k] * mul
    if g > 0.08 and m < MAXB then
      m = m + 1
      BO[SG][m], BO[MD][m], BO[GN][m], BO[LT][m] =
        bank[SG][k], bank[MD][k], g, bank[LT][k]
    end
  end
  return m
end

function xfade_begin()
  BO.n = grab_bank(BB, rampin, grab_bank(BA, rampin, 0))
  w_o = 1
end

-- swept-arc crossing: seg on the pick's arc this frame
function crossed(last, trav, seg)
  if trav > 0 then
    local rel = (seg - last) % 64
    return rel > 0 and rel <= trav
  elseif trav < 0 then
    local rel = (last - seg) % 64
    return rel > 0 and rel <= -trav
  end
  return false
end

function fire(b, k, vel, now)
  if b[MD][k] > 127 then return end
  if b[OT][k] > 0 then midi_note_off(b[OM][k], 0, b[OC][k]) end
  midi_note_on(b[MD][k], vel, midi_ch)
  b[OM][k], b[OC][k], b[OT][k] = b[MD][k], midi_ch, now + gate
  b[LT][k] = 15
end

function gfire(b, k, vel, g, now) -- fire scaled by crossfade gain
  local vv = clamp(math.floor(vel * g + 0.5), 8, VEL_MAX)
  -- qamt = snap window: notes in the last qamt of the cell defer to grid, rest free
  if qdiv > 0 and q_frac >= 1 - qamt then
    if vv > b[QV][k] then b[QV][k] = vv end
  else fire(b, k, vv, now) end
end

-- fire note-ons queued since the last boundary (one per voice)
function q_flush(now)
  for i = 1, 3 do
    local bk = BKS[i]
    local qv, md = bk[QV], bk[MD]
    for k = 1, MAXB do
      if qv[k] > 0 then
        if md[k] > 0 then fire(bk, k, qv[k], now) end
        qv[k] = 0
      end
    end
  end
end

function strike_bank(bank, mul, last, trav, now, vel)
  local gn, sg = bank[GN], bank[SG]
  for k = 1, bank.n do
    local g = gn[k] * mul
    if g > GMIN and crossed(last, trav, sg[k]) then gfire(bank, k, vel, g, now) end
  end
end

function offs_bank(bank, now) -- all slots: shrunk banks still owe offs
  local ot, lt = bank[OT], bank[LT]
  for k = 1, MAXB do
    local e = ot[k]
    if e > 0 and now >= e then
      midi_note_off(bank[OM][k], 0, bank[OC][k]) ot[k] = 0
    end
    if lt[k] > 0 then lt[k] = lt[k] - 1 end
  end
end

function offs_all(now) for i = 1, 3 do offs_bank(BKS[i], now) end end

function notes_frame(last, trav, now)
  local vel = clamp(VEL_FLOOR + math.floor(math.abs(trav) * VEL_K), VEL_MIN, VEL_MAX)
  if trav ~= 0 then
    for i = 1, 3 do strike_bank(BKS[i], bmul(i), last, trav, now, vel) end
  end
  offs_all(now)
end

-- strum-reset (engine 2): travel walled to the pattern span
function strum_bounds()
  if BA.n < 1 then return 0, 64 end
  local lo, hi = 64, 0
  local sg = BA[SG]
  for k = 1, BA.n do
    local s = sg[k]
    if s < lo then lo = s end
    if s > hi then hi = s end
  end
  return lo - SR_PAD, hi + SR_PAD
end

function physics_strum()
  local trav = omega
  if engine == 2 then -- strum reset: momentum + friction like strum, but walled to the
    local lo, hi = strum_bounds() -- pattern span -- stops dead at either end (no wrap),
    local nt = theta + omega      -- friction still decays so a soft flick/heavy drag
    if nt >= hi then nt = hi omega = 0         -- plays only the first few notes
    elseif nt <= lo then nt = lo omega = 0 end
    trav = nt - theta
    theta = nt
    omega = omega * fr
    if math.abs(omega) < EPS then omega = 0 end
    return trav
  end
  theta = (theta + trav) % 64
  omega = omega * fr
  if math.abs(omega) < EPS then omega = 0 end
  return trav
end

-- LFO wave 0..1 -> [-1,1]; 5,6 = saw+/saw- twins (chord-saw)
function lfo_wave(sh, ph)
  if sh == 1 then return math.sin(ph * 6.2832)
  elseif sh == 2 then return ph < 0.5 and ph * 4 - 1 or 3 - ph * 4
  elseif sh == 3 or sh == 5 then return ph * 2 - 1
  elseif sh == 4 or sh == 6 then return 1 - ph * 2
  else return ph < 0.5 and 1 or -1 end
end

-- advance LFO; return swept arc; phead = render pos
function playhead()
  local base = physics_strum()
  local off = 0
  if lfo_depth > 0 then
    local p0 = lfo_ph
    lfo_ph = (lfo_ph + LFO_RMIN + lfo_rate * (LFO_RMAX - LFO_RMIN)) % 1
    off = lfo_depth * LFO_DMAX * lfo_wave(lfo_shape, lfo_ph)
    -- teleport the offset (no stab) on a plain-saw reset OR a shape switch
    if lfo_tp or (lfo_ph < p0 and (lfo_shape == 3 or lfo_shape == 4)) then lfo_off = off end
    lfo_tp = false
  end
  local last = (theta - base + lfo_off) % 64
  local trav = base + (off - lfo_off)
  lfo_off = off
  phead = (theta + off) % 64
  return last, trav
end

-- chimes/wind: damped pendulums the pick strikes; neighbors collide+fire; fr=damp
function chime_bank(bank, now, vmul, last, trav, vel)
  local n = bank.n
  if n < 1 then return end
  local gap = 64 / n
  local cw = gap * CH_CW
  local cvmax = gap * CH_CVM
  local cxa, cva = bank[CX], bank[CV]
  for k = 1, n do
    local r = bank[MD][k] * 0.0167
    local cv = clamp((cva[k] - CH_K * r * r * cxa[k]) * fr, -cvmax, cvmax)
    local nx = cxa[k] + cv
    if nx > gap then nx = gap cv = -cv * CH_REST
    elseif nx < -gap then nx = -gap cv = -cv * CH_REST end
    cxa[k] = nx
    if trav ~= 0 and crossed(last, trav, bank[SG][k] + nx) then
      if engine == 3 then -- chimes fire on strike; wind (4) only sways
        local g = bank[GN][k] * vmul
        if g > GMIN then gfire(bank, k, vel, g, now) end
      end
      cv = clamp(cv + trav * CH_HIT, -cvmax, cvmax)
    end
    cva[k] = cv
  end
  if n < 2 then return end
  for a = 1, n do
    local b = a % n + 1
    if gap + cxa[b] - cxa[a] < cw and cva[a] > cva[b] then
      local vel = clamp(VEL_FLOOR + math.floor((cva[a] - cva[b]) * CH_VELK),
        VEL_MIN, VEL_MAX)
      local ga, gb = bank[GN][a] * vmul, bank[GN][b] * vmul
      if ga > GMIN then gfire(bank, a, vel, ga, now) end
      if gb > GMIN then gfire(bank, b, vel, gb, now) end
      local mid = (cva[a] + cva[b]) * 0.5
      local av, bv = cva[a], cva[b]
      cva[a] = mid + (bv - mid) * CH_REST cva[b] = mid + (av - mid) * CH_REST
      local push = (cw - (gap + cxa[b] - cxa[a])) * 0.5
      cxa[a] = cxa[a] - push cxa[b] = cxa[b] + push
    end
  end
end

function chimes_reset()
  for i = 1, 3 do
    local b = BKS[i]
    for k = 1, MAXB do b[CX][k] = 0 b[CV][k] = 0 end
  end
end

acc = { 0, 0, 0, 0 }

function accstep(n, d)
  if d * acc[n] < 0 then acc[n] = 0 end
  acc[n] = acc[n] + d
  if acc[n] >= ACC_TH then acc[n] = 0 return 1 end
  if acc[n] <= -ACC_TH then acc[n] = 0 return -1 end
  return 0
end

function stepped(n, d, cur, lo, hi)
  local s = accstep(n, d)
  if s == 0 then return cur end
  local nu = clamp(cur + s, lo, hi)
  if nu ~= cur then xfade_begin() dirty = true end
  return nu
end

function set_fric(x) -- fricv IS friction: 0 = infinite spin, 1 = heavy drag
  fricv = clamp(x, 0, 1)
  fr = linlin(fricv, 0, 1, FR_MAX, FR_MIN)
end

function set_gate(x)
  gatev = clamp(x, 0, 1)
  gate = linlin(gatev, 0, 1, GATE_MIN, GATE_MAX)
end

function spin(d) -- ring 1 = playhead momentum
  if engine == 2 then -- strum reset: a flick from rest OR any reverse-direction flick
    -- restarts from the correct wall (CW=low, CCW=high), not braking
    if d ~= 0 and (omega == 0 or (d > 0) ~= (omega > 0)) then
      local lo, hi = strum_bounds()
      theta = d > 0 and lo or hi
      omega = 0
    end
    omega = clamp(omega + d * GAIN, -OMEGA_MAX, OMEGA_MAX)
    if omega > EPS then dirn = 1 elseif omega < -EPS then dirn = -1 end
    return
  end
  omega = clamp(omega + d * GAIN, -OMEGA_MAX, OMEGA_MAX)
  if omega > EPS then dirn = 1 elseif omega < -EPS then dirn = -1 end
end

function delta_strum(n, d)
  if n == 1 then spin(d)
  elseif n == 2 then pmorph = pmorph + d * MORPH_SENS pm_hold = 8 dirty = true
  elseif n == 3 then xpose = stepped(3, -d, xpose, -2, 2) -- -d inverts per LED design
  else set_fric(fricv + d * EXPR_SENS) end
end

function delta_seq(n, d)
  if n == 1 then spin(d)
  elseif n == 2 then local s = accstep(2, d) -- arp pattern wraps
    if s ~= 0 then style = wrap(style + s, 1, NSTYLE) xfade_begin() dirty = true end
  elseif n == 3 then arange = stepped(3, -d, arange, 1, 4)
  else set_gate(gatev + d * EXPR_SENS) end
end

function delta_lfo(n, d) -- ring 1 spin; shape (CCW+wrap), rate, depth (CW+)
  if n == 1 then spin(d)
  elseif n == 2 then
    local s = accstep(2, -d)
    if s ~= 0 then lfo_shape = wrap(lfo_shape + s, 1, NSHAPE) lfo_tp = true end
  elseif n == 3 then lfo_rate = clamp(lfo_rate + d * LFO_SENS, 0, 1)
  else lfo_depth = clamp(lfo_depth + d * LFO_SENS, 0, 1) end
end

edit_slot = 1
edit_page = 1
KBPC = {}     -- keyboard cache: lit pitch classes of the edited slot
PCLIT = {}    -- scratch pitch-class set for the settings root/scale pianos

function upd_kb()
  for pc = 0, 11 do KBPC[pc] = false end
  local n = realize(edit_slot, NA)
  for i = 1, n do KBPC[NA[i] % 12] = true end
end

function sel_slot(s)
  edit_slot = s
  local pp = pathpos(s)
  if pp then
    xfade_begin()
    pmorph = pp
    dirty = true
  end
  upd_kb()
end

-- s>0=CW. per-param directions follow the editor LED designs
function delta_secondary(n, d)
  local s = accstep(n, d)
  if s == 0 then return end
  if n == 1 then
    local t = clamp(edit_slot - s, 1, NSLOT)
    if t ~= edit_slot then sel_slot(t) end
    return
  end
  local sl = slots[edit_slot]
  local v
  if edit_page == 1 then
    if n == 2 then v = clamp(sl.d - s, 1, 7)
      if v ~= sl.d then sl.d = v else return end
    elseif n == 3 then v = clamp(sl.nn - s, 0, 4)
      if v ~= sl.nn then sl.nn = v else return end
    elseif n == 4 then sl.voic = wrap(sl.voic - s, 1, VOICN) end
  else
    if n == 2 then sl.rot = wrap(sl.rot + s, 0, 4)
    elseif n == 3 then sl.sp = wrap(sl.sp + s, 1, 6)
    elseif n == 4 then v = clamp(sl.oct - s, -2, 2)
      if v ~= sl.oct then sl.oct = v else return end
    end
  end
  xfade_begin()
  if n == 3 and edit_page == 1 then
    local pp = pathpos(edit_slot)
    if pp then pmorph = pp end
  end
  dirty = true
  upd_kb()
end

function delta_settings(n, d)
  if set_page == 2 then
    if n == 4 then bpm = clamp(bpm + d * BPM_SENS, 40, 240) return end
    if n == 3 then qamt = clamp(qamt + d * QAMT_SENS, 0, 1) return end -- CW: more
    local s = accstep(n, d)
    if s == 0 then return end
    if n == 1 then engine = wrap(engine - s, 1, NENG) chimes_reset()
    elseif n == 2 then
      local nq = clamp(qdiv + s, 0, NQDIV)
      if nq ~= qdiv then q_flush(get_time()) qdiv = nq q_acc = 0 end
    end
    return
  end
  local s = accstep(n, d)
  if s == 0 then return end
  if n == 4 then midi_ch = clamp(midi_ch - s, 1, 16) return end -- -s: CCW = ch up
  xfade_begin()
  if n == 1 then root = (root - s) % 12 -- -s: CCW selects the next semitone up
  elseif n == 2 then scale_i = clamp(scale_i + s, 1, #SCALES)
  else oct = clamp(oct + s, 1, 7) end -- n==3 base octave: CW = octave up
  dirty = true
end

function event_arc(n, d)
  if mode == MAIN then
    if main_page == STRUM then delta_strum(n, d)
    elseif main_page == SEQ then delta_seq(n, d)
    else delta_lfo(n, d) end
  elseif mode == SETTINGS then delta_settings(n, d)
  else delta_secondary(n, d) end
end

-- hold arms; 2nd press in CLICK_WINDOW = double; short release = single
k_down = false
k_time = 0
wait_click = false
swallow = false
hold_fired = false

function on_single()
  if mode == SECONDARY then edit_page = 3 - edit_page
  elseif mode == SETTINGS then set_page = set_page % NSETPG + 1
  elseif mode == MAIN then
    main_page = main_page % NMAIN + 1
    enter_page()
  end
end

function on_double()
  if mode == MAIN then
    mode = SETTINGS -- keep whatever settings page we were last on
    enter_page()
  else exit_menu(MAIN) end
end

function on_hold()
  if mode == SECONDARY then exit_menu(MAIN) return end
  mode = SECONDARY
  save_state()
  local ne = build_path()
  if ne > 0 then
    edit_slot = EN[(math.floor(pmorph + 0.5) % ne) + 1]
  end
  upd_kb()
  enter_page()
end

function exit_menu(to)
  mode = to
  save_state()
  enter_page()
end

function event_arc_key(a, b)
  local z = b or a
  local now = get_time()
  if z and z > 0 then
    k_down = true
    if wait_click and (now - k_time) < CLICK_WINDOW then
      wait_click = false
      swallow = true
      m_click:stop()
      on_double()
    else
      swallow = false
      m_hold:start(HOLD_TIME, 1)
    end
    k_time = now
  else
    k_down = false
    m_hold:stop()
    if hold_fired then
      hold_fired = false
      -- momentary: exit secondary on hold release
      if not HOLD_SECONDARY_LATCH and mode == SECONDARY then exit_menu(MAIN) end
    elseif not swallow and (now - k_time) < HOLD_TIME then
      wait_click = true
      m_click:start(CLICK_WINDOW, 1)
    end
    swallow = false
  end
end

function click_fire()
  m_click:stop()
  if wait_click then
    wait_click = false
    on_single()
  end
end

function hold_fire()
  m_hold:stop()
  if k_down and not swallow then
    hold_fired = true
    on_hold()
  end
end

-- fixed _quote (stock iii gsub corrupts ints 0->"", 10->1)
function _quote(val, ...)
  if ... ~= nil then
    local t = { _quote(val) }
    for _, v in ipairs({ ... }) do t[#t + 1] = _quote(v) end
    return table.concat(t, ',')
  elseif type(val) == 'string' then return string.format('%q', val)
  elseif type(val) == 'number' then return string.format('%.6g', val)
  elseif type(val) ~= 'table' then return tostring(val)
  else
    local t = {}
    for k, v in pairs(val) do
      local f = string.format((type(k) == 'number') and '[%d]' or '[%q]', k)
      t[#t + 1] = f .. '=' .. _quote(v)
    end
    return string.format('{%s}', table.concat(t, ','))
  end
end

-- pset snapshot v7; transient table, garbage after pset_write
function snapshot()
  local t = { script = "rake", v = 7 }
  t.root, t.scale_i, t.midi_ch, t.oct = root, scale_i, midi_ch, oct
  t.fricv, t.gatev, t.pmorph, t.xpose = fricv, gatev, pmorph, xpose
  t.style, t.arange, t.main_page, t.engine = style, arange, main_page, engine
  t.lsh, t.lr, t.ld = lfo_shape, lfo_rate, lfo_depth
  t.qdiv, t.bpm, t.qamt, t.set_page = qdiv, bpm, qamt, set_page
  for k = 1, NSLOT do
    local sl = slots[k]
    local p = "s" .. k
    t[p .. "d"], t[p .. "n"], t[p .. "v"] = sl.d, sl.nn, sl.voic
    t[p .. "r"], t[p .. "s"], t[p .. "o"] = sl.rot, sl.sp, sl.oct
  end
  return t
end

function apply_state(r)
  root = r.root or 0
  scale_i = clamp(r.scale_i or 1, 1, #SCALES)
  midi_ch = clamp(r.midi_ch or 1, 1, 16)
  oct = clamp(r.oct or 4, 1, 7)
  xpose = clamp(r.xpose or 0, -2, 2)
  pmorph = r.pmorph or 0
  style = clamp(r.style or 1, 1, NSTYLE)
  arange = clamp(r.arange or 2, 1, 4)
  main_page = clamp(r.main_page or STRUM, 1, NMAIN)
  engine = clamp(r.engine or 1, 1, NENG)
  qdiv = clamp(r.qdiv or 0, 0, NQDIV)
  bpm = clamp(r.bpm or 120, 40, 240)
  qamt = clamp(r.qamt or 1, 0, 1)
  set_page = clamp(r.set_page or 1, 1, NSETPG)
  lfo_shape = clamp(r.lsh or 1, 1, NSHAPE)
  lfo_rate = clamp(r.lr or 0.3, 0, 1)
  lfo_depth = clamp(r.ld or 0, 0, 1)
  local pv = r.v or 0
  for k = 1, NSLOT do
    local sl = slots[k]
    local p = "s" .. k
    if r[p .. "d"] then
      sl.d = clamp(r[p .. "d"], 1, 7)
      sl.nn = clamp(r[p .. "n"] or 3, 0, 4)
      sl.voic = clamp(r[p .. "v"] or 1, 1, VOICN)
      sl.rot = clamp(r[p .. "r"] or 0, 0, 4)
      -- spread migrates to the 1..6 index
      local sp = r[p .. "s"]
      if sp == nil then sp = 3
      elseif pv < 6 then sp = (sp == 6) and 6 or (6 - sp)
      elseif pv < 7 then sp = 3 - sp end
      sl.sp = clamp(sp, 1, 6)
      sl.oct = clamp(r[p .. "o"] or 0, -2, 2)
    end
  end
  local fv = r.fricv
  if fv == nil then fv = r.expr end
  if fv == nil then fv = 0.15
  elseif (r.v or 0) < 5 then fv = 1 - fv end
  set_fric(fv)
  set_gate(r.gatev or 0.35)
  dirty = true
end

function save_state()
  collectgarbage()
  pset_write(1, snapshot())
end

function enter_page()
  acc[1], acc[2], acc[3], acc[4] = 0, 0, 0, 0
  arc_res(1, mode == MAIN and RES_STRUM or RES_MENU)
  for n = 2, 4 do arc_res(n, RES_MENU) end
  dirty = true
end

function L(n, s, z, rel)
  arc_led(n, math.floor(s) % 64 + 1, z, rel)
end

function pointf(n, s, z) -- anti-aliased point across two segments
  local f = s - math.floor(s)
  L(n, s, math.ceil(z * (1 - f)), true)
  if f > 0 then L(n, s + 1, math.floor(z * f), true) end
end

function markers_bank(bank, mul, floorz)
  local gn, lta, sg = bank[GN], bank[LT], bank[SG]
  for k = 1, bank.n do
    local g = gn[k] * mul
    if g > 0.05 then
      local lt = lta[k]
      local z = math.floor((lt > floorz and lt or floorz) * g + 0.5)
      if z > 0 then
        if engine >= 3 then pointf(1, sg[k] + bank[CX][k], z)
        else L(1, sg[k], z, true) end
      end
    end
  end
end

function markers_all(fz) for i = 1, 3 do markers_bank(BKS[i], bmul(i), fz) end end

function render_ruler(ring, val) -- friction-style ruler fill (LED_Design/Friction)
  local vp = math.floor(val * 52 + 0.5)
  for p = 0, 52 do
    local t = FTICK:byte(p + 1) == 49
    local z = p <= vp and (t and 10 or 3) or (t and 2 or 0)
    if z > 0 then L(ring, 38 + p, z) end
  end
  L(ring, 38 + vp, 15)
end

-- render_fill (gradient fill arc + cursor) lives in rake_data.lua

function render_morph_ring()
  local ne = npath > 0 and npath or 1
  local pm = pmorph % ne
  local cur = math.floor(pm) + 1
  for s = 1, ne do L(2, (s - 1) * (64 / ne), s == cur and 6 or 2) end
  pointf(2, pm * (64 / ne), 14)
end

function render_comet() -- head + decaying tail at the effective playhead
  pointf(1, phead, 15)
  local tl = clamp(math.floor(math.abs(omega) * 5) + 2, 2, 14)
  for t = 1, tl do
    local z = math.floor(11 * (1 - t / tl))
    if z > 0 then L(1, phead - dirn * t, z, true) end
  end
end

function render_strum()
  markers_all(4)
  render_comet()
  render_morph_ring()
  rlist(3, TRANSP, xpose + 3)
  render_ruler(4, fricv)
end

-- LFO page: comet + swing markers; shape/rate/depth on rings 2/3/4
function render_lfo()
  markers_all(4)
  if lfo_depth > 0 then
    local amp = lfo_depth * LFO_DMAX
    L(1, theta - amp, 4) L(1, theta + amp, 4)
  end
  render_comet()
  rglyph(2, SHPAT, SHP_LO:byte(lfo_shape), SHP_HI:byte(lfo_shape), 20, 46)
  render_ruler(3, lfo_rate)
  render_fill(4, lfo_depth, GATEB, GATEF, 38, 52)
end

function render_seq() -- dense pattern dots + bare head: stepped idiom
  markers_all(3)
  pointf(1, phead, 15)
  rglyph(2, STYPAT, STY_LO:byte(style), STY_HI:byte(style), 1, 64)
  rlist(3, OCTR, arange)
  render_fill(4, gatev, GATEB, GATEF, 38, 52)
end


function rgroup(ring, s, sel) -- startLED,count byte pairs; sel-th run bright
  for i = 1, #s // 2 do
    local z = (i == sel) and 15 or 1
    local st, c = s:byte(i + i - 1), s:byte(i + i)
    for j = 0, c - 1 do L(ring, st + j - 1, z) end
  end
end

function rlist(ring, s, sel) -- \0-separated LED byte lists; sel-th group bright
  local i = 1
  for p = 1, #s do
    local b = s:byte(p)
    if b == 0 then i = i + 1
    else L(ring, b - 1, (i == sel) and 15 or 1) end
  end
end

function rglyph(ring, pat, lo, hi, a, b) -- glyph strip: LEDs a..b from hex pat,
  for led = a, b do                      -- selected span [lo,hi] bright, rest dim
    local bv = tonumber(pat:sub(led, led), 16)
    if bv > 0 then L(ring, led - 1, (led >= lo and led <= hi) and bv or bv // 3) end
  end
end


function render_secondary()
  piano(1, KBPC) -- lower-octave keyboard: chord notes lit
  for s = 1, NSLOT do
    local z = s == edit_slot and 15 or (slots[s].nn > 0 and 1 or 0)
    if z > 0 then L(1, 54 - s, z) end
  end
  local sl = slots[edit_slot]
  if edit_page == 1 then
    rgroup(2, DEG, sl.d)
    rgroup(3, NN, sl.nn)
    rglyph(4, VOICEPAT, VOIC_LO:byte(sl.voic), VOIC_HI:byte(sl.voic), 5, 62)
  else
    rgroup(2, ROT, sl.rot + 1)
    rlist(3, SPREAD, sl.sp)
    rlist(4, OCTL, sl.oct + 3)
  end
end

function render_settings()
  if set_page == 2 then
    for e = 1, NENG do -- ring 1: mode glyphs (LED_Design/Mode-Select.json)
      local g = MGLYPH[e]
      for j = 1, #g, 2 do
        local bv = g:byte(j + 1)
        L(1, g:byte(j) - 1, e == engine and bv or (bv == 15 and 4 or 1))
      end
    end
    rglyph(2, QPAT, QZ_LO:byte(qdiv + 1), QZ_HI:byte(qdiv + 1), 17, 49) -- r2 quantize
    render_fill(3, qamt, QAB, QAF, 39, 50)                 -- r3 quantize amount
    render_fill(4, (bpm - 40) / 200, BPMB, BPMF, 39, 50)   -- r4 BPM
    if q_ext then -- external-sync indicator across the bottom of ring 4
      for j = 1, #EXTSYNC, 2 do L(4, EXTSYNC:byte(j) - 1, EXTSYNC:byte(j + 1)) end
    end
    return
  end
  root_scale_view() -- rings 1 (root) + 2 (scale) keyboards (in rake_data.lua)
  for o = 1, 7 do L(3, 37 + o, o == oct and 15 or 1) end       -- ring 3: base octave
  for c = 1, 16 do L(4, 26 - c, c == midi_ch and 15 or 1) end  -- ring 4: MIDI channel
end

function tick()
  local now = get_time()
  if w_o > 0 then
    w_o = w_o - 1 / (XFADE_TIME * FPS)
    if w_o < 0 then w_o = 0 end
  end
  rampin = 1 - w_o
  morph_snap() -- ring 2 morph detent -> nearest slot
  if dirty then
    dirty = false
    update_voices()
  end
  -- notes come only from the pick striking markers/chimes
  local last, trav = playhead()
  if engine >= 3 then
    local vel = clamp(VEL_FLOOR + math.floor(math.abs(trav) * VEL_K), VEL_MIN, VEL_MAX)
    for i = 1, 3 do chime_bank(BKS[i], now, bmul(i), last, trav, vel) end
    offs_all(now)
  else
    notes_frame(last, trav, now)
    if engine == 2 and omega == 0 then -- strum reset: home the pick on stop
      local lo, hi = strum_bounds()
      theta = dirn >= 0 and lo or hi
      phead = (theta + lfo_off) % 64
    end
  end
  -- internal BPM grid flush (external clock flushes in event_midi)
  local dt = now - q_last
  q_last = now
  if qdiv > 0 then
    if q_ext and now - q_clk > Q_TIMEOUT then q_ext = false q_acc = 0 end
    if q_ext then
      local pp = QPULSE:byte(qdiv)
      q_frac = (q_pulse % pp) / pp
    else
      if dt < 0 or dt > 0.1 then dt = 1 / FPS end
      q_acc = q_acc + dt
      local spg = QPULSE:byte(qdiv) * 2.5 / bpm -- pulses/24 * 60s
      if q_acc >= spg then q_acc = q_acc - spg q_flush(now) end
      q_frac = q_acc / spg
    end
  end
  arc_led_all(0)
  if mode == SETTINGS then
    render_settings()
    pointf(1, phead, 5)
  elseif mode == SECONDARY then
    render_secondary()
    pointf(1, phead, 5)
  elseif main_page == SEQ then render_seq()
  elseif main_page == LFO then render_lfo()
  else render_strum() end
  arc_refresh()
end

function morph_note(note)
  local d = note - MORPH_C
  if d < 0 or d > 12 then return end -- guard: :byte(-1) would wrap to the end
  local s = WSLOT:byte(d + 1)
  if s > 0 then
    local pp = pathpos(s)
    if pp then xfade_begin() pmorph = pp dirty = true end
  else
    local x = BXPOSE:byte(d + 1)
    if x > 0 and x - 3 ~= xpose then xfade_begin() xpose = x - 3 dirty = true end
  end
end

function root_note(note)
  xfade_begin()
  root = note % 12
  oct = clamp(note // 12 - 1, 1, 7)
  dirty = true
end

-- MIDI in: note by channel; clock = grid/transport
function event_midi(a, b, c)
  if (a & 0xf0) == 0x90 then
    if c and c > 0 then
      local ch = (a & 0x0f) + 1
      if ch == MCH_MORPH then morph_note(b)
      elseif ch == MCH_ROOT then root_note(b) end
    end
  elseif a == 0xF8 then
    q_clk = get_time()
    if not q_ext then q_ext = true q_pulse = 0 end
    q_pulse = q_pulse + 1
    if qdiv > 0 and q_pulse % QPULSE:byte(qdiv) == 0 then q_flush(q_clk) end
  elseif a == 0xFA then q_pulse = 0
  elseif a == 0xFC then q_flush(get_time()) end
end

-- guard(): print callback errors (else silent death)
err_cnt = 0
function guard(f, name)
  return function(a, b, c)
    local okk, e = pcall(f, a, b, c)
    if not okk then
      err_cnt = err_cnt + 1
      print(name .. " error: " .. tostring(e))
    end
  end
end

event_arc = guard(event_arc, "arc")
event_arc_key = guard(event_arc_key, "key")
event_midi = guard(event_midi, "midi")
click_fire = guard(click_fire, "click")
hold_fire = guard(hold_fire, "hold")
tick = guard(tick, "tick")

function init()
  print("\n~~~ rake ~~~\n")
  for ch = 1, 16 do midi_cc(123, 0, ch) end
  collectgarbage() -- pset parse is the boot's memory peak; enter it clean
  local r = pset_read(1)
  if r and r.script == "rake" then apply_state(r)
  else
    print("fresh pset")
    set_fric(fricv)
    set_gate(gatev)
    save_state()
  end
  upd_kb()
  enter_page()
  collectgarbage() -- reclaim all load-time garbage before the frame loop
  m_frame = metro.init(tick, 1 / FPS)
  m_frame:start()
  m_click = metro.init(click_fire)
  m_hold = metro.init(hold_fire)
end

init()
