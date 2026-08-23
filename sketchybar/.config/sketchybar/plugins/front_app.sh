#!/bin/bash
# Focused application name.
#
# Driven by the built-in front_app_switched event, so nothing polls. The
# aerospace fallback only runs when $INFO is absent (initial load or a manual
# trigger), which is why it isn't on the hot path.

app="${INFO:-$(aerospace echo -- '%{app-name}' 2>/dev/null)}"
[ -z "$app" ] && exit 0

sketchybar --set "$NAME" label="$app"
