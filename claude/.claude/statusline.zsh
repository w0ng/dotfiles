#!/usr/bin/env zsh
#
# Claude Code status line: one line, assembled to fit the pane.
#
# Parts are offered to the line in priority order and each is taken only if it
# still fits, so the line adapts to any width. Display order is fixed and
# independent of priority, so a part never moves. It only appears or
# disappears. Nothing is ever truncated mid-value, and the line never wraps to a
# second row.
#
# In a 124-column pane it takes 107 of them, every part on:
#     34% 68k/200k 󰆼 52m 󱑃  24% 󰑐 2h14m 󰨳  41% 󰑐 4d 12h 󱎫 1h15m 󰄔 $1.23  󰃭 $6.05
#
# In 48 it takes 45 and sheds the reset spans, the window size and both bars:
#    34% 68k 󰆼 52m 󱑃 24% 󰨳 41% 󱎫 1h15m
#
# The order is the context and the cache clock first, then the two rate limits,
# then how long the session has run and what it has cost. Display order matches
# priority, so the two read first are also the two that survive the narrowest
# pane. Detail within a part, such as a bar or a reset span, is worth less than
# the existence of the next part, so every core lands before any detail.
#
# There is deliberately no model, effort or thinking indicator: all three read
# the same on every session here, so they spend columns on nothing that changes.
# Add them back the day the model starts varying.
#
# Carries no navigation, so no cwd, branch, worktree or PR. The zsh prompt
# already reports where you are, so this reports only what the session costs,
# and the space that frees up goes to the numbers.
#
# This runs on every assistant message, so the whole render is one fork: jq.
# The cost ledger is summed with integer arithmetic rather than awk, and the
# helpers hand results back in $REPLY because $(...) around a function forks too.
#
# Colours are palette indices 0-15, not hex, so the line follows whatever theme
# the terminal has set.

emulate -L zsh
setopt no_unset
zmodload zsh/datetime 2>/dev/null

local -r JQ=${commands[jq]:-/opt/homebrew/bin/jq}
[[ -x $JQ ]] || { print -r -- 'statusline: jq not found'; exit 0 }

local -i now=${EPOCHSECONDS:-0}
(( now )) || now=$(date +%s)

# An undetected width falls back to a wide-but-not-widest budget. Claude Code
# does export COLUMNS, so this only covers running the script by hand, and a
# line that wraps costs more than a part that stays hidden.
local -i budget=${COLUMNS:-0}
(( budget > 0 )) || budget=120
# Keep a column in hand rather than filling the pane exactly: whether the host
# pads the line or reserves the last cell is not knowable from in here, and
# guessing wrong costs a second row, which this script never uses.
(( budget > 1 )) && budget=$(( budget - 1 ))

# Anthropic's prompt cache is refreshed by every call and expires this long after
# the last one. The TTL is not discoverable: a captured payload carries
# current_usage as four scalars, with no ephemeral-bucket split and no
# cache_control anywhere, so there is nothing to read it from. Claude Code takes
# the 1-hour cache on this plan, which is the only reason 3600 is right here. A
# session dropped to the 5-minute cache under usage overage is dropped silently,
# and the countdown then reads twelve times longer than the truth.
#
# The override is validated rather than trusted: an integer-typed local under
# no_unset aborts the whole script on a non-numeric value, which would replace
# the status line with a shell error.
local -i CACHE_TTL=3600
[[ ${CLAUDE_STATUSLINE_CACHE_TTL:-} == <-> ]] && \
  (( CLAUDE_STATUSLINE_CACHE_TTL > 0 )) && CACHE_TTL=$CLAUDE_STATUSLINE_CACHE_TTL
typeset -r CACHE_TTL

#######################################
# Presentation helpers
#######################################

local -r RS=$'\033[0m'
local -r RED=$'\033[38;5;1m' GRN=$'\033[38;5;2m' YLW=$'\033[38;5;3m'
local -r CYN=$'\033[38;5;6m'
# The secondary grey is the one colour here that is not a palette index.
# Index 8 renders dark-on-dark, because ghostty/.config/ghostty/config overrides
# it to #3c3836, a gruvbox *background* shade; index 7 (#a89984) is too light to
# recede. Nothing sits between them, so this pins gruvbox's own comment grey in
# truecolor: bg4, chosen by eye against the real line. It sits below the 4.5:1
# contrast guideline deliberately, because these are labels and separators meant
# to recede. It is the one value to revisit if the terminal theme ever changes.
local -r FG=$'\033[38;5;15m' DIM=$'\033[38;2;124;111;100m'

# Each group is drawn as a pill. ghostty/.config/ghostty/config pins palette 0 to
# gruvbox bg0_h #1d2021 and palette 8 to #3c3836, a shade under and a shade over
# the #282828 ground; 0 is the one to keep, because it recedes and lets the pill
# group the values without competing with them, where 8 reads as a highlight and
# washes the dim text out. Inside a pill the background has to survive, so tokens
# end with FR, a foreground-only reset, and never the full RS.
local -ri PILL_IDX=0
local -r FR=$'\033[39m'
local -r PILL=$'\033[48;5;'"${PILL_IDX}m"
local -r CAPC=$'\033[49m'$'\033[38;5;'"${PILL_IDX}m"
local -r CAP_L=$'\ue0b6' CAP_R=$'\ue0b4'
# Two columns of cap per group, and one of gap between them. Cap-to-cap with no
# gap reads as one run of scalloped edges rather than as separate pills.
local -ri CAPW=2 GAPW=1

# Nerd Fonts powerline caps: half-circles drawn in the pill's own colour against
# the terminal ground, which is what rounds the ends.
pill() {
  REPLY="${CAPC}${CAP_L}${PILL}${1}${CAPC}${CAP_R}${RS}"
}

# A group opens with its icon and one space, which is why every width below is
# 2 + the length of the value. Where a group carries a second figure it joins on
# two spaces, so that one costs 4 + its length.

# Colour a percentage by how alarming it is.
heat() {
  local -i p=$1
  if   (( p >= 90 )); then REPLY=$RED
  elif (( p >= 75 )); then REPLY=$YLW
  else                     REPLY=$GRN
  fi
}

# A bar restates a number already beside it, so it buys resolution with columns
# another part could use. These two widths are the whole budget for that, and the
# fit pass has to charge for them long before the render draws them: a bar costs
# its width plus the space that follows it.
local -ri CTX_BAR=8 LIM_BAR=5

# Nerd Fonts "progress" set (U+EE00 to U+EE05): an empty and a filled glyph for
# each of left cap, middle and right cap, so a bar draws as one rounded track
# rather than a row of separate blocks. Font-dependent, so a terminal font
# without these renders every bar as tofu.
bar() {
  local -i pct=$1 width=$2 filled i
  (( pct < 0   )) && pct=0
  (( pct > 100 )) && pct=100
  (( filled = (pct * width + 50) / 100 ))
  REPLY=''
  for (( i = 1; i <= width; i++ )); do
    if (( i == 1 )); then
      if (( i <= filled )); then REPLY+=''
      else                       REPLY+=''
      fi
    elif (( i == width )); then
      if (( i <= filled )); then REPLY+=''
      else                       REPLY+=''
      fi
    else
      if (( i <= filled )); then REPLY+=''
      else                       REPLY+=''
      fi
    fi
  done
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
  if   (( s <= 0     )); then REPLY='0s'
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
  [ ((.context_window.used_percentage | num | round) | tostring)
  , ((.context_window.total_input_tokens | num) | tostring)
  , ((.context_window.context_window_size // 200000) | tostring)
  , ((.cost.total_cost_usd | num) * 1000000 | round | tostring)
  , ((.cost.total_duration_ms | num | round) | tostring)
  , ((.rate_limits.five_hour.used_percentage // -1) | round | tostring)
  , ((.rate_limits.five_hour.resets_at // 0) | tostring)
  , ((.rate_limits.seven_day.used_percentage // -1) | round | tostring)
  , ((.rate_limits.seven_day.resets_at // 0) | tostring)
  , ((.context_window.current_usage.cache_read_input_tokens | num) | tostring)
  , (.session_id // "")
  , "end"
  ] | join("\n")' 2>/dev/null)"

[[ -n $raw ]] || exit 0
local -a F; F=("${(@f)raw}")
(( ${#F} >= 12 )) || exit 0

local -i ctx_pct=$F[1] ctx_tok=$F[2] ctx_max=$F[3]
local -i cost_u=$F[4] dur_ms=$F[5]
local -i rl5=$F[6] rl5_at=$F[7] rl7=$F[8] rl7_at=$F[9]
local -i cu_read=$F[10]
local    session=$F[11]
local REPLY=''

local ledger=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline

#######################################
# Cross-session daily cost ledger
#######################################

# cost.total_cost_usd only covers the current session, but the number worth
# watching is what the day has cost across all of them. Each session drops its
# running total in a file named after itself, bucketed by date; today's spend is
# the sum of that directory.
#
# A session running past midnight carries its whole total into the new day's
# bucket rather than splitting at the boundary, which is close enough for a
# status line, and it keeps the write to one file with no bookkeeping.
local -i today_u=0
if [[ -n $session ]]; then
  local today; strftime -s today '%Y-%m-%d' $now 2>/dev/null || today=$(date +%F)
  local bucket=$ledger/$today

  if [[ ! -d $bucket ]]; then
    mkdir -p $bucket 2>/dev/null
    # Buckets are named by date, so a descending name sort is newest-first and
    # trimming to the last week is a slice, with no date arithmetic required.
    # The leading digit keeps this off the cache clock's directory next door.
    local -a old; old=($ledger/[0-9]*(N/On))
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
# Cache clock
#######################################

# The useful number is not how much of the last call the cache covered, which
# sits near 100% all session and never prompts an action. It is how long is left
# before the entry expires and the whole context gets re-sent at write price. The payload carries no timestamp for the last call, so its own counters
# serve as one: they move when a call happens and stay put when this script is
# re-run by the 60s refresh. Recording when the signature last changed dates the
# cache entry; the TTL turns that into a countdown.
#
# A session that has sent nothing has no cache entry to count down, so the clock
# stays off rather than reporting a full TTL for an entry that does not exist.
# Nothing cached is the state most worth flagging, so it must not render green.
local -i cache_left=0 cache_pct=-1
if [[ -n $session ]] && (( ctx_tok > 0 )); then
  local cdir=$ledger/cache cfile=$ledger/cache/$session
  local sig="${ctx_tok}:${cost_u}:${cu_read}"
  local oldsig='' oldstamp=''
  local -i stamp=0
  [[ -r $cfile ]] && read -r oldsig oldstamp < $cfile 2>/dev/null
  [[ $oldstamp == <-> ]] && stamp=$oldstamp

  if [[ $oldsig != $sig ]] || (( stamp == 0 )); then
    stamp=$now
    [[ -d $cdir ]] || mkdir -p $cdir 2>/dev/null
    print -r -- "$sig $stamp" > $cfile 2>/dev/null
    # Sessions end without warning, so their clocks are swept on the way past.
    # This branch runs on every message, so the sweep is one glob and one rm to
    # keep the render at a single fork.
    local -a dead; dead=($cdir/*(N.mh+24))
    (( ${#dead} )) && rm -f -- "${(@)dead}" 2>/dev/null
  fi

  (( cache_left = CACHE_TTL - (now - stamp) ))
  (( cache_pct = cache_left > 0 ? cache_left * 100 / CACHE_TTL : 0 ))
fi

#######################################
# Values, then the widths they will occupy
#######################################

local p5='' p7='' span5='' span7=''
(( rl5 >= 0 )) && p5="${rl5}%"
(( rl7 >= 0 )) && p7="${rl7}%"
(( rl5 >= 0 && rl5_at > now )) && { human_span $(( rl5_at - now )); span5=$REPLY }
(( rl7 >= 0 && rl7_at > now )) && { human_span $(( rl7_at - now )); span7=$REPLY }

local ctxp="${ctx_pct}%"
human_tokens $ctx_tok; local ctok=$REPLY
human_tokens $ctx_max; local cwin=$REPLY
# "cold" rather than a zero, because the number read off a countdown is time
# remaining and there is none. The next call pays to write the cache again.
local cachev=''
if   (( cache_pct < 0    )); then cachev=''
elif (( cache_left <= 0  )); then cachev='cold'
else human_span $cache_left; cachev=$REPLY
fi
human_span $(( dur_ms / 1000 )); local dspan=$REPLY
human_cost $cost_u; local scost=$REPLY
local tcost=''; (( today_u > 0 )) && { human_cost $today_u; tcost=$REPLY }

# Widths are counted from the value strings rather than measured, because every
# glyph on this line, Nerd Fonts icons included, is exactly one column wide.
local -i w_lim5=0; [[ -n $p5 ]] && (( w_lim5 = 2 + ${#p5} ))
local -i w_lim7=0; [[ -n $p7 ]] && (( w_lim7 = 2 + ${#p7} ))
local -i w_ctx=$(( 2 + ${#ctxp} ))
local -i w_cache=0;  [[ -n $cachev ]] && (( w_cache  = 2 + ${#cachev} ))
local -i w_time=$(( 2 + ${#dspan} ))
local -i w_cost=$(( 2 + ${#scost} ))
local -i w_ctxtok=$(( 1 + ${#ctok} ))
local -i w_reset=0
[[ -n $span5 ]] && (( w_reset += 3 + ${#span5} ))
[[ -n $span7 ]] && (( w_reset += 3 + ${#span7} ))
local -i w_today=0;  [[ -n $tcost ]]  && (( w_today  = 4 + ${#tcost} ))
local -i w_ctxwin=$(( 1 + ${#cwin} ))
local -i w_ctxbar=$(( CTX_BAR + 1 ))
local -i w_barlim=0
[[ -n $p5 ]] && (( w_barlim += LIM_BAR + 1 ))
[[ -n $p7 ]] && (( w_barlim += LIM_BAR + 1 ))

#######################################
# Fit: offer each part in priority order, keep what still fits
#######################################

local -i used=0 stopped=0
local -i on_lim5=0 on_lim7=0 on_ctx=0 on_cache=0 on_time=0 on_cost=0
local -i on_ctxtok=0 on_reset=0 on_today=0 on_ctxwin=0 \
         on_ctxbar=0 on_barlim=0

# The first part that does not fit closes the ladder, rather than being skipped
# so a cheaper one behind it can squeeze in. Skipping reads as a bug from the
# outside: the line shows the cache clock but not the context it outranks, and
# then swaps the two back as the pane gains a single column. Stopping keeps what
# is on the line a strict prefix of the priority order, so widening a pane only
# ever adds. A part the payload does not carry has no width, costs nothing and
# does not close the ladder.
offer() {  # $1=width  $2=1 if this part opens a group
  local -i w=$1 cost
  (( stopped )) && return 1
  (( w > 0 )) || return 1
  (( cost = w + ( $2 == 1 ? CAPW + ( used > 0 ? GAPW : 0 ) : 0 ) ))
  if (( used + cost > budget )); then
    stopped=1
    return 1
  fi
  (( used += cost ))
  return 0
}

offer $w_ctx   1 && on_ctx=1
offer $w_cache 1 && on_cache=1
offer $w_lim5  1 && on_lim5=1
offer $w_lim7  1 && on_lim7=1
# Four columns for the tokens actually consumed, still inside the first group on
# the line, beat starting the next one.
(( on_ctx )) && offer $w_ctxtok 0 && on_ctxtok=1
offer $w_time  1 && on_time=1
offer $w_cost  1 && on_cost=1

# The reset spans are the costliest detail on the line, which is the only reason
# they sit behind two cores they would otherwise outrank.
(( on_lim5 || on_lim7 )) && offer $w_reset 0 && on_reset=1
(( on_cost )) && offer $w_today 0 && on_today=1
# The denominator is meaningless without the figure it divides.
(( on_ctxtok )) && offer $w_ctxwin 0 && on_ctxwin=1
(( on_ctx )) && offer $w_ctxbar 0 && on_ctxbar=1
(( on_lim5 || on_lim7 )) && offer $w_barlim 0 && on_barlim=1

#######################################
# Render
#######################################

local -a groups
local t

if (( on_ctx )); then
  # Deliberately not using exceeds_200k_tokens to force red here. It is a fixed
  # 200k threshold regardless of the model's real context window, so on a 1M-window
  # model it latches on at ~20% used and never clears. It also counts input + cache
  # + output, while used_percentage counts input only, so it would be recolouring
  # a number it does not actually measure.
  heat $ctx_pct; local cc=$REPLY
  t="${cc} "
  (( on_ctxbar )) && { bar $ctx_pct $CTX_BAR; t+="${cc}${REPLY} " }
  t+="${cc}${ctxp}${FR}"
  if (( on_ctxtok )); then
    t+=" ${DIM}${ctok}"
    (( on_ctxwin )) && t+="/${cwin}"
    t+="${FR}"
  fi
  groups+=("$t")
fi

# Warmth is what is left of the TTL, not how much of it has been spent, so the
# thresholds run the other way to heat(): half the window still on the clock is
# comfortable, a fifth is not, and expired is the state worth colouring loudest
# because the next call re-writes the whole context.
if (( on_cache )); then
  local kc=$GRN
  (( cache_pct < 50 )) && kc=$YLW
  (( cache_pct < 20 )) && kc=$RED
  groups+=("${kc}󰆼 ${cachev}${FR}")
fi

if (( on_lim5 )); then
  heat $rl5; local c5=$REPLY
  t="${c5}󱑃 "
  (( on_barlim )) && { bar $rl5 $LIM_BAR; t+="${c5}${REPLY} " }
  t+="${c5}${p5}${FR}"
  (( on_reset )) && [[ -n $span5 ]] && t+="${DIM} 󰑐 ${span5}${FR}"
  groups+=("$t")
fi

if (( on_lim7 )); then
  heat $rl7; local c7=$REPLY
  t="${c7}󰨳 "
  (( on_barlim )) && { bar $rl7 $LIM_BAR; t+="${c7}${REPLY} " }
  t+="${c7}${p7}${FR}"
  (( on_reset )) && [[ -n $span7 ]] && t+="${DIM} 󰑐 ${span7}${FR}"
  groups+=("$t")
fi

(( on_time )) && groups+=("${FG}󱎫 ${dspan}${FR}")

if (( on_cost )); then
  t="${CYN}󰄔 ${scost}${FR}"
  # The session total alone under-reports whenever the day ran across several
  # sessions, so this is the figure worth the space once there is space for it.
  (( on_today )) && t+="  ${DIM}󰃭 ${tcost}${FR}"
  groups+=("$t")
fi

local line='' g
for g in $groups; do
  pill "$g"
  [[ -n $line ]] && line+=' '
  line+=$REPLY
done
print -r -- "$line"
exit 0
