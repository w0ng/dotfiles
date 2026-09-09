#!/bin/bash
# Focused application, as its sketchybar-app-font glyph and its name.
#
# Driven by the built-in front_app_switched event, so nothing polls. The
# aerospace fallback runs only when $INFO is absent, on initial load or a manual
# trigger, so it never lands on the hot path.

source "$HOME/.config/sketchybar/colors.sh"
# The map is a 41KB case statement, and sourcing it costs ~1.5ms against the
# ~9ms of spawning a second bash to run it.
source "$HOME/.config/sketchybar/helpers/icon_map.sh"
source "$HOME/.config/sketchybar/helpers/icon_colors.sh"

app="${INFO:-$(aerospace echo -- '%{app-name}' 2>/dev/null)}"
[ -z "$app" ] && exit 0

__icon_map "$app"

# shellcheck disable=SC2154 # icon_result comes from the sourced map
__icon_color "$icon_result"

# shellcheck disable=SC2154 # color_result likewise
sketchybar --set "$NAME" icon="$icon_result" icon.color="${color_result:-$FG}" \
  label="$app"
