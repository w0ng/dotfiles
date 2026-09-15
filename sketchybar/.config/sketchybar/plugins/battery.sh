#!/usr/bin/env bash
# Battery percentage with a charge-level icon, coloured by remaining capacity.

# shellcheck source-path=SCRIPTDIR source=../colors.sh
source "${HOME}/.config/sketchybar/colors.sh"

# One pmset call serves both lookups.
batt=$(pmset -g batt)
percent=$(printf '%s' "${batt}" | grep -Eo '[0-9]+%' | cut -d% -f1)
# Match the battery's own state, not the power source: on AC at 100% pmset
# reports "charged", and keying off "AC Power" would show the charging bolt
# permanently while docked.
charging=$(printf '%s' "${batt}" | grep '; charging')

[[ -z "${percent}" ]] && exit 0

if [[ -n "${charging}" ]]; then
  icon="󰂄" # nf-md-battery_charging
  color="${GREEN}"
else
  case "${percent}" in
    100 | 9[0-9])
      icon="󰁹" # nf-md-battery
      color="${GREEN}"
      ;;
    8[0-9] | 7[0-9])
      icon="󰂁" # nf-md-battery_80
      color="${GREEN}"
      ;;
    6[0-9] | 5[0-9])
      icon="󰁿" # nf-md-battery_60
      color="${YELLOW}"
      ;;
    4[0-9] | 3[0-9])
      icon="󰁽" # nf-md-battery_40
      color="${ORANGE}"
      ;;
    2[0-9])
      icon="󰁻" # nf-md-battery_20
      color="${ORANGE}"
      ;;
    *)
      icon="󰁺" # nf-md-battery_10
      color="${RED}"
      ;;
  esac
fi

sketchybar --set "${NAME}" icon="${icon}" icon.color="${color}" label="${percent}%"
