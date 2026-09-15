#!/usr/bin/env bash
# AI agent counters: a robot, then one count per state, each hidden at zero and
# the whole group hidden when no agent is running.
#
# working, blocked, done and idle are exactly what herdr reports, so nothing
# here is derived beyond the total. They come from helpers/ai_watch.py, which
# watches the herdr running beside this bar, plus every file in ai_agents.d,
# where anything watching a herdr this machine cannot reach drops what it sees.
# All of them are added together, so the bar shows one total rather than one
# group per herd. README.md states what a contributor has to write.

# shellcheck source-path=SCRIPTDIR source=../colors.sh
source "${HOME}/.config/sketchybar/colors.sh"

STATE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/sketchybar"
STATE_FILE="${STATE_DIR}/ai_agents"
CONTRIB_DIR="${STATE_DIR}/ai_agents.d"

# Past this, whatever was writing a contributor file has stopped and its agents
# are gone with it. Only a repaint notices the expiry, so ai_driver carries an
# update_freq tied to this number.
CONTRIB_MAX_AGE=60

# nf-fa-robot. Every glyph here was checked against MapleMono-NF-CN's character
# map, because one the font lacks falls back to a system face in silence.
AI_ICON=""

working=0
blocked=0
finished=0
idle=0

add_counts() {
  [[ -f "$1" && -r "$1" ]] || return 0
  local key value
  # Last wins within a file, so a writer that appends rather than truncates
  # does not report its old counts on top of its new ones. Only the totals
  # across files add.
  local w=0 b=0 f=0 i=0
  # `|| [[ -n "${key}" ]]` so a final line with no trailing newline is still
  # read rather than silently dropping whichever count happens to be last.
  while IFS='=' read -r key value || [[ -n "${key}" ]]; do
    # A stray carriage return or a space around the `=` would otherwise land in
    # the key, match no arm below, and drop that count in silence.
    key="${key//[[:space:]]/}"
    value="${value//[[:space:]]/}"
    # Digits only, because `$(( ))` does more than arithmetic. It dereferences
    # a bare word, so `working=idle` would add this reading's idle count
    # instead, and it expands an array subscript, so `working=x[$(cmd)]` runs
    # cmd. These files are written by tooling this repo does not own.
    #
    # Six digits or more reads as zero for the same reason: 10# on twenty of
    # them wraps through signed 64-bit and draws the wrap as the label, and a
    # value chosen to wrap the sum negative hides the group while agents run.
    case "${value}" in
      '' | *[!0-9]* | ??????*) value=0 ;;
      # 10# so a leading zero stays a digit rather than reading as octal, which
      # fails outright on an 8 or a 9.
      *) value=$((10#${value})) ;;
    esac
    case "${key}" in
      working) w="${value}" ;;
      blocked) b="${value}" ;;
      done) f="${value}" ;;
      idle) i="${value}" ;;
    esac
  done <"$1"
  working=$((working + w))
  blocked=$((blocked + b))
  finished=$((finished + f))
  idle=$((idle + i))
}

add_counts "${STATE_FILE}"

# Globbed before the guard, so the usual case of no contributors forks nothing
# even once the directory itself exists. The writer is on this machine, so the
# mtime and `date` below read the same clock.
#
# `*` skips a leading dot, which is how a contributor's half-written temp file
# stays out of the counts.
contributors=("${CONTRIB_DIR}"/*)
if [[ -e "${contributors[0]}" ]]; then
  now="$(date +%s)"
  for contributor in "${contributors[@]}"; do
    [[ -f "${contributor}" ]] || continue
    mtime="$(stat -f %m "${contributor}" 2>/dev/null)" || continue
    age=$((now - mtime))
    # A negative age is a clock that stepped back, or a file copied from a host
    # running ahead. Without the lower bound it never expires, so it counts on
    # forever after the writer that left it has died.
    ((age >= 0 && age <= CONTRIB_MAX_AGE)) || continue
    add_counts "${contributor}"
  done
fi

# Nothing draws the total. It only decides whether the group appears, and
# deriving it means a contributor can neither hide a live herd by leaving its
# own total out nor draw a bare robot by overstating one.
total=$((working + blocked + finished + idle))

# A missing or unreadable file leaves every count at zero, which hides the group.
if [[ "${total}" -le 0 ]]; then
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
counts=("${working}" "${blocked}" "${finished}" "${idle}")
glyphs=(󰭻 󱜸 󱐏 󱋑)
colors=("${BLUE}" "${RED}" "${GREEN}" "${DIM}")

args=(--set ai.icon drawing=on icon="${AI_ICON}" icon.color="${PURPLE}")

for i in "${!states[@]}"; do
  count="${counts[${i}]}"
  if [[ "${count}" -gt 0 ]]; then
    args+=(
      --set "ai.${states[${i}]}" drawing=on
      icon="${glyphs[${i}]}" icon.color="${colors[${i}]}"
      label="${count}" label.color="${colors[${i}]}"
    )
  else
    args+=(--set "ai.${states[${i}]}" drawing=off)
  fi
done

sketchybar "${args[@]}"
