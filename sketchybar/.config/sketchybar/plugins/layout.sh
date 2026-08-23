#!/bin/bash
# AeroSpace layout + which monitor is focused.
#
# Drives two bar items from a single query: `layout` and `monitor`. AeroSpace
# has no on-layout-changed callback, so this is triggered by the layout
# keybindings (aerospace_layout_change) and on-focus-changed — nothing polls.
#
# Each `aerospace echo` costs ~22ms, so this makes two calls rather than one —
# see the note below for why they cannot be combined.

source "$HOME/.config/sketchybar/colors.sh"

# Two queries, deliberately. window-* variables error with "No window is
# focused" on an empty workspace, and a combined query would poison the whole
# read — monitor-is-main would parse as "is focused" and report 'secondary'.
# monitor-* is monitor-scoped and always resolves.
is_main=$(aerospace echo -- '%{monitor-is-main}' 2>/dev/null)

if win=$(aerospace echo -- '%{window-layout} %{window-is-fullscreen}' 2>/dev/null); then
  read -r layout fullscreen <<<"$win"
else
  layout=""; fullscreen=""
fi

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
