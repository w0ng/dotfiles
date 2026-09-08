#!/usr/bin/env zsh
#
# Claude Code status line: limits on top, consumption below.
#
#   󰄉 5h █░░░░░ 24% 󰑐 2h14m  ·  󰄉 7d ██░░░░ 41%  ·  󰍛 ███░░░░░░░ 34% 68k/200k
#   󰚩 Opus 5  xhigh  󰧑  ·  󰄔 $1.23 󰈸 $0.98/h  󰃭 $3.10  ·  󰆼 97%  ·  󰥔 1h15m
#
# Carries no navigation -- no cwd, branch, worktree or PR. The zsh prompt
# already answers "where am I" on every prompt, so this answers only "what is
# this costing", and the space that bought goes to the numbers.
#
# This runs on every assistant message, so the whole render is one fork: jq.
# The cost ledger is summed with integer arithmetic rather than awk, and the
# helpers hand results back in $REPLY because $(...) around a function forks too.
#
# Colours are palette indices 0-15, not hex, so the line follows whatever theme
# the terminal is wearing.

emulate -L zsh
setopt no_unset
zmodload zsh/datetime 2>/dev/null

local -r JQ=${commands[jq]:-/opt/homebrew/bin/jq}
[[ -x $JQ ]] || { print -r -- 'statusline: jq not found'; exit 0 }

local -i now=${EPOCHSECONDS:-0}
(( now )) || now=$(date +%s)

# Segments shed by priority as the pane narrows. Thresholds are measured, not
# guessed: the widest line renders 81 columns at full, 63 at mid and 45 at min,
# so each tier is set just above what it actually produces. Re-measure these if
# the segments change -- a tier that overflows its own threshold is invisible
# until a narrow pane wraps.
#
# An undetected width falls back to full rather than minimal: the wide monitor is
# the common case, and wrapping is a smaller loss than hiding data that fits.
local -i cols=${COLUMNS:-0}
local tier=full
if   (( cols > 0 && cols < 64 )); then tier=min
elif (( cols > 0 && cols < 82 )); then tier=mid
fi
local -i wide=0 mid=0
[[ $tier == full ]] && wide=1
[[ $tier != min  ]] && mid=1

#######################################
# Presentation helpers
#######################################

local -r RS=$'\033[0m'       BD=$'\033[1m'
local -r RED=$'\033[38;5;1m' GRN=$'\033[38;5;2m' YLW=$'\033[38;5;3m'
local -r BLU=$'\033[38;5;4m' MAG=$'\033[38;5;5m' CYN=$'\033[38;5;6m'
# The secondary grey is the one colour here that is not a palette index.
# Index 8 renders dark-on-dark, because ghostty/.config/ghostty/config overrides
# it to #3c3836, a gruvbox *background* shade; index 7 (#a89984) is too light to
# recede. Nothing sits between them, so this pins gruvbox's own comment grey in
# truecolor -- bg4, chosen by eye against the real line. It sits below the 4.5:1
# contrast guideline deliberately: these are labels and separators meant to
# recede. It is the one value to revisit if the terminal theme ever changes.
local -r FG=$'\033[38;5;15m' DIM=$'\033[38;2;124;111;100m'
local -r SEP="${DIM}  ·  ${RS}"

# Every icon keeps a space on both sides, standalone ones included, which is why
# the identity group below joins on two spaces rather than one.
#
# One glyph needs the room more than the rest: U+21BB is absent from Maple Mono
# NF, so macOS substitutes it from a fallback font whose metrics do not match,
# and it crowds whatever follows. Verified with:
#   fc-query --format='%{charset}' ~/Library/Fonts/MapleMono-NF-CN-Medium.ttf

# Colour a percentage by how alarming it is.
heat() {
  local -i p=$1
  if   (( p >= 90 )); then REPLY=$RED
  elif (( p >= 75 )); then REPLY=$YLW
  else                     REPLY=$GRN
  fi
}

bar() {
  local -i pct=$1 width=$2 filled
  (( pct < 0   )) && pct=0
  (( pct > 100 )) && pct=100
  (( filled = (pct * width + 50) / 100 ))
  REPLY=''
  repeat $filled REPLY+='█'
  repeat $(( width - filled )) REPLY+='░'
}

human_tokens() {
  local -i t=$1
  if   (( t >= 1000000 )); then printf -v REPLY '%d.%dM' $(( t / 1000000 )) $(( (t % 1000000) / 100000 ))
  elif (( t >= 1000    )); then printf -v REPLY '%dk' $(( t / 1000 ))
  else                          REPLY=$t
  fi
}

human_span() {
  local -i s=$1
  if   (( s <= 0     )); then REPLY='now'
  elif (( s < 60     )); then printf -v REPLY '%ds' $s
  elif (( s < 3600   )); then printf -v REPLY '%dm' $(( s / 60 ))
  elif (( s < 86400  )); then printf -v REPLY '%dh%02dm' $(( s / 3600 )) $(( (s % 3600) / 60 ))
  else                        printf -v REPLY '%dd %dh' $(( s / 86400 )) $(( (s % 86400) / 3600 ))
  fi
}

# Costs are carried as integer micro-dollars end to end, so totals can be
# summed and formatted without ever needing floating point in the shell.
human_cost() {
  local -i u=$1
  printf -v REPLY '$%d.%02d' $(( u / 1000000 )) $(( (u % 1000000) / 10000 ))
}

#######################################
# Session data
#######################################

local payload; payload="$(</dev/stdin)"

# One jq pass emits every field as a fixed-position line. Absent values become
# empty or -1 so the field count never shifts, and "end" anchors the list
# because command substitution eats trailing blank lines.
local raw
raw="$(print -r -- "$payload" | "$JQ" -r '
  def num: if . == null then 0 else . end;
  def flag: if . then "1" else "" end;
  [ (.model.display_name // "Claude")
  , (.effort.level // "")
  , (.thinking.enabled | flag)
  , (.fast_mode | flag)
  , ((.context_window.used_percentage | num | round) | tostring)
  , ((.context_window.total_input_tokens | num) | tostring)
  , ((.context_window.context_window_size // 200000) | tostring)
  , ((.cost.total_cost_usd | num) * 1000000 | round | tostring)
  , ((.cost.total_duration_ms | num | round) | tostring)
  , ((.rate_limits.five_hour.used_percentage // -1) | round | tostring)
  , ((.rate_limits.five_hour.resets_at // 0) | tostring)
  , ((.rate_limits.seven_day.used_percentage // -1) | round | tostring)
  , ((.rate_limits.seven_day.resets_at // 0) | tostring)
  , ((.rate_limits.spend_limit.used_percentage // -1) | round | tostring)
  , ((.rate_limits.spend_limit.resets_at // 0) | tostring)
  , ((.prompt_cache.hit_ratio // -0.01) * 100 | round | tostring)
  , ((.context_window.current_usage.input_tokens | num) | tostring)
  , ((.context_window.current_usage.cache_creation_input_tokens | num) | tostring)
  , ((.context_window.current_usage.cache_read_input_tokens | num) | tostring)
  , (.session_id // "")
  , "end"
  ] | join("\n")' 2>/dev/null)"

[[ -n $raw ]] || exit 0
local -a F; F=("${(@f)raw}")
(( ${#F} >= 21 )) || exit 0

local    model=$F[1] effort=$F[2] thinking=$F[3] fastmode=$F[4]
local -i ctx_pct=$F[5] ctx_tok=$F[6] ctx_max=$F[7]
local -i cost_u=$F[8] dur_ms=$F[9]
local -i rl5=$F[10] rl5_at=$F[11] rl7=$F[12] rl7_at=$F[13]
local -i spend=$F[14] spend_at=$F[15] pc_hit=$F[16]
local -i cu_in=$F[17] cu_write=$F[18] cu_read=$F[19]
local    session=$F[20]
local REPLY=''

#######################################
# Cross-session daily cost ledger
#######################################

# cost.total_cost_usd only covers the current session, but the number worth
# watching is what the day has cost across all of them. It renders even when it
# equals the session total -- a segment that silently vanishes on single-session
# days reads as a bug, and a stable position is worth one redundant figure. Each session drops its
# running total in a file named after itself, bucketed by date; today's spend is
# the sum of that directory.
#
# A session running past midnight carries its whole total into the new day's
# bucket rather than splitting at the boundary -- close enough for a status
# line, and it keeps the write to one file with no bookkeeping.
local -i today_u=0
local ledger=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
if [[ -n $session ]]; then
  local today; strftime -s today '%Y-%m-%d' $now 2>/dev/null || today=$(date +%F)
  local bucket=$ledger/$today

  if [[ ! -d $bucket ]]; then
    mkdir -p $bucket 2>/dev/null
    # Buckets are named by date, so a descending name sort is newest-first and
    # trimming to the last week is a slice -- no date arithmetic required.
    local -a old; old=($ledger/*(N/On))
    (( ${#old} > 7 )) && rm -rf -- "${(@)old[8,-1]}" 2>/dev/null
  fi

  (( cost_u > 0 )) && print -r -- $cost_u > $bucket/$session 2>/dev/null
  local f v
  for f in $bucket/*(N.); do
    read -r v < $f 2>/dev/null || continue
    [[ $v == <-> ]] && (( today_u += v ))
  done
fi

#######################################
# Line 1 -- the limits
#######################################

local -a lim
if (( rl5 >= 0 )); then
  local l5col; heat $rl5; l5col=$REPLY
  local out="${DIM}󰄉 5h${RS} "
  (( wide )) && { bar $rl5 6; out+="${l5col}${REPLY} " }
  out+="${l5col}${rl5}%${RS}"
  if (( mid && rl5_at > now )); then
    human_span $(( rl5_at - now ))
    out+="${DIM} 󰑐 ${REPLY}${RS}"
  fi
  lim+=("$out")
fi
if (( rl7 >= 0 )); then
  local l7col; heat $rl7; l7col=$REPLY
  local out7="${DIM}󰄉 7d${RS} "
  (( wide )) && { bar $rl7 6; out7+="${l7col}${REPLY} " }
  out7+="${l7col}${rl7}%${RS}"
  lim+=("$out7")
fi
if (( mid && spend >= 0 )); then
  local spcol; heat $spend; spcol=$REPLY
  local outs="${DIM}󰄉 spend${RS} "
  (( wide )) && { bar $spend 6; outs+="${spcol}${REPLY} " }
  outs+="${spcol}${spend}%${RS}"
  lim+=("$outs")
fi

local ctx_col
# Deliberately not using exceeds_200k_tokens to force red here. It is a fixed
# 200k threshold regardless of the model's real context window, so on a 1M-window
# model it latches on at ~20% used and never clears. It also counts input + cache
# + output, while used_percentage counts input only -- so it would be recolouring
# a number it does not actually measure.
heat $ctx_pct; ctx_col=$REPLY
bar $ctx_pct 10
local ctx="${ctx_col}󰍛 ${REPLY} ${ctx_pct}%${RS}"
if (( mid )); then
  human_tokens $ctx_tok
  ctx+=" ${DIM}${REPLY}"
  if (( wide )); then
    human_tokens $ctx_max
    ctx+="/${REPLY}"
  fi
  ctx+="${RS}"
fi
lim+=("$ctx")
print -r -- "${(j:  ·  :)lim}"

#######################################
# Line 2 -- what it is costing
#######################################

local -a seg
seg=("${MAG}󰚩 ${BD}${model}${RS}")
(( mid )) && [[ -n $effort ]] && seg+=("${DIM}${effort}${RS}")
if (( wide )); then
  [[ -n $thinking ]] && seg+=("${BLU}󰧑${RS}")
  [[ -n $fastmode ]] && seg+=("${YLW}󱐋${RS}")
fi
local line2="${(j:  :)seg}"

human_cost $cost_u
line2+="${SEP}${CYN}󰄔 ${REPLY}${RS}"

# Spend velocity, which predicts hitting a limit better than the total does.
# Suppressed for the first minute, when a tiny elapsed time makes the
# extrapolation meaningless.
if (( mid && dur_ms > 60000 && cost_u > 0 )); then
  human_cost $(( cost_u * 3600000 / dur_ms ))
  line2+=" ${DIM}󰈸 ${REPLY}/h${RS}"
fi

if (( mid && today_u > 0 )); then
  human_cost $today_u
  line2+="  ${DIM}󰃭 ${REPLY}${RS}"
fi

# prompt_cache is the session-wide figure but needs Claude Code 2.1.251+; below
# that, derive the last call's hit rate from current_usage, which has carried the
# same counters for far longer. The token floor keeps the first call of a session
# -- nothing cached yet, so 0% by definition -- from reading as a failure.
local -i hit=-1
if   (( pc_hit >= 0 )); then hit=$pc_hit
elif (( cu_in + cu_write + cu_read >= 20000 )); then
  (( hit = cu_read * 100 / (cu_in + cu_write + cu_read) ))
fi
if (( mid && hit >= 0 )); then
  local hitcol=$GRN
  (( hit < 70 )) && hitcol=$YLW
  (( hit < 40 )) && hitcol=$RED
  line2+="${SEP}${hitcol}󰆼 ${hit}%${RS}"
fi

if (( wide )); then
  human_span $(( dur_ms / 1000 ))
  line2+="${SEP}${FG}󰥔 ${REPLY}${RS}"
fi

print -r -- "$line2"
exit 0
