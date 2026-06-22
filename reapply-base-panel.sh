#!/usr/bin/env bash
# reapply-base-panel.sh
# Re-applies the custom KlipperScreen sidebar shortcut edits to base_panel.py.
#
# base_panel.py is a STOCK KlipperScreen file, so every KlipperScreen
# update/reinstall overwrites it and reverts the sidebar shortcut back to
# the default ("panel": "gcode_macros", "icon": "custom-script").
#
# This restores it to open the Enclosure Lights panel with a light-bulb icon.
# Run after any KlipperScreen update, then restart KlipperScreen.
# Safe anytime: idempotent, backs up before editing, touches only 2 strings.
set -euo pipefail

BP="$HOME/KlipperScreen/panels/base_panel.py"
[[ -f "$BP" ]] || { echo "ERROR: $BP not found" >&2; exit 1; }

need=0
if grep -q '"panel": "gcode_macros"' "$BP"; then need=1; fi
if grep -q '"icon": "custom-script"' "$BP"; then need=1; fi

if [[ $need -eq 0 ]]; then
    echo "Already applied - nothing to do."
    exit 0
fi

cp -a "$BP" "$BP.bak-$(date +%Y%m%d-%H%M%S)"
sed -i 's/"panel": "gcode_macros"/"panel": "enclosure_lights"/' "$BP"
sed -i 's/"icon": "custom-script"/"icon": "light"/' "$BP"
echo "Applied: panel -> enclosure_lights, icon -> light"
echo "Now restart KlipperScreen: sudo systemctl restart KlipperScreen"
