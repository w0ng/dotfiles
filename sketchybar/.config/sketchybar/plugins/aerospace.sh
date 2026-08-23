#!/bin/bash
# Workspace pill: focused / has windows / empty.
#
# $1 is the workspace id this item represents. Both FOCUSED_WORKSPACE and
# NONEMPTY are supplied by the aerospace_workspace_change trigger (see
# exec-on-workspace-change in aerospace.toml), so the common path makes no
# aerospace calls at all. The fallbacks only run on initial load or a manual
# trigger, where $NONEMPTY is absent.

source "$HOME/.config/sketchybar/colors.sh"

sid="$1"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
nonempty="${NONEMPTY:-$(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ')}"

if [ "$sid" = "$focused" ]; then
  bg="$YELLOW"; fg="$BG0"
elif [[ " $nonempty " == *" $sid "* ]]; then
  bg="$BG_DIM"; fg="$FG"        # has windows
else
  bg="$BG_DIM"; fg="$DIM"       # empty
fi

sketchybar --set "$NAME" background.drawing=on background.color="$bg" label.color="$fg"
