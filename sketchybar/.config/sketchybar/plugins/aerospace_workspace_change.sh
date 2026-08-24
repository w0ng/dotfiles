#!/bin/bash
# Paints the whole workspace pill row.
#
# Called directly by aerospace's exec-on-workspace-change callback, and once
# from sketchybarrc for the initial paint.
#
# Paints all ten pills from one process and one chained --set, rather than
# giving each pill its own script and paying ten script spawns per switch.
#
# Pill states: focused / visible on another monitor / has windows / empty.
# The focused workspace is also "visible", so that branch is tested first.

source "$HOME/.config/sketchybar/colors.sh"

# Two queries are needed because AeroSpace has no workspace-is-empty variable,
# so `aerospace eval` batches them over one connection (see aerospace_layout.sh
# for why a second call would be expensive). Querying every workspace also
# means the list is not duplicated from sketchybarrc.
#
# Lines are tagged 'A' (every workspace) and 'N' (the non-empty ones). The
# format strings contain no spaces, so they need no quoting inside the eval
# expression, which must stay on one line.
state=$(aerospace eval -- 'list-workspaces --monitor all --format A%{tab}%{workspace}%{tab}%{workspace-is-visible}%{tab}%{workspace-is-focused} ; list-workspaces --monitor all --empty no --format N%{tab}%{workspace}' 2>/dev/null)

[ -z "$state" ] && exit 0

# Pure-bash pass; awk here would add back a process spawn.
nonempty=" "
while IFS=$'\t' read -r tag ws; do
  [ "$tag" = "N" ] && nonempty="$nonempty$ws "
done <<<"$state"

args=()
while IFS=$'\t' read -r tag ws visible focused; do
  [ "$tag" = "A" ] || continue
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
done <<<"$state"

sketchybar "${args[@]}"
