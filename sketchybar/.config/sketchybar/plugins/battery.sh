#!/bin/bash
# Battery percentage with a charge-level icon, coloured by remaining capacity.

source "$HOME/.config/sketchybar/colors.sh"

# One pmset call serves both lookups.
batt=$(pmset -g batt)
percent=$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | cut -d% -f1)
# Match the battery's own state, not the power source: on AC at 100% pmset
# reports "charged", and keying off "AC Power" would show the charging bolt
# permanently while docked.
charging=$(printf '%s' "$batt" | grep '; charging')

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
