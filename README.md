# iii_mod

**Run native monome [_iii_](https://monome.org/docs/iii/) scripts on norns — with any arc/grid, old or new.**

_iii_ is monome's on-device scripting environment, but it only runs on the newest
hardware (grid 2022+, arc 2025+). **iii_mod** is a norns **mod** that runs
*unmodified* native iii scripts on **any** norns + **any** arc/grid, including the
older ones that can't run iii themselves.

Because it's a mod, it runs in the background independently of whatever norns script
you have loaded — so an iii sequencer/controller on your grid or arc can play a normal
norns synth over MIDI (or drive external gear) while your foreground script does its
own thing. One **arc** script and one **grid** script run at a time, each chosen (and
changed on the fly) from `SYSTEM › MODS › iii_mod`. Choices persist across boots.

---

## Install

In maiden's REPL:

```
;install https://github.com/<your-username>/iii_mod
```

Then enable it: `SYSTEM › MODS › iii_mod` → **ON**, and **reboot** (mods load at
startup). Two demo scripts are copied into your data folder automatically on first run,
so there's something to try immediately.

> After install the mod lives in `~/dust/code/iii_mod/` and your scripts/state in
> `~/dust/data/iii_mod/`. (The mod adapts to whatever folder name it is installed under.)

## Add scripts

Drop native iii `.lua` scripts into `~/dust/data/iii_mod/arc/` or `.../grid/`.
Keep any sibling files a script loads next to it (e.g. `rake` needs `rake_data.lua`).
Get scripts from **[codeberg.org/tehn/iii-scripts](https://codeberg.org/tehn/iii-scripts)**
or write your own.

Helper/data files are hidden from the script lists automatically: `lib.lua`, anything
in `blacklist.txt`, and any filename starting with `pset_`, `data_`, `d_`, or `state_`.

```
~/dust/data/iii_mod/
  arc/          native iii ARC scripts (*.lua)   [demo_spin.lua auto-installed]
  grid/         native iii GRID scripts (*.lua)  [demo_keys.lua auto-installed]
  pdata/        per-script saved state (psets) — managed for you
  state.lua     your selections + MIDI settings
  blacklist.txt extra filenames to hide (lib.lua + pset_/data_/d_/state_ auto-hidden)
```

## Use it — `SYSTEM › MODS › iii_mod`

Navigation uses **E2 / E3 / K2 / K3** only (E1/K1 belong to the norns menu):

- **E2** — move the cursor. The **top row is the tab selector** (ARC / GRID / MIDI).
- **E3** — change the focused thing. On the tab row it switches tabs; on a setting row
  it adjusts the value.
- **K3** — activate the focused row (load a script, toggle, advance the tab).
- **K2** — exit.

**ARC / GRID tabs:** power on/off · takeover (auto/forced) · arc-button src (arc) ·
`hold K3` arc button (arc) · the script list (`*` = running, `o` = selected-but-off;
K3 loads the highlighted script).

**MIDI tab** (per device, so arc and grid can go different places):

- **route** — how the two scripts connect:
  - `split` — each device sends to its own out port (point both at the virtual port for
    _grid → norns **&** arc → norns_).
  - `grid>arc` — the grid script's MIDI feeds the **arc** script, and only the arc
    script reaches its out port (_grid → arc → norns_).
  - `arc>grid` — the reverse (_arc → grid → norns_).

  Great for chaining, e.g. a grid sequencer driving an arc arpeggiator into one synth.
  (If the target script isn't running, it falls back to sending to the port.)
- **arc out / grid out** — the norns vport (1–16, by name) each device sends to. In a
  chain route, the feeding device's out port is unused (it goes to the other script).
- **arc in / grid in** — the vport each device receives on (`none` to disable).
- **clock** — `thru` passes incoming MIDI clock; `norns` generates clock (24 ppqn) for
  both; `off` strips clock (scripts self-time).

### Also in the script's PARAMS menu

An **iii_mod** sub-menu appears at the top of whatever norns script you have loaded
(`PARAMS › EDIT › iii_mod`): per-device enable / script / out / in / takeover, plus
clock, arc-button source, and an **arc key** trigger. The menu and params stay in sync.

### Play a norns synth (e.g. Molly the Poly) from an iii script

norns routes MIDI to itself through its **virtual** port, delivered in-process:

1. `SYSTEM › DEVICES › MIDI` → assign **virtual** to a free port slot.
2. On the MIDI tab, set the iii device's **out** to that vport (shows as `N:virtual`).
3. Load the synth and set *its* MIDI-in to the same virtual vport.
4. Play your iii script — it drives the synth. No cables.

### Arc button (for arcs with no physical key)

Many iii scripts use an arc key-press (menus, resets). Set **arc button source** to:

- `None`;
- `B1` / `B2` / `B3` — a norns key (only while a script is playing, never in a menu;
  B2/B3 are taken over, B1 also still toggles the norns menu);
- `GTL` / `GTR` / `GBL` / `GBR` — a **grid corner**, which works even under a foreground
  norns grid script (iii catches just that corner, passing every other key through).

Or fire it ad-hoc: **hold K3** on the ARC tab, or the **arc key** trigger in PARAMS.

---

## Good to know

- **Grid size.** Many iii grid scripts assume a 128 (16×8) grid. On a 64 they still run
  but part of the UI is off-screen; 128/256 are first-class.
- **Foreground scripts that use the grid/arc.** By default iii backs off that device
  (and stops drawing to it) so it won't fight your loaded script; set **takeover** to
  `forced` to override. iii's MIDI keeps flowing either way.
- **Switching foreground scripts** briefly pauses the iii scripts and sends all-notes-off
  (norns frees all timers on every script change); they resume automatically.
- **One arc + one grid** at a time.

## How it works

iii's standard library is pure Lua on a small set of firmware primitives. This mod
provides those primitives on norns (`midi_tx`, `metro_set`, `arc_led`/`grid_led`,
`fs_*`, `get_time`, …), loads iii's own `lib.lua` (bundled, v1.1.2) plus your script into
an isolated sandbox `_ENV`, and dispatches norns arc/grid/MIDI events to the script's
`event_*` callbacks. Virtual metros map lazily onto real norns metros; LED writes go
through a framebuffer diffed to the device; MIDI to a norns "virtual" port is delivered
in-process to the receiving script.

```
lib/
  mod.lua          hooks, menu, params, state/persistence, device/metro orchestration
  iii_runtime.lua  the sandbox: firmware primitives, metros, framebuffers, fs, dispatch
  iii_lib.lua      bundled iii stdlib v1.1.2 (one tweak: lazy slew)
  midi_router.lua  per-device out/in ports (virtual delivered in-process), norns→clock
  devices.lua      arc/grid connect, input takeover/restore, hotplug
  iii_menu.lua     the SYSTEM › MODS screen UI
examples/{arc,grid}/  demo scripts, auto-copied to data on first run
```

## Credits

_iii_ and its standard library are by **[@tehn / monome](https://monome.org/docs/iii/)**
([iii-scripts](https://codeberg.org/tehn/iii-scripts)); `lib/iii_lib.lua` is a bundled
copy of iii's `lib.lua` (v1.1.2). This mod is an independent compatibility runtime;
the reference iii scripts are the work of their respective authors.

## License

MIT — see [LICENSE](LICENSE).
