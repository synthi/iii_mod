-- griii
-- topographic drum sequencer for monome arc iii
-- pattern data from Mutable Instruments Grids (GPLv3)
-- original design by Émilie Gillet
pset_init('griii')
PAT =
"\255\0\0\0\0\0\145\0\0\0\0\0\218\0\0\0\72\0\36\0\182\0\0\0\109\0\0\0\72\0\0\0\36\0\109\0\0\0\8\0\255\0\0\0\0\0\72\0\0\0\182\0\0\0\36\0\218\0\0\0\145\0\0\0\170\0\113\0\255\0\56\0\170\0\141\0\198\0\56\0" ..
"\170\0\113\0\226\0\28\0\170\0\113\0\198\0\85\0\229\0\25\0\102\0\25\0\204\0\25\0\76\0\8\0\255\0\8\0\51\0\25\0\178\0\25\0\153\0\127\0\28\0\198\0\56\0\56\0\226\0\28\0\141\0\28\0\28\0\170\0\28\0\28\0\255\0\113\0\85\0\85\0" ..
"\159\0\159\0\255\0\63\0\159\0\159\0\191\0\31\0\159\0\127\0\255\0\31\0\159\0\127\0\223\0\95\0\255\0\0\0\127\0\0\0\0\0\102\0\0\0\229\0\0\0\178\0\204\0\0\0\76\0\51\0\153\0\25\0\0\0\127\0\0\0\0\0\255\0\191\0\31\0\63\0" ..
"\0\0\95\0\0\0\0\0\223\0\0\0\31\0\159\0\255\0\85\0\148\0\85\0\127\0\85\0\106\0\63\0\212\0\170\0\191\0\170\0\85\0\42\0\233\0\21\0\255\0\212\0\63\0\0\0\106\0\148\0\85\0\127\0\191\0\21\0\233\0\0\0\21\0\170\0\0\0\42\0" ..
"\0\0\0\0\141\0\113\0\255\0\198\0\0\0\56\0\0\0\85\0\56\0\28\0\226\0\28\0\170\0\56\0\255\0\231\0\255\0\208\0\139\0\92\0\115\0\92\0\185\0\69\0\46\0\46\0\162\0\23\0\208\0\46\0\255\0\31\0\63\0\63\0\127\0\95\0\191\0\63\0" ..
"\223\0\31\0\159\0\63\0\31\0\63\0\95\0\31\0\8\0\0\0\95\0\63\0\255\0\0\0\127\0\0\0\8\0\0\0\159\0\63\0\255\0\223\0\191\0\31\0\76\0\25\0\255\0\127\0\153\0\51\0\204\0\102\0\76\0\51\0\229\0\127\0\153\0\51\0\178\0\102\0" ..
"\255\0\51\0\25\0\76\0\0\0\0\0\102\0\0\0\204\0\229\0\0\0\178\0\0\0\153\0\127\0\8\0\178\0\127\0\153\0\204\0\255\0\0\0\25\0\76\0\102\0\51\0\0\0\0\0\229\0\25\0\25\0\204\0\178\0\102\0\255\0\76\0\127\0\76\0\229\0\76\0" ..
"\153\0\102\0\255\0\25\0\127\0\51\0\204\0\51\0\255\0\0\0\223\0\0\0\31\0\8\0\127\0\0\0\95\0\0\0\159\0\0\0\95\0\63\0\191\0\0\0\51\0\204\0\0\0\102\0\255\0\127\0\8\0\178\0\25\0\229\0\0\0\76\0\204\0\153\0\51\0\25\0" ..
"\255\0\226\0\255\0\255\0\198\0\28\0\141\0\56\0\170\0\56\0\85\0\28\0\170\0\28\0\113\0\56\0\223\0\0\0\63\0\0\0\95\0\0\0\223\0\31\0\255\0\0\0\159\0\0\0\127\0\31\0\191\0\31\0\0\0\0\0\109\0\0\0\218\0\0\0\182\0\72\0" ..
"\8\0\36\0\145\0\36\0\255\0\8\0\182\0\72\0\255\0\72\0\218\0\36\0\218\0\0\0\145\0\0\0\255\0\36\0\182\0\36\0\182\0\0\0\109\0\0\0\255\0\0\0\218\0\0\0\36\0\0\0\218\0\0\0\182\0\109\0\255\0\0\0\0\0\0\0\145\0\72\0" ..
"\159\0\0\0\31\0\127\0\255\0\31\0\0\0\95\0\8\0\0\0\191\0\31\0\255\0\31\0\223\0\63\0\255\0\31\0\63\0\31\0\95\0\31\0\63\0\127\0\159\0\31\0\63\0\31\0\223\0\223\0\191\0\191\0\226\0\28\0\28\0\141\0\8\0\8\0\255\0\8\0" ..
"\113\0\28\0\198\0\85\0\56\0\198\0\170\0\28\0\8\0\95\0\8\0\8\0\255\0\63\0\31\0\223\0\8\0\31\0\191\0\8\0\255\0\127\0\127\0\159\0\115\0\46\0\255\0\185\0\139\0\23\0\208\0\115\0\231\0\69\0\255\0\162\0\139\0\115\0\231\0\92\0" ..
"\145\0\0\0\0\0\109\0\0\0\0\0\255\0\109\0\72\0\218\0\0\0\0\0\36\0\0\0\182\0\0\0\0\0\127\0\159\0\127\0\159\0\191\0\223\0\63\0\255\0\95\0\31\0\95\0\31\0\8\0\63\0\8\0\255\0\0\0\145\0\0\0\182\0\109\0\109\0\109\0" ..
"\218\0\0\0\72\0\0\0\182\0\72\0\182\0\36\0\255\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\255\0\0\0\218\0\72\36\0\0\182\0\0\0\145\109\0\0\127\0\0\0\42\0\212\0\0\212\0\0\212\0\0\0\0\0\42\0\0\0\255\0\0\0\170\170\127\85" ..
"\145\0\109\109\218\109\72\0\145\0\72\0\218\0\109\0\182\0\109\0\255\0\72\0\182\109\36\109\255\109\109\0\255\0\0\0\255\0\191\0\0\0\0\0\95\0\63\0\31\0\0\0\223\0\223\0\0\0\8\0\159\0\127\0\0\0\85\0\56\0\28\0\255\0\28\0\0\0\226\0" ..
"\0\0\170\0\56\0\113\0\198\0\0\0\113\0\141\0\255\0\42\0\233\0\63\0\212\0\85\0\191\0\106\0\191\0\21\0\170\0\8\0\170\0\127\0\148\0\148\0\255\0\0\0\0\0\63\0\191\0\95\0\31\0\223\0\255\0\63\0\95\0\63\0\159\0\0\0\0\0\127\0" ..
"\72\0\0\0\0\0\0\0\255\0\0\0\0\0\0\0\72\0\72\0\36\0\8\0\218\0\182\0\145\0\109\0\255\0\162\0\231\0\162\0\231\0\115\0\208\0\139\0\185\0\92\0\185\0\46\0\162\0\69\0\162\0\23\0\255\0\0\0\51\0\0\0\0\0\0\0\102\0\0\0" ..
"\204\0\0\0\153\0\0\0\0\0\0\0\51\0\0\0\0\0\0\0\8\0\36\0\255\0\0\0\182\0\8\0\0\0\0\0\72\0\109\0\145\0\0\0\255\0\218\0\212\0\8\0\170\0\0\0\127\0\0\0\85\0\8\0\255\0\8\0\170\0\0\0\127\0\0\0\42\0\8\0" ..
"\255\0\0\0\0\0\0\0\36\0\0\0\182\0\0\0\218\0\0\0\0\0\0\0\72\0\0\0\145\0\109\0\36\0\36\0\0\0\0\0\255\0\0\0\182\0\0\0\0\0\0\0\0\0\0\109\218\0\0\0\145\0\72\72\255\0\28\0\226\0\56\0\198\0\0\0\0\0\28\28" ..
"\170\0\0\0\141\0\0\0\113\0\0\0\85\85\85\85\255\0\0\0\0\0\95\0\0\0\127\0\0\0\0\0\223\0\95\0\63\0\31\0\191\0\0\0\159\0\0\0\0\0\31\0\255\0\0\0\0\0\95\0\223\0\0\0\0\0\63\0\191\0\0\0\0\0\0\0\159\0\127\0" ..
"\141\0\28\0\28\0\28\0\113\0\8\0\8\0\8\0\255\0\0\0\226\0\0\0\198\0\56\0\170\0\85\0\255\0\0\0\8\0\0\0\182\0\0\0\72\0\0\0\218\0\0\0\36\0\0\0\145\0\0\0\109\0\0\0\0\0\51\25\76\25\25\0\153\0\0\0\127\102\178\0" ..
"\204\0\0\0\0\0\255\0\0\0\102\0\229\0\76\0\113\0\0\0\141\0\85\0\0\0\0\0\170\0\0\0\56\28\255\0\0\0\0\0\198\0\0\0\226\0\0\0\255\0\8\0\28\0\28\0\198\0\56\0\56\0\85\0\255\0\85\0\113\0\113\0\226\0\141\0\170\0\141\0" ..
"\0\0\0\0\0\0\0\0\255\0\0\0\127\0\0\0\0\0\0\0\0\0\0\0\63\0\0\0\191\0\0\0\255\0\0\0\255\0\127\0\0\0\85\0\0\0\212\0\0\0\212\0\42\0\170\0\0\0\127\0\0\0\0\0\255\0\0\0\0\0\218\0\182\0\0\0\0\0\145\0" ..
"\145\0\36\0\0\0\109\0\109\0\0\0\72\0\36\0\0\0\0\0\109\0\8\0\72\0\0\0\255\0\182\0\0\0\0\0\145\0\8\0\36\0\8\0\218\0\182\0\255\0\0\0\0\0\226\0\85\0\0\0\141\0\0\0\0\0\0\0\170\0\56\0\198\0\0\0\113\0\28\0" ..
"\255\0\0\0\113\0\0\0\198\0\56\0\85\0\28\0\255\0\0\0\226\0\0\0\170\0\0\0\141\0\0\0\0\0\0\0\0\0\0\0\255\0\145\0\109\0\218\0\36\0\182\0\72\0\72\0\255\0\0\0\0\0\109\0\36\0\36\0\145\0\0\0\72\0\72\0\182\0\0\0" ..
"\72\0\72\0\218\0\0\0\109\0\109\0\255\0\0\0\255\0\0\0\218\0\0\0\145\0\0\0\36\0\0\0\218\0\0\0\36\0\0\0\182\0\72\0\0\0\109\0\0\0\0\0\8\0\0\0\255\0\85\0\212\0\42\0\0\0\0\0\8\0\0\0\85\0\170\0\127\0\42\0" ..
"\109\0\109\0\255\0\0\0\72\0\72\0\218\0\0\0\145\0\182\0\255\0\0\0\36\0\36\0\218\0\8\0\255\0\0\0\42\0\0\0\212\0\0\0\8\0\212\0\170\0\0\0\85\0\0\0\212\0\8\0\127\0\8\0\255\0\85\0\0\0\0\0\226\0\85\0\0\0\198\0" ..
"\0\0\141\0\56\0\0\0\170\0\28\0\0\0\113\0\113\0\56\0\255\0\0\0\85\0\56\0\226\0\0\0\0\0\170\0\0\0\141\0\28\0\28\0\198\0\28\0\255\0\0\0\229\0\0\0\204\0\204\0\0\0\76\0\178\0\153\0\51\0\178\0\178\0\127\0\102\51\51\25" ..
"\0\0\0\0\0\0\0\31\0\0\0\0\255\0\0\31\0\0\8\0\0\0\191\159\127\95\95\0\223\0\63\0\255\0\255\0\204\204\204\204\0\0\51\51\51\51\0\0\204\0\204\0\153\153\153\153\153\0\0\0\102\102\102\102\170\0\0\0\0\255\0\0\198\0\0\0\0\28\0\0" ..
"\141\0\0\0\0\226\0\0\56\0\0\113\0\85\0\0\255\0\0\0\0\113\0\0\85\0\0\0\0\226\0\0\141\0\0\8\0\170\56\56\198\0\0\56\0\141\28\0\255\0\0\0\0\191\0\0\159\0\0\0\0\223\0\0\95\0\0\0\0\63\0\0\127\0\0\0\0\31\0\0"
dm = {
  {10,8,0,9,11},
  {15,7,13,12,6},
  {18,14,4,5,3},
  {23,16,21,1,2},
  {24,19,17,20,22},
}
function u8mix(a, b, mix)
  return a + (b - a) * mix // 256
end
function read_drum_map(step, inst, x, y)
  local i = x >> 6
  local j = y >> 6
  if i > 3 then i = 3 end
  if j > 3 then j = 3 end
  local off = inst * 32 + step + 1
  local a = string.byte(PAT, dm[i+1][j+1] * 96 + off)
  local b = string.byte(PAT, dm[i+2][j+1] * 96 + off)
  local c = string.byte(PAT, dm[i+1][j+2] * 96 + off)
  local d = string.byte(PAT, dm[i+2][j+2] * 96 + off)
  local fx = (x & 0x3F) << 2
  local fy = (y & 0x3F) << 2
  return u8mix(u8mix(a, b, fx), u8mix(c, d, fx), fy)
end
function eucl_hit(step, hits, len, rot)
  if hits <= 0 then return false end
  if hits >= len then return true end
  local s = (step + rot) % len
  return (s * hits) % len < hits
end
STEPS = 32
NT = 4
ACC_THRESH = 192
TPT = 12
RATES = {{1,4},{1,3},{1,2},{1,1},{2,1},{3,1},{4,1},{6,1},{8,1}}
RATE_DEF = 4
RESET_THRESH = 16
FILL_BOOST = 128
BOOT_FRAMES = 30
CTX_MAIN = 1
CTX_CONFIG = 2
PG_DENSITY = 1
PG_MAP = 2
PG_LENGTH = 3
PG_ROTATE = 4
MAIN_GRIDS = {PG_DENSITY, PG_MAP, PG_ROTATE}
MAIN_EUCL  = {PG_DENSITY, PG_LENGTH, PG_ROTATE}
CG_MODE = 1
CG_RATE = 2
CG_NOTE = 3
CG_CH = 4
CG_VEL = 5
CG_FEEL = 6
CG_INST = 7
CONFIG_LIST = {CG_MODE, CG_INST, CG_RATE, CG_NOTE, CG_CH, CG_VEL, CG_FEEL}
INST_MAP = {0, 1, 2, 0}
NOTE_DEF = {36, 38, 42, 37}
map_x = 128
map_y = 128
chaos = 0
bpm = 120
humanize = 0
swing = 0
mode = 0
ctx = CTX_MAIN
page = {1, 1}
alt = false
fill_on = false
FILL_MIN = -32
SCENE_THRESH = 16
SCENE_XF_MAX = 64
scene = {}
scene_acc = 0
xf_pos = 0
trk = {}
for i = 1, NT do
  trk[i] = {
    density = 128,
    rate = RATE_DEF,
    rotation = 0,
    eucl_len = 16,
    note = NOTE_DEF[i],
    ch = 10,
    vel_min = 80,
    vel_max = 127,
    step = 0,
    acc = 0,
    inst = INST_MAP[i],
  }
end
playing = true
note_active = {false, false, false, false}
note_on_n = {0, 0, 0, 0}
note_on_ch = {0, 0, 0, 0}
trig_flash = {0, 0, 0, 0}
trig_accent = {false, false, false, false}
trig_vel = {0, 0, 0, 0}
pend_vel = {0, 0, 0, 0}
cur_step = {0, 0, 0, 0}
drop_amt = 0
DROP_STAGES = {{4,-1}, {2,-1}, {3,-1}, {1,-1}, {3,1}}
DROP_MAX = 80
DROP_BLOCKS = {{25,32}, {17,23}, {9,15}, {0,7}}
clkout_acc = 0
function drop_factor(t)
  local f = 1
  local a = drop_amt
  for i = 1, #DROP_STAGES do
    if a <= 0 then break end
    local st = DROP_STAGES[i]
    local seg = a < 16 and a or 16
    if st[1] == t then
      f = st[2] < 0 and 1 - seg / 16 or seg / 16
    end
    a = a - 16
  end
  return f
end
function lerp(a, b, f) return math.floor(a + (b - a) * f + 0.5) end
function save_scene(slot)
  local s = {map_x, map_y, chaos, bpm, humanize, swing}
  for t = 1, NT do
    s[#s+1] = trk[t].density
    s[#s+1] = trk[t].rotation
    s[#s+1] = trk[t].eucl_len
  end
  scene[slot] = s
end
function apply_scene(f)
  local A, B = scene[1], scene[2]
  if not A or not B then return end
  map_x = lerp(A[1], B[1], f); map_y = lerp(A[2], B[2], f); chaos = lerp(A[3], B[3], f)
  bpm = lerp(A[4], B[4], f); humanize = lerp(A[5], B[5], f); swing = lerp(A[6], B[6], f)
  for t = 1, NT do
    local b = 6 + (t - 1) * 3
    trk[t].density = lerp(A[b+1], B[b+1], f)
    trk[t].rotation = lerp(A[b+2], B[b+2], f) % STEPS
    trk[t].eucl_len = clamp(lerp(A[b+3], B[b+3], f), 1, 32)
  end
end
pending = {}
pend_acc = {false, false, false, false}
ext_clock = false
last_midi_t = 0
tick_ct = 0
time_accum = 0
last_t = 0
perturb = {0, 0, 0, 0}
dirty = true
flash_ctr = 0
flash_lvl = 0
seeded = false
reset_acc = 0
reset_flash = 0
boot_anim = 0
function eff_density(t)
  if fill_on then return clamp(trk[t].density + FILL_BOOST, 0, 255) end
  return trk[t].density
end
function main_list()
  return mode == 0 and MAIN_GRIDS or MAIN_EUCL
end
function cur_main()
  return main_list()[page[CTX_MAIN]]
end
function cur_config()
  return CONFIG_LIST[page[CTX_CONFIG]]
end
function tick_period()
  local base = 60 / (bpm * 8) / TPT
  if swing > 0 then
    if (tick_ct // (TPT * 2)) % 2 == 0 then
      base = base * (1 + swing / 100)
    else
      base = base * (1 - swing / 100)
    end
  end
  if base < 0.002 then base = 0.002 end
  return base
end
function fire_note(t, accent, vbase)
  local tr = trk[t]
  if note_active[t] then
    midi_note_off(note_on_n[t], 0, note_on_ch[t])
  end
  local vel = vbase
  if humanize > 0 then
    local j = math.max(0, tr.vel_max - tr.vel_min) * humanize // 200
    if j > 0 then vel = vel + math.random(-j, j) end
  end
  vel = clamp(vel, 1, 127)
  midi_note_on(tr.note, vel, tr.ch)
  note_active[t] = true
  note_on_n[t] = tr.note
  note_on_ch[t] = tr.ch
  trig_flash[t] = accent and 5 or 3
  trig_accent[t] = accent
  trig_vel[t] = vel
  dirty = true
end
function process_step(t)
  local tr = trk[t]
  local hit = false
  local accent = false
  local vbase = tr.vel_min
  if mode == 0 then
    if tr.step == 0 then
      local r = chaos >> 2
      perturb[t] = r > 0 and math.random(0, r) or 0
    end
    local s = (tr.step + tr.rotation) % STEPS
    local level = read_drum_map(s, tr.inst, map_x, map_y)
    if level < 255 - perturb[t] then
      level = level + perturb[t]
    else
      level = 255
    end
    if level > 255 - eff_density(t) then
      hit = true
      accent = level > ACC_THRESH
      vbase = tr.vel_min + (tr.vel_max - tr.vel_min) * level // 255
    end
  else
    local hits = clamp(math.floor(eff_density(t) / 255 * tr.eucl_len + 0.5), 0, tr.eucl_len)
    hit = eucl_hit(tr.step, hits, tr.eucl_len, tr.rotation)
    accent = hit and (tr.step + tr.rotation) % tr.eucl_len == 0
    if accent then vbase = tr.vel_max end
  end
  if hit and drop_amt > 0 then
    local f = drop_factor(t)
    if f <= 0 then
      hit = false
    elseif f < 1 then
      vbase = math.max(1, math.floor(vbase * f + 0.5))
    end
  end
  if hit then
    local dly = 0
    if humanize > 0 then
      dly = math.random(0, (humanize * 6 + 50) // 100)
    end
    if dly > 0 then
      pending[t] = dly
      pend_acc[t] = accent
      pend_vel[t] = vbase
    else
      fire_note(t, accent, vbase)
    end
  end
end
function do_tick(nsub)
  tick_ct = (tick_ct + nsub) % (TPT * 4)
  if playing and not ext_clock then
    clkout_acc = clkout_acc + nsub
    while clkout_acc >= 4 do
      clkout_acc = clkout_acc - 4
      midi_tx(0xF8)
    end
  end
  if not playing then return end
  for t = 1, NT do
    if note_active[t] then
      midi_note_off(note_on_n[t], 0, note_on_ch[t])
      note_active[t] = false
    end
  end
  for t = 1, NT do
    if pending[t] then
      pending[t] = pending[t] - nsub
      if pending[t] <= 0 then
        pending[t] = nil
        fire_note(t, pend_acc[t], pend_vel[t])
      end
    end
  end
  for t = 1, NT do
    local r = RATES[trk[t].rate]
    local thresh = r[2] * TPT
    trk[t].acc = trk[t].acc + r[1] * nsub
    while trk[t].acc >= thresh do
      trk[t].acc = trk[t].acc - thresh
      process_step(t)
      cur_step[t] = trk[t].step
      local len = mode == 1 and trk[t].eucl_len or STEPS
      trk[t].step = (trk[t].step + 1) % len
      dirty = true
    end
  end
end
function reset_transport(nsub)
  for t = 1, NT do
    local r = RATES[trk[t].rate]
    trk[t].step = 0
    cur_step[t] = 0
    trk[t].acc = r[2] * TPT - r[1] * nsub
    pending[t] = nil
  end
  tick_ct = 0
end
function all_notes_off()
  for t = 1, NT do
    if note_active[t] then
      midi_note_off(note_on_n[t], 0, note_on_ch[t])
      note_active[t] = false
    end
    pending[t] = nil
  end
end
function do_reset()
  all_notes_off()
  reset_transport(1)
  clkout_acc = 0
  if not ext_clock then midi_tx(0xFA) end
end
function event_midi(b1, b2, b3)
  if b1 == 0xF8 then
    last_midi_t = get_time()
    ext_clock = true
    do_tick(4)
  elseif b1 == 0xFA then
    reset_transport(4)
    playing = true
  elseif b1 == 0xFC then
    playing = false
    all_notes_off()
  elseif b1 == 0xFB then
    playing = true
  end
end
k_down = false
k_time = 0
last_down = -1
click_wait = false
swallow = false
need_save = false
cur_res = {0, 0, 0, 0}
function set_res(n, div)
  if cur_res[n] ~= div then
    cur_res[n] = div
    arc_res(n, div)
  end
end
function event_arc_key(z)
  local now = get_time()
  if z == 1 then
    k_down = true
    if click_wait and (now - last_down) < 0.35 then
      click_wait = false
      swallow = true
      km:stop()
      on_double_click()
    else
      if click_wait then
        click_wait = false
        on_short_click()
      end
      swallow = false
      k_time = now
      km:start(0.3, 1)
    end
    last_down = now
  else
    k_down = false
    km:stop()
    if alt then
      alt = false
      enter_page()
      dirty = true
      return
    end
    if swallow then
      swallow = false
      return
    end
    if (now - k_time) < 0.3 then
      click_wait = true
      km:start(0.35, 1)
    end
  end
end
function key_timer()
  km:stop()
  if k_down then
    if not swallow and (get_time() - k_time) >= 0.28 then
      alt = true
      set_alt_res()
      dirty = true
    end
  elseif click_wait then
    click_wait = false
    on_short_click()
  end
end
function set_alt_res()
  if ctx ~= CTX_MAIN then return end
  if cur_main() == PG_ROTATE then
    for i = 1, 4 do set_res(i, 32) end
  else
    set_res(1, 16); set_res(2, 8); set_res(3, 16); set_res(4, 8)
    reset_acc = 0
    scene_acc = 0
  end
end
function on_short_click()
  local list = ctx == CTX_MAIN and main_list() or CONFIG_LIST
  page[ctx] = (page[ctx] % #list) + 1
  enter_page()
  dirty = true
end
function on_double_click()
  if ctx == CTX_MAIN then
    ctx = CTX_CONFIG
    flash_lvl = 6
  else
    ctx = CTX_MAIN
    flash_lvl = 12
  end
  need_save = true
  flash_ctr = 3
  enter_page()
  dirty = true
end
function enter_page()
  if ctx == CTX_MAIN then
    local p = cur_main()
    if p == PG_LENGTH then for i = 1, 4 do set_res(i, 32) end
    elseif p == PG_ROTATE then for i = 1, 4 do set_res(i, 16) end
    else for i = 1, 4 do set_res(i, 4) end end
  else
    local p = cur_config()
    if p == CG_VEL then for i = 1, 4 do set_res(i, 4) end
    elseif p == CG_FEEL then set_res(1, 8); set_res(2, 8); set_res(3, 4); set_res(4, 4)
    else for i = 1, 4 do set_res(i, 32) end end
  end
end
function set_eucl_len(n, d)
  trk[n].eucl_len = clamp(trk[n].eucl_len + (d > 0 and 1 or -1), 1, 32)
  if mode == 1 then
    trk[n].step = trk[n].step % trk[n].eucl_len
    cur_step[n] = cur_step[n] % trk[n].eucl_len
  end
end
function set_mode(m)
  if m == mode then return end
  mode = m
  for i = 1, NT do
    local l = mode == 1 and trk[i].eucl_len or STEPS
    trk[i].step = trk[i].step % l
    cur_step[i] = cur_step[i] % l
  end
  local ml = main_list()
  if page[CTX_MAIN] > #ml then page[CTX_MAIN] = #ml end
end
function delta_global(n, d)
  if n == 1 then map_x = clamp(map_x + d, 0, 255)
  elseif n == 2 then map_y = clamp(map_y + d, 0, 255)
  elseif n == 3 then chaos = clamp(chaos + d, 0, 255)
  else bpm = clamp(bpm + d, 40, 240) end
end
function delta_density(n, d)
  trk[n].density = clamp(trk[n].density + d, 0, 255)
end
function delta_trans(n, d)
  if n == 1 then
    if not playing then
      if d > 0 then
        playing = true
        reset_acc = 0
        if not ext_clock then midi_tx(0xFB) end
      end
    else
      reset_acc = reset_acc + d
      if reset_acc >= RESET_THRESH then
        do_reset()
        reset_flash = 10
        reset_acc = 0
      elseif reset_acc < 0 then
        playing = false
        reset_acc = 0
        all_notes_off()
        if not ext_clock then midi_tx(0xFC) end
      end
    end
  elseif n == 2 then
    drop_amt = clamp(drop_amt - d, FILL_MIN, DROP_MAX)
    fill_on = drop_amt <= FILL_MIN
  elseif n == 3 then
    scene_acc = scene_acc - d
    if scene_acc >= SCENE_THRESH then
      save_scene(2); reset_flash = 10; scene_acc = 0
    elseif scene_acc <= -SCENE_THRESH then
      save_scene(1); reset_flash = 10; scene_acc = 0
    end
  elseif n == 4 then
    xf_pos = clamp(xf_pos - d, 0, SCENE_XF_MAX)
    apply_scene(xf_pos / SCENE_XF_MAX)
  end
end
function event_arc(n, d)
  if not seeded then
    seeded = true
    math.randomseed(math.floor(get_time() % 100000 * 1000) + n * 7919 + d)
  end
  if ctx == CTX_MAIN then
    local p = cur_main()
    if p == PG_ROTATE then
      if alt then
        trk[n].rotation = 0
      else
        trk[n].rotation = (trk[n].rotation + (d > 0 and -1 or 1)) % STEPS
      end
    elseif alt then
      delta_trans(n, d)
    elseif p == PG_DENSITY then delta_density(n, d)
    elseif p == PG_MAP then delta_global(n, d)
    elseif p == PG_LENGTH then set_eucl_len(n, d)
    end
  else
    local p = cur_config()
    if p == CG_MODE then
      set_mode(d > 0 and 1 or 0)
    elseif p == CG_INST then
      trk[n].inst = clamp(trk[n].inst + (d > 0 and -1 or 1), 0, 2)
    elseif p == CG_RATE then
      trk[n].rate = clamp(trk[n].rate + (d > 0 and 1 or -1), 1, #RATES)
      trk[n].acc = trk[n].acc % (RATES[trk[n].rate][2] * TPT)
    elseif p == CG_NOTE then
      if alt then
        local oct = clamp(trk[n].note // 12, 0, 6)
        oct = clamp(oct + (d > 0 and 1 or -1), 0, 6)
        trk[n].note = clamp(oct * 12 + trk[n].note % 12, 0, 127)
      else
        trk[n].note = clamp(trk[n].note + (d > 0 and 1 or -1), 0, 127)
      end
    elseif p == CG_CH then
      trk[n].ch = clamp(trk[n].ch + (d > 0 and 1 or -1), 1, 16)
    elseif p == CG_VEL then
      if alt then
        trk[n].vel_min = clamp(trk[n].vel_min + d, 0, trk[n].vel_max)
      else
        trk[n].vel_max = clamp(trk[n].vel_max + d, trk[n].vel_min, 127)
      end
    elseif p == CG_FEEL then
      if n == 1 then humanize = clamp(humanize + d, 0, 100)
      elseif n == 2 then swing = clamp(swing + d, 0, 75)
      elseif n == 3 then chaos = clamp(chaos + d, 0, 255)
      elseif n == 4 then bpm = clamp(bpm + d, 40, 240) end
    end
  end
  dirty = true
end
function grid_led(slot)
  return (16 + slot) % 64 + 1
end
function draw_boot()
  local head = (BOOT_FRAMES - boot_anim) * 3
  for t = 1, NT do
    for i = 0, 10 do
      local pos = head - (t - 1) * 4 - i
      if pos >= 0 and pos < 64 then
        local b = 15 - i - i // 2
        if b > 0 then arc_led(t, pos + 1, b) end
      end
    end
  end
end
function north_pos(slot)
  return (48 + slot) % 64 + 1
end
function draw_north_fill(ring, frac, bright)
  local n = math.floor(frac * 32 + 0.5)
  if n > 32 then n = 32 end
  for i = 0, n - 1 do
    arc_led(ring, north_pos(i), bright, true)
  end
end
function global_param_frac(t)
  if t == 1 then return map_x / 255
  elseif t == 2 then return map_y / 255
  elseif t == 3 then return chaos / 255
  else return (bpm - 40) / 200 end
end
GAUGE_START = 38
GAUGE_LEN = 55
function gauge_led(i)
  return (GAUGE_START - 1 + i) % 64 + 1
end
function draw_gauge(ring, frac, bright)
  for i = 0, GAUGE_LEN - 1 do
    arc_led(ring, gauge_led(i), 1)
  end
  local n = math.floor(frac * GAUGE_LEN + 0.5)
  if n > GAUGE_LEN then n = GAUGE_LEN end
  for i = 0, n - 1 do
    arc_led(ring, gauge_led(i), bright)
  end
  if n > 0 then
    arc_led(ring, gauge_led(n - 1), 15)
  end
end
function main_tick()
  local now = get_time()
  if ext_clock and (now - last_midi_t) > 2.0 then
    ext_clock = false
    playing = true
    last_t = now
    time_accum = 0
    clkout_acc = 0
  end
  if not ext_clock then
    time_accum = time_accum + (now - last_t)
    local guard = 0
    local tp = tick_period()
    while time_accum >= tp and guard < 96 do
      time_accum = time_accum - tp
      do_tick(1)
      tp = tick_period()
      guard = guard + 1
    end
  end
  last_t = now
  for t = 1, NT do
    if trig_flash[t] > 0 then
      trig_flash[t] = trig_flash[t] - 1
      dirty = true
    end
  end
  if flash_ctr > 0 then
    flash_ctr = flash_ctr - 1
    dirty = true
  end
  if reset_flash > 0 then
    reset_flash = reset_flash - 1
    dirty = true
  end
  if boot_anim > 0 then
    boot_anim = boot_anim - 1
    dirty = true
  end
  if (ctx == CTX_MAIN and alt and cur_main() ~= PG_ROTATE)
    or (ctx == CTX_CONFIG and cur_config() == CG_FEEL) then
    dirty = true
  end
  redraw()
  if need_save and flash_ctr == 0 and boot_anim == 0 then
    need_save = false
    save_pset()
  end
end
function redraw()
  if not dirty then return end
  dirty = false
  if boot_anim > 0 then
    arc_led_all(0)
    draw_boot()
    arc_refresh()
    return
  end
  if flash_ctr > 0 then
    arc_led_all(flash_lvl)
    arc_refresh()
    return
  end
  arc_led_all(0)
  if ctx == CTX_MAIN then
    local p = cur_main()
    if alt and p ~= PG_ROTATE then redraw_trans()
    elseif p == PG_DENSITY then redraw_density()
    elseif p == PG_MAP then redraw_map()
    elseif p == PG_LENGTH then redraw_length()
    elseif p == PG_ROTATE then redraw_rotate() end
  else
    local p = cur_config()
    if p == CG_MODE then redraw_mode()
    elseif p == CG_INST then redraw_inst()
    elseif p == CG_RATE then redraw_rate()
    elseif p == CG_NOTE then redraw_note()
    elseif p == CG_CH then redraw_ch()
    elseif p == CG_VEL then redraw_vel()
    elseif p == CG_FEEL then redraw_feel() end
  end
  arc_refresh()
end
function north_bright(t)
  if trig_flash[t] > 0 then
    return clamp(4 + trig_flash[t] * 3, 5, trig_accent[t] and 15 or 11)
  end
  return 4
end
function redraw_density()
  for t = 1, NT do
    local fb = 0
    if trig_flash[t] > 0 then fb = clamp(trig_vel[t] * trig_flash[t] // 64, 0, 12) end
    arc_led_ring(t, fb)
    draw_pattern(t, 64, fb)
  end
end
function draw_pattern(t, span, floorb)
  floorb = floorb or 0
  local tr = trk[t]
  local dens = eff_density(t)
  local full = span == 64
  local thr = 255 - dens
  if mode == 0 then
    local pt = perturb[t]
    for d = 0, span - 1 do
      local level = read_drum_map((d % STEPS + tr.rotation) % STEPS, tr.inst, map_x, map_y)
      local b = 0
      if level > thr then b = clamp(level // 24 + 4, 5, 14)
      elseif pt > 0 and level + pt > thr then b = 4
      elseif level > 96 then b = 3 end
      if full and d % 8 == 0 and b < 1 then b = 1 end
      if b > floorb then arc_led(t, grid_led(d), b) end
    end
    local ph = cur_step[t] % STEPS
    arc_led(t, grid_led(ph), 15)
    if full then arc_led(t, grid_led(ph + STEPS), 15) end
  else
    local hits = clamp(math.floor(dens / 255 * tr.eucl_len + 0.5), 0, tr.eucl_len)
    local ph = cur_step[t] % tr.eucl_len
    for s = 0, tr.eucl_len - 1 do
      local on = eucl_hit(s, hits, tr.eucl_len, tr.rotation)
      local b = on and 11 or 1
      if s == ph then b = on and 15 or 6 end
      if b > floorb then arc_led(t, grid_led(math.floor(s * span / tr.eucl_len)), b) end
    end
  end
end
function redraw_map()
  for t = 1, NT do
    arc_led_ring(t, 0)
    draw_north_fill(t, global_param_frac(t), north_bright(t))
    draw_pattern(t, 32, 0)
  end
end
function redraw_length()
  for t = 1, NT do
    arc_led_ring(t, 0)
    draw_north_fill(t, trk[t].eucl_len / 32, north_bright(t))
    for k = 4, trk[t].eucl_len, 4 do
      arc_led(t, north_pos(k - 1), 15)
    end
    draw_pattern(t, 32, 0)
  end
end
function redraw_rotate()
  for t = 1, NT do
    arc_led_ring(t, 0)
    draw_pattern(t, 64, 0)
  end
end
function redraw_rate()
  for t = 1, NT do
    arc_led_ring(t, 0)
    local r = RATES[trk[t].rate]
    local num, den = r[1], r[2]
    local b = (num == 1 and den == 1) and 12 or 8
    for i = 0, num - 1 do arc_led(t, 35 + i, b) end
    for i = 0, den - 1 do arc_led(t, 31 - i, b) end
  end
end
function redraw_feel()
  local now = get_time()
  for t = 1, NT do
    arc_led_ring(t, 0)
    if t == 1 then
      draw_gauge(t, humanize / 100, 6)
      anim_humanize(t)
    elseif t == 2 then
      draw_gauge(t, swing / 75, 6)
      anim_swing(t, now)
    elseif t == 3 then
      draw_gauge(t, chaos / 255, 6)
      anim_chaos(t)
    elseif t == 4 then
      draw_gauge(t, (bpm - 40) / 200, 6)
      anim_bpm(t, now)
    end
  end
end
function anim_humanize(t)
  local amt = humanize / 100
  if amt <= 0 then return end
  local edge = math.floor(amt * GAUGE_LEN)
  local spread = 1 + math.floor(amt * 6)
  for k = 1, 3 do
    local slot = clamp(edge + math.random(-spread, spread), 0, GAUGE_LEN - 1)
    arc_led(t, gauge_led(slot), math.random(4, 11), true)
  end
end
function anim_swing(t, now)
  local sw = swing / 100
  local eighth = 60 / bpm / 2
  local ph = (now % eighth) / eighth
  local split = 0.5 * (1 + sw)
  local pos
  if ph < split then pos = (ph / split) * 0.5
  else pos = 0.5 + ((ph - split) / (1 - split)) * 0.5 end
  local led = 29 + math.floor(pos * 8 + 0.5)
  arc_led(t, 33, 3)
  arc_led(t, led, 15)
end
function anim_chaos(t)
  local amt = chaos / 255
  if amt <= 0 then return end
  local n = 1 + math.floor(amt * 8)
  for k = 1, n do
    arc_led(t, math.random(1, 64), math.random(2, 4 + math.floor(amt * 8)), true)
  end
end
function anim_bpm(t, now)
  local beat = 60 / bpm
  local ph = (now % beat) / beat
  local b = 0
  if ph < 0.12 then b = 15
  elseif ph < 0.24 then b = 7 end
  if b > 0 then
    arc_led(t, 33, b)
    arc_led(t, 1, b)
  end
end
function redraw_trans()
  if reset_flash > 0 then
    arc_led_all(clamp(reset_flash + 5, 1, 15))
    return
  end
  for t = 1, NT do arc_led_ring(t, 0) end
  if playing then
    for i = 0, STEPS do arc_led(1, grid_led(i), 1) end
    arc_led(1, grid_led(cur_step[1] % STEPS), 15)
  else
    for i = 0, 2 do arc_led(1, 29 + i, 9); arc_led(1, 35 + i, 9) end
  end
  if reset_acc > 0 then
    for i = 0, math.floor(reset_acc / RESET_THRESH * STEPS) do arc_led(1, grid_led(i), 13) end
  end
  if drop_amt > 0 then
    for t = 1, NT do
      local b = math.floor(drop_factor(t) * 12 + 0.5)
      if drop_factor(t) > 0 and b < 1 then b = 1 end
      if b > 0 then local blk = DROP_BLOCKS[t]; for i = blk[1], blk[2] do arc_led(2, grid_led(i), b) end end
    end
  elseif fill_on then
    for i = 0, STEPS do arc_led(2, north_pos(i), 6) end
    for i = 0, STEPS do arc_led(2, grid_led(i), 12) end
  else
    for i = 0, STEPS do arc_led(2, grid_led(i), 2) end
    if drop_amt < 0 then draw_north_fill(2, -drop_amt / -FILL_MIN, 9) end
  end
  arc_led(3, 49, 10); arc_led(3, 17, 10)
  arc_led(3, wrap(33 - math.floor(scene_acc / SCENE_THRESH * 16 + 0.5), 1, 64), 15)
  for i = 0, STEPS do arc_led(4, grid_led(i), 1) end
  arc_led(4, 49, 6); arc_led(4, 17, 6)
  arc_led(4, grid_led(math.floor((1 - xf_pos / SCENE_XF_MAX) * STEPS + 0.5)), 15)
end
function redraw_mode()
  for t = 1, NT do
    arc_led_ring(t, 0)
    draw_pattern(t, 32, 0)
  end
end
function redraw_inst()
  for t = 1, NT do
    arc_led_ring(t, 0)
    for i = 0, 2 do
      local c = 41 - i * 8
      if trk[t].inst == i then
        arc_led(t, c, 15)
        arc_led(t, c - 1, 4)
        arc_led(t, c + 1, 4)
      else
        arc_led(t, c, 2)
      end
    end
  end
end
function redraw_note()
  for t = 1, NT do
    arc_led_ring(t, 0)
    local note = trk[t].note
    local semi = note % 12
    local oct = clamp(note // 12, 0, 6)
    local sb = alt and 6 or 12
    local ob = alt and 12 or 6
    for i = 0, 11 do
      arc_led(t, 36 + i, i == semi and sb or 1)
    end
    for i = 0, 6 do
      arc_led(t, 49 + i, i == oct and ob or 1)
    end
  end
end
function redraw_ch()
  for t = 1, NT do
    arc_led_ring(t, 0)
    for i = 1, 16 do
      arc_led(t, 24 + i, trk[t].ch == i and 12 or 1)
    end
  end
end
function vel_slot(v)
  return v * (GAUGE_LEN - 1) // 127
end
function redraw_vel()
  for t = 1, NT do
    arc_led_ring(t, 0)
    for i = 0, GAUGE_LEN - 1 do arc_led(t, gauge_led(i), 1) end
    local lo = vel_slot(trk[t].vel_min)
    local hi = vel_slot(trk[t].vel_max)
    for i = lo, hi do arc_led(t, gauge_led(i), 4) end
    if alt then
      arc_led(t, gauge_led(hi), 6)
      arc_led(t, gauge_led(lo), 15)
    else
      arc_led(t, gauge_led(lo), 6)
      arc_led(t, gauge_led(hi), 15)
    end
  end
end
function save_pset()
  local data = {
    script = "griii",
    map_x = map_x, map_y = map_y,
    chaos = chaos, bpm = bpm,
    humanize = humanize, swing = swing,
    mode = mode,
    t = {}
  }
  for i = 1, NT do
    data.t[i] = {
      d = trk[i].density, r = trk[i].rate,
      rot = trk[i].rotation,
      el = trk[i].eucl_len, n = trk[i].note,
      ch = trk[i].ch, vn = trk[i].vel_min,
      vx = trk[i].vel_max, is = trk[i].inst,
    }
  end
  data.scene = scene
  pset_write(1, data)
end
function load_pset()
  local data = pset_read(1)
  if not data or data.script ~= "griii" then return false end
  map_x = data.map_x or 128
  map_y = data.map_y or 128
  chaos = data.chaos or 0
  bpm = data.bpm or 120
  humanize = data.humanize or 0
  swing = data.swing or 0
  mode = data.mode or 0
  if data.t then
    for i = 1, NT do
      local d = data.t[i]
      if d then
        trk[i].density = d.d or 128
        trk[i].rate = d.r or RATE_DEF
        trk[i].rotation = d.rot or 0
        trk[i].eucl_len = d.el or 16
        trk[i].note = d.n or NOTE_DEF[i]
        trk[i].ch = d.ch or 10
        trk[i].vel_min = d.vn or 80
        trk[i].vel_max = d.vx or 127
        trk[i].inst = d.is or INST_MAP[i]
        if trk[i].vel_min > trk[i].vel_max then
          trk[i].vel_min, trk[i].vel_max = trk[i].vel_max, trk[i].vel_min
        end
      end
    end
  end
  if data.scene and data.scene[1] and data.scene[2] then scene = data.scene end
  return true
end
function init()
  math.randomseed(math.floor(get_time() % 100000 * 1000))
  load_pset()
  if not scene[1] then save_scene(1); save_scene(2) end
  reset_transport(1)
  last_t = get_time()
  time_accum = 0
  rm = metro.init(main_tick, 0.033)
  rm:start()
  km = metro.init(key_timer)
  enter_page()
  boot_anim = BOOT_FRAMES
  dirty = true
  redraw()
  print("griii ready")
end
init()
