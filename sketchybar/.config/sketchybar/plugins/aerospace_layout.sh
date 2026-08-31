#!/bin/bash
# AeroSpace layout + which monitor is focused.
#
# Writes two bar items, `layout` and `monitor`, from one aerospace call.
# Triggered by aerospace_layout_change — nothing polls.

source "$HOME/.config/sketchybar/colors.sh"

# An aerospace call costs ~21ms in process spawn and socket round trip almost
# regardless of what it asks for, so `aerospace eval` batches both queries over
# one connection instead of paying that twice.
#
# They stay two queries rather than one format string: window-* variables are
# absent on an empty workspace, and a combined format would then shift
# monitor-is-main into the layout field. The 'M'/'W' tags keep them apart, and
# a failing sub-command inside eval does not abort the ones after it — on an
# empty workspace the W line is simply missing.
#
# `list-monitors --count` is folded into the same eval call rather than a
# separate `aerospace` invocation, so hiding the monitor item on a single-
# display setup costs nothing extra (no --format support alongside --count,
# so it comes back as a bare number with no tag; the case fallback below
# recognizes it by shape instead).
#
# The eval expression must stay on one line; embedded newlines fail to parse.
state=$(aerospace eval -- 'list-monitors --focused --format M%{tab}%{monitor-is-main}%{tab}%{monitor-id} ; list-windows --focused --format W%{tab}%{window-layout}%{tab}%{window-is-fullscreen} ; list-monitors --count' 2>/dev/null)

is_main=""; mon_id=""; layout=""; fullscreen=""; monitor_count=""
while IFS=$'\t' read -r tag a b; do
  case "$tag" in
    M) is_main="$a"; mon_id="$b" ;;
    W) layout="$a"; fullscreen="$b" ;;
    ''|*[!0-9]*) ;;                 # neither tag — ignore
    *) monitor_count="$tag" ;;      # bare digit line from --count
  esac
done <<<"$state"

# ── layout ───────────────────────────────────────────────────────────────────

if [ "$fullscreen" = "true" ]; then
  icon="󰊓"; label="fullscreen"; color="$ORANGE"
else
  # AeroSpace's own layout name verbatim, h_/v_ direction prefix included, so
  # the bar matches what `aerospace` reports and a new layout needs no mapping.
  label="${layout:-—}"
  case "$layout" in
    floating)     icon="󰀽"; color="$AQUA"  ;;
    h_tiles)      icon="󰯌"; color="$GREEN" ;;
    v_tiles)      icon="󰯋"; color="$GREEN" ;;
    h_accordion)  icon="󰹴"; color="$BLUE"  ;;
    v_accordion)  icon="󰹺"; color="$BLUE"  ;;
    *)            icon="󰋱"; color="$GRAY"  ;;
  esac
fi

# ── monitor ──────────────────────────────────────────────────────────────────

# AeroSpace's own monitor id, so the indicator maps onto what its commands take
# (`move-workspace-to-monitor 2`). 'main'/'secondary' could not tell two
# non-main displays apart. Colour still marks the main display at a glance.
mon_label="${mon_id:+monitor_$mon_id}"
mon_label="${mon_label:-—}"

if [ "$is_main" = "true" ] || [ -z "$mon_id" ]; then
  mon_color="$GRAY"
else
  mon_color="$PURPLE"
fi

# Nothing to indicate on a single-display setup — hide the item rather than
# show a monitor pill that can never read anything but "monitor_1". A failed
# or unparseable count defaults to "on" so a query hiccup can't wedge it
# hidden.
if [ "${monitor_count:-2}" -le 1 ]; then
  mon_drawing=off
else
  mon_drawing=on
fi

# background is set on every run so a stray write can't leave it stuck.
sketchybar \
  --set "$NAME" icon="$icon" icon.color="$color" \
                label="$label" label.color="$color" \
                background.color="$BG_DIM" \
  --set monitor  drawing="$mon_drawing" \
                icon="󰍹" icon.color="$mon_color" \
                label="$mon_label" label.color="$mon_color" \
                background.color="$BG_DIM"
