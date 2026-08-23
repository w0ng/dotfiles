#!/bin/bash
# Highlights the focused workspace pill.
# $1 is the workspace id this item represents. FOCUSED_WORKSPACE is exported by
# the aerospace_workspace_change event; fall back to querying AeroSpace so the
# pills are correct on first load too.

source "$HOME/.config/sketchybar/colors.sh"

sid="$1"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

if [ "$sid" = "$focused" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color="$YELLOW" \
    label.color="$BG0"
else
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color="$BG_DIM" \
    label.color="$GRAY"
fi
