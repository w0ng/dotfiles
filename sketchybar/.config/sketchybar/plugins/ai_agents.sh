#!/bin/bash
# AI agent counters: a robot, then one count per state, each hidden at zero and
# the whole group hidden when no agent is running.
#
# working, blocked, done and idle are exactly what herdr reports, so this only
# ever reads the file helpers/ai_watch.py writes. Nothing here is derived, and
# the plugin holds no state between repaints.

source "$HOME/.config/sketchybar/colors.sh"

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar/ai_agents"

# nf-fa-robot. Every glyph here was checked against MapleMono-NF-CN's character
# map, because one the font lacks falls back to a system face in silence.
AI_ICON=""

total=0
working=0
blocked=0
finished=0
idle=0

if [ -r "$STATE_FILE" ]; then
  # `|| [ -n "$key" ]` so a final line with no trailing newline is still read
  # rather than silently dropping whichever count happens to be last.
  while IFS='=' read -r key value || [ -n "$key" ]; do
    case "$key" in
      total) total="$value" ;;
      working) working="$value" ;;
      blocked) blocked="$value" ;;
      done) finished="$value" ;;
      idle) idle="$value" ;;
    esac
  done <"$STATE_FILE"
fi

# Anything non-numeric reads as zero, because `[ abc -le 0 ]` errors and returns
# false, which would fall through to the drawing block below and paint a robot
# with nothing beside it.
numeric() {
  case "$1" in
    '' | *[!0-9]*) printf '0' ;;
    *) printf '%s' "$1" ;;
  esac
}

# A missing or unreadable file leaves every count at zero, which hides the group.
if [ "$(numeric "$total")" -le 0 ]; then
  sketchybar \
    --set ai.icon drawing=off \
    --set ai.working drawing=off \
    --set ai.blocked drawing=off \
    --set ai.done drawing=off \
    --set ai.idle drawing=off
  exit 0
fi

# Glyph as well as colour, because four counts sitting side by side are told
# apart faster by shape. All four come from one family, chat_processing,
# chat_question, chat_plus and chat_sleep, so they read as a set rather than as
# four unrelated symbols.
#
# done is herdr's own state for a turn that finished and has not been looked at
# yet. Green draws the eye to it, against a dim idle that does not need one.
states=('working' 'blocked' 'done' 'idle')
counts=("$working" "$blocked" "$finished" "$idle")
glyphs=(󰭻 󱜸 󱐏 󱋑)
colors=("$BLUE" "$RED" "$GREEN" "$DIM")

args=(--set ai.icon drawing=on icon="$AI_ICON" icon.color="$PURPLE")

for i in "${!states[@]}"; do
  count="$(numeric "${counts[$i]}")"
  if [ "$count" -gt 0 ]; then
    args+=(
      --set "ai.${states[$i]}" drawing=on
      icon="${glyphs[$i]}" icon.color="${colors[$i]}"
      label="$count" label.color="${colors[$i]}"
    )
  else
    args+=(--set "ai.${states[$i]}" drawing=off)
  fi
done

sketchybar "${args[@]}"
