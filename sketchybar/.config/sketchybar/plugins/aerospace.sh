#!/bin/bash
# Workspace pill: focused / visible on another monitor / has windows / empty.
#
# $1 is the workspace id this item represents. FOCUSED_WORKSPACE, NONEMPTY and
# VISIBLE all arrive with the aerospace_workspace_change trigger (see
# workspace_change.sh), so the common path makes no aerospace calls at all.
# The fallbacks only run on initial load or a manual trigger.
#
# "Visible" means the workspace is showing on some monitor. The focused
# workspace is visible too, so that case must be tested first.

source "$HOME/.config/sketchybar/colors.sh"

sid="$1"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
nonempty="${NONEMPTY:-$(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ')}"
visible="${VISIBLE:-$(aerospace list-workspaces --monitor all --visible 2>/dev/null | tr '\n' ' ')}"

if [ "$sid" = "$focused" ]; then
  bg="$YELLOW"; fg="$BG0"        # focused — this monitor
elif [[ " $visible " == *" $sid "* ]]; then
  bg="$GRAY_DARK"; fg="$FG"      # visible on the other monitor
elif [[ " $nonempty " == *" $sid "* ]]; then
  bg="$BG_DIM"; fg="$FG"         # has windows
else
  bg="$BG_DIM"; fg="$DIM"        # empty
fi

sketchybar --set "$NAME" background.drawing=on background.color="$bg" label.color="$fg"
