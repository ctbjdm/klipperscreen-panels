# KlipperScreen Custom Panels

Custom KlipperScreen panels for the RatRig V-Core 4 500 (`pi@ratos`,
`3dp.computertoolbox.com`).

The real panel files live in **this repo**. They are symlinked into
`~/KlipperScreen/panels/` so KlipperScreen loads them normally while git stays
the single source of truth. This also protects them from a KlipperScreen
update/reinstall — only the symlink is lost, never the code.

## Panels

### `enclosure_lights.py` — WLED enclosure light control
Manual brightness control for the enclosure lights from the touchscreen. Five
buttons: **Off / 25% / 50% / 75% / 100%**, plus a live status label. Talks
straight to the WLED JSON API and coexists with (and overrides) the automatic
`printer-lights` service.

- WLED controller: `3dp-wled.computertoolbox.com` (GLEDOPTO ESP32, PWM/analog white)
- Brightness map (WLED `bri`, 0–255): 25→64, 50→128, 75→191, 100→255
- PWM-white quirk: a bare `{"on":true,"bri":N}` does **not** light an analog
  white strip. The payload must set the white channel and `fx:0` inside the
  segment: `{"seg":[{"fx":0,"col":[[0,0,0,255]]}]}`.
- Runs under KlipperScreen's Python (3.9) — avoid `X | None` type hints here.

### `bed_positions.py` — bed position jog grid
3×3 grid that jogs the toolhead to fixed positions on the 500mm bed (X/Y at
10 / 250 / 490, Z lifted before travel). Base class `ScreenPanel`
(`ks_includes.screen_panel`).

Both panels are registered as menu entries in
`~/printer_data/config/KlipperScreen.conf`.

## The wider enclosure-light system

Three independent control surfaces, all pointing at the same WLED controller:

1. **Automatic — `printer-lights` service**
   `~/vcore-enclosure-lights/printer-lights/printer_lights.py` (systemd:
   `printer-lights`). Watches Moonraker's websocket and drives the lights by
   print state: full bright while printing, dim after an idle delay, and a fade
   preset on Klipper error (snaps back to full once the error clears).

2. **Mainsail buttons** (in the `RatrigVcore4_500` config repo)
   - `~/printer_data/config/wled_set.py` — stdlib-only helper; takes `off` or a
     `0–255` brightness and POSTs the matching payload to WLED.
   - `~/printer_data/config/wled_buttons.cfg` — a `[gcode_shell_command]` plus
     five macros (`LIGHTS_OFF` / `LIGHTS_25` / `LIGHTS_50` / `LIGHTS_75` /
     `LIGHTS_100`), included from `printer.cfg`, grouped under "Lights" on the
     dashboard.

3. **KlipperScreen panel** — `enclosure_lights.py` in this repo.

All three are deliberately independent manual writers to WLED. The panel and
Mainsail buttons are manual overrides; the service owns automatic behavior.
Pressing any manual button overrides the service (including stopping the error
fade) until the next print-state change.

## Restore after a KlipperScreen wipe

```bash
git clone <this-repo-url> ~/klipperscreen-panels
ln -s ~/klipperscreen-panels/bed_positions.py    ~/KlipperScreen/panels/bed_positions.py
ln -s ~/klipperscreen-panels/enclosure_lights.py ~/KlipperScreen/panels/enclosure_lights.py
~/klipperscreen-panels/reapply-base-panel.sh
sudo systemctl restart KlipperScreen
```

Menu entries live in `KlipperScreen.conf`, backed up in the `RatrigVcore4_500`
config repo.

## Why this repo lives outside `~/printer_data/`

Backup copies must **not** be written under `~/printer_data/config/`. Moonraker's
file watcher monitors that tree, and copying files there on a schedule triggers
a file-change storm that floods MoonCord and fires spurious "Printer
disconnected" Discord notifications. Moonraker has no option to exclude a
subfolder, so the only fix is to keep scheduled backup writes out of the watched
tree. This repo sits outside `~/printer_data/` entirely, so it's safe to commit
and push on a schedule.


## Sidebar shortcut (base_panel.py) - re-apply after every KlipperScreen update

The Enclosure Lights side button is wired by editing the hardcoded
self.shorcut dict in ~/KlipperScreen/panels/base_panel.py:

- "panel": "gcode_macros"  ->  "panel": "enclosure_lights"
- "icon": "custom-script"  ->  "icon": "light"

base_panel.py is a STOCK KlipperScreen file, so every KlipperScreen update or
reinstall overwrites it and reverts the shortcut. After any update, run the
idempotent re-apply script, then restart KlipperScreen:

    ~/klipperscreen-panels/reapply-base-panel.sh
    sudo systemctl restart KlipperScreen

It backs up base_panel.py (timestamped) before editing and no-ops if the edits
are already present.

(The [menu __main ...] dashboard TILES for Enclosure Lights and Bed Positions
render from KlipperScreen.conf and are unaffected by this.)
