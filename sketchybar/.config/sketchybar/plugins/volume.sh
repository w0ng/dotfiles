#!/bin/bash
# Output volume, with a speaker icon that tracks the level.

source "$HOME/.config/sketchybar/colors.sh"

volume="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"

case "$volume" in
  100|9[0-9]|8[0-9]|7[0-9]|6[0-9]) icon="󰕾" ;;
  5[0-9]|4[0-9]|3[0-9]) icon="󰖀" ;;
  [1-9]|1[0-9]|2[0-9]) icon="󰕿" ;;
  *) icon="󰝟" ;;
esac

sketchybar --set "$NAME" icon="$icon" icon.color="$AQUA" label="${volume}%"
