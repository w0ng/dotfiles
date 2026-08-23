#!/bin/bash
# Paints the whole workspace pill row, and tells the layout item to refresh.
#
# Called directly by aerospace's exec-on-workspace-change callback, and once
# from sketchybarrc for the initial paint.
#
# This does the work for all ten pills in one process rather than having each
# pill run its own script: ten bash spawns plus, on startup where no event
# environment exists, three aerospace queries each. Two queries and one chained
# --set replace all of that.
#
# Pill states: focused / visible on another monitor / has windows / empty.
# The focused workspace is also "visible", so that branch is tested first.

source "$HOME/.config/sketchybar/colors.sh"

# One call yields every workspace plus its visible and focused flags, so the
# workspace list does not have to be duplicated from sketchybarrc. There is no
# workspace-is-empty variable, hence the second call.
all=$(aerospace list-workspaces --monitor all \
        --format '%{workspace} %{workspace-is-visible} %{workspace-is-focused}' 2>/dev/null)
nonempty=" $(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ') "

[ -z "$all" ] && exit 0

args=()
while read -r ws visible focused; do
  [ -z "$ws" ] && continue
  if [ "$focused" = "true" ]; then
    bg="$YELLOW";    fg="$BG0"   # focused — this monitor
  elif [ "$visible" = "true" ]; then
    bg="$GRAY_DARK"; fg="$FG"    # visible on the other monitor
  elif [[ "$nonempty" == *" $ws "* ]]; then
    bg="$BG_DIM";    fg="$FG"    # has windows
  else
    bg="$BG_DIM";    fg="$DIM"   # empty
  fi
  args+=(--set "space.$ws" background.drawing=on background.color="$bg" label.color="$fg")
done <<<"$all"

sketchybar "${args[@]}"

# The layout/monitor items still listen for this.
sketchybar --trigger aerospace_workspace_change
