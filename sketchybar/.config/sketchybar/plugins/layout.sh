#!/bin/bash
# AeroSpace layout + which monitor is focused.
#
# Drives two bar items from a single query: `layout` and `monitor`. AeroSpace
# has no on-layout-changed callback, so this is triggered by the layout
# keybindings (aerospace_layout_change) and on-focus-changed — nothing polls.
#
# One `aerospace echo` costs ~37ms regardless of how many variables it asks
# for, so folding the monitor lookup into the existing call is free.

source "$HOME/.config/sketchybar/colors.sh"

read -r layout fullscreen is_main <<<"$(
  aerospace echo -- '%{window-layout} %{window-is-fullscreen} %{monitor-is-main}' 2>/dev/null
)"

# ── layout ───────────────────────────────────────────────────────────────────

if [ "$fullscreen" = "true" ]; then
  icon="󰊓"; label="full"; color="$ORANGE"
else
  # AeroSpace reports direction as an h_/v_ prefix: h_tiles, v_accordion, ...
  case "$layout" in
    floating)     icon="󰄯"; label="float";  color="$AQUA"  ;;
    h_tiles)      icon="↔"; label="tiles";  color="$GREEN" ;;
    v_tiles)      icon="↕"; label="tiles";  color="$GREEN" ;;
    h_accordion)  icon="↔"; label="accord"; color="$BLUE"  ;;
    v_accordion)  icon="↕"; label="accord"; color="$BLUE"  ;;
    *)            icon="󰋱"; label="${layout:-—}"; color="$GRAY" ;;
  esac
fi

# ── monitor ──────────────────────────────────────────────────────────────────

if [ "$is_main" = "true" ]; then
  mon_label="main";      mon_color="$GRAY"
else
  mon_label="secondary"; mon_color="$PURPLE"
fi

# background is set on every run so a stray write can't leave it stuck.
sketchybar \
  --set "$NAME" icon="$icon" icon.color="$color" \
                label="$label" label.color="$color" \
                background.color="$BG_DIM" \
  --set monitor  icon="󰍹" icon.color="$mon_color" \
                label="$mon_label" label.color="$mon_color" \
                background.color="$BG_DIM"
