#!/bin/bash
# Battery percentage with a charge-level icon, coloured by remaining capacity.

source "$HOME/.config/sketchybar/colors.sh"

# One pmset call serves both lookups; the upstream sketchybar example calls it
# twice. Worth ~3ms — the greps already pipeline against pmset, so the win is
# smaller than it looks.
batt=$(pmset -g batt)
percent=$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | cut -d% -f1)
charging=$(printf '%s' "$batt" | grep 'AC Power')

[ -z "$percent" ] && exit 0

if [ -n "$charging" ]; then
  icon="󰂄"; color="$GREEN"
else
  case "$percent" in
    100|9[0-9]) icon="󰁹"; color="$GREEN" ;;
    8[0-9]|7[0-9]) icon="󰂁"; color="$GREEN" ;;
    6[0-9]|5[0-9]) icon="󰁿"; color="$YELLOW" ;;
    4[0-9]|3[0-9]) icon="󰁽"; color="$ORANGE" ;;
    2[0-9]) icon="󰁻"; color="$ORANGE" ;;
    *) icon="󰁺"; color="$RED" ;;
  esac
fi

sketchybar --set "$NAME" icon="$icon" icon.color="$color" label="${percent}%"
