#!/bin/bash
# AeroSpace binding mode indicator.
#
# Hidden entirely in 'main' so the bar stays uncluttered; only appears when a
# non-default mode is active. Driven by on-mode-changed in aerospace.toml —
# nothing polls.

source "$HOME/.config/sketchybar/colors.sh"

mode=$(aerospace list-modes --current 2>/dev/null)

if [ -z "$mode" ] || [ "$mode" = "main" ]; then
  sketchybar --set "$NAME" drawing=off
else
  sketchybar --set "$NAME" \
    drawing=on \
    label="$(printf '%s' "$mode" | tr '[:lower:]' '[:upper:]')" \
    label.color="$BG0" \
    background.color="$RED" \
    background.drawing=on
fi
