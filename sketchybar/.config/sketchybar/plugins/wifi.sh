#!/bin/bash
# Wi-Fi connected / disconnected.
#
# Driven by sketchybar's built-in wifi_change event — nothing polls. The SSID
# is deliberately not shown: macOS redacts it without Location Services access,
# whereas `ipconfig getifaddr` needs no permission at all.

source "$HOME/.config/sketchybar/colors.sh"

if [ -n "$(ipconfig getifaddr en0 2>/dev/null)" ]; then
  icon="󰤨"; label="up";   color="$GREEN"
else
  icon="󰤭"; label="down"; color="$RED"
fi

sketchybar --set "$NAME" icon="$icon" icon.color="$color" \
                         label="$label" label.color="$color"
