#!/bin/bash
# Every AeroSpace-derived bar item, painted from one query: layout, monitor,
# mode and the ten workspace pills.
#
# One script rather than one per item because an `aerospace` call costs ~17ms in
# process spawn and socket round trip almost regardless of what it asks for, so
# six queries cost no more than two. A workspace switch fires both
# exec-on-workspace-change and on-focus-changed, so this runs twice either way.
# Merging the queries halves what each of those two runs costs.
#
# front_app is deliberately not here. It reads sketchybar's own $INFO and
# reaches AeroSpace only when that is absent, so folding it in would put a query
# and a full repaint on the most frequent event the bar sees.

source "$HOME/.config/sketchybar/colors.sh"

# The eval expression must stay on one line; embedded newlines fail to parse.
#
# Each sub-command carries a tag, so one that returns nothing cannot shift
# another's fields into the wrong variable. window-* is absent on an empty
# workspace, and a failing sub-command inside eval does not abort the ones after
# it. `list-monitors --count` and `list-modes --current` take no --format, so
# they arrive untagged, and the loop below tells those two apart by shape.
state=$(aerospace eval -- 'list-monitors --focused --format M%{tab}%{monitor-is-main}%{tab}%{monitor-id} ; list-windows --focused --format W%{tab}%{window-layout}%{tab}%{window-is-fullscreen} ; list-workspaces --monitor all --format A%{tab}%{workspace}%{tab}%{workspace-is-visible}%{tab}%{workspace-is-focused} ; list-workspaces --monitor all --empty no --format N%{tab}%{workspace} ; list-monitors --count ; list-modes --current' 2>/dev/null)

# Nothing came back, so leave every item at its last paint rather than blanking
# the whole bar. An AeroSpace restart is the common cause and it is brief.
[ -z "$state" ] && exit 0

is_main=""
mon_id=""
layout=""
fullscreen=""
monitor_count=""
mode=""
nonempty=" "
# Parallel arrays rather than one array of tab-joined rows, because re-splitting
# a row needs a herestring, and bash backs every herestring with a temp file.
# Ten of those per repaint measured ~1.7ms, more than the extra queries cost.
ws_ids=()
ws_visible=()
ws_focused=()

while IFS=$'\t' read -r tag a b c; do
  # A tagged line always carries fields and the two untagged queries never do,
  # so the presence of $a is what tells them apart. Matching the tag first would
  # let a mode named M, W, A or N take a tag's arm and clobber a real line.
  if [ -z "$a" ]; then
    case "$tag" in
      '') ;;
      *[!0-9]*) mode="$tag" ;;
      *) monitor_count="$tag" ;;
    esac
    continue
  fi
  case "$tag" in
    M)
      is_main="$a"
      mon_id="$b"
      ;;
    W)
      layout="$a"
      fullscreen="$b"
      ;;
    A)
      ws_ids+=("$a")
      ws_visible+=("$b")
      ws_focused+=("$c")
      ;;
    N) nonempty="$nonempty$a " ;;
  esac
done <<<"$state"

# ── layout ───────────────────────────────────────────────────────────────────

if [ "$fullscreen" = "true" ]; then
  icon="󰊓"
  label="fullscreen"
  color="$ORANGE"
else
  # AeroSpace's own layout name verbatim, h_/v_ direction prefix included, so
  # the bar matches what `aerospace` reports and a new layout needs no mapping.
  label="${layout:-—}"
  case "$layout" in
    floating)
      icon="󰀽"
      color="$AQUA"
      ;;
    h_tiles)
      icon="󰯌"
      color="$GREEN"
      ;;
    v_tiles)
      icon="󰯋"
      color="$GREEN"
      ;;
    h_accordion)
      icon="󰹴"
      color="$BLUE"
      ;;
    v_accordion)
      icon="󰹺"
      color="$BLUE"
      ;;
    *)
      icon="󰋱"
      color="$GRAY"
      ;;
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

# Nothing to indicate on a single-display setup, so hide the item rather than
# show a monitor pill that can never read anything but "monitor_1". A failed
# or unparseable count defaults to "on" so a query hiccup cannot leave it stuck
# hidden.
if [ "${monitor_count:-2}" -le 1 ]; then
  mon_drawing=off
else
  mon_drawing=on
fi

# ── argv ─────────────────────────────────────────────────────────────────────

# One chained --set for every item, so the whole repaint is a single sketchybar
# process however many items it touches.
#
# Every item gets background.color on every run, so a stray write elsewhere
# cannot leave one stuck.
args=(
  --set layout icon="$icon" icon.color="$color"
  label="$label" label.color="$color"
  background.color="$BAR"
  --set monitor drawing="$mon_drawing"
  icon="󰍹" icon.color="$mon_color"
  label="$mon_label" label.color="$mon_color"
  background.color="$BAR"
)

# Hidden entirely in 'main' so the bar stays uncluttered; only a non-default
# binding mode is worth the space.
if [ -z "$mode" ] || [ "$mode" = "main" ]; then
  args+=(--set mode drawing=off)
else
  args+=(
    --set mode drawing=on
    label="$(printf '%s' "$mode" | tr '[:lower:]' '[:upper:]')"
    label.color="$BG0"
    background.color="$RED"
    background.drawing=on
  )
fi

# A pill is focused, visible on another monitor, holding windows, or empty. The
# focused workspace is also visible, so that branch has to be tested first.
for i in "${!ws_ids[@]}"; do
  ws="${ws_ids[$i]}"
  if [ "${ws_focused[$i]}" = "true" ]; then
    bg="$YELLOW"
    fg="$BG0"
  elif [ "${ws_visible[$i]}" = "true" ]; then
    bg="$GRAY_DARK"
    fg="$FG"
  elif [[ "$nonempty" == *" $ws "* ]]; then
    bg="$BAR"
    fg="$FG"
  else
    bg="$BAR"
    fg="$DIM"
  fi
  args+=(--set "space.$ws" background.drawing=on background.color="$bg" label.color="$fg")
done

sketchybar "${args[@]}"
