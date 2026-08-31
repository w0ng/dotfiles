#!/usr/bin/env bash
# Two left-packed rows: where you are on line 1, what the work is doing on line 2.
# Segments drop by priority as the pane narrows — nothing is right-aligned, because
# a half-width pane strands the right-hand group behind an ellipsis.
#
# Nothing here may be slow: it runs on every assistant message. `git status` can cost
# seconds in a large repo, so no segment uses it. Branch comes from one read of
# `.git/HEAD`; branch age is cached; PR review, CI, mergeability and (optionally)
# train position come from a cache that a detached statusline-pr.sh refreshes.
#
# A handful of segments only activate when their env var is set — see the table in
# the README. They're no-ops otherwise, since this script has no idea what ticket
# tracker, CI gate, or branching convention any given repo uses.

set -uo pipefail

input=$(cat)
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mtime() { stat -f %m -- "$1" 2>/dev/null || stat -c %Y -- "$1" 2>/dev/null || echo 0; }

mapfile -t F < <(printf '%s' "$input" | jq -r '
  [ .workspace.current_dir // .cwd // "",
    .workspace.repo.owner // "",
    .workspace.repo.name // "",
    ((.context_window.used_percentage // 0) | floor),
    (.context_window.total_input_tokens // 0),
    (.context_window.context_window_size // 200000),
    (.cost.total_cost_usd // 0),
    (((.cost.total_cost_usd // 0) * 100) | floor),
    (.pr.number // "" | tostring),
    .pr.review_state // "",
    .agent.name // "",
    (.rate_limits.five_hour.used_percentage // "" | tostring),
    (.rate_limits.seven_day.used_percentage // "" | tostring)
  ] | .[] | tostring')

(( ${#F[@]} >= 13 )) || exit 0

DIR=${F[0]} OWNER=${F[1]} REPO=${F[2]} PCT=${F[3]} TOKENS=${F[4]} CTXSIZE=${F[5]}
COST=${F[6]} CENTS=${F[7]} PR_NUM=${F[8]} PR_STATE=${F[9]} AGENT=${F[10]}
RL5=${F[11]} RL7=${F[12]}

R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'
I_REVIEW=$''; I_WARN=$''; I_BUILD=$''; I_THREAD=$''
I_OK=$''; I_TAG=$''; I_CLOCK=$''; I_BRANCH=$''
I_TRAIN=$''; I_DB=$''; I_COST=$''; I_PR=$''
I_GEAR=$''; I_FAIL=$''
RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLU=$'\033[34m'; MAG=$'\033[35m'; CYN=$'\033[36m'
NOW=$(date +%s)

# BEL-terminated OSC 8, the form the Claude Code docs use. Requires FORCE_HYPERLINK=1
# in the environment: Claude Code decides whether to emit OSC 8 by sniffing
# TERM_PROGRAM/VTE_VERSION, which some terminal multiplexers don't forward, and
# otherwise strips these. Sets $LNK rather than returning, since assemble() runs
# repeatedly while fitting the line and a fork per segment adds up.
link() { if [[ -z ${2:-} || -n ${CC_STATUSLINE_NO_LINKS:-} ]]; then LNK=$1
  else printf -v LNK '\033]8;;%s\a\033[4m%s\033[24m\033]8;;\a' "$2" "$1"; fi; }

# The branch comes from reading .git/HEAD with shell builtins rather than
# `git for-each-ref`/`git branch`, which fork a process and are measurably slower
# on every render. Worktrees keep .git as a file pointing at the real gitdir.
BRANCH=""
gitdir=""
d=$DIR
while [[ -n $d && $d != / ]]; do
  if [[ -e $d/.git ]]; then
    gitdir=$d/.git
    if [[ -f $gitdir ]]; then
      line=$(<"$gitdir")
      gitdir=${line#gitdir: }
      [[ $gitdir != /* ]] && gitdir=$d/$gitdir
    fi
    break
  fi
  d=${d%/*}
done
if [[ -n $gitdir && -f $gitdir/HEAD ]]; then
  head=$(<"$gitdir/HEAD")
  [[ $head == "ref: refs/heads/"* ]] && BRANCH=${head#ref: refs/heads/}
fi

CDIR="${XDG_CACHE_HOME:-$HOME/.cache}/cc-statusline"
AGE=""
if [[ -n $BRANCH && $BRANCH != master && $BRANCH != main ]]; then
  agef="$CDIR/age-${OWNER:-x}-${REPO:-x}-${BRANCH//\//_}"
  if [[ -s $agef ]]; then
    cached=$(<"$agef"); cts=${cached%% *}; cval=${cached##* }
    [[ $cts =~ ^[0-9]+$ ]] && (( NOW - cts < 600 )) && AGE=$cval
  fi
  if [[ -z $AGE ]]; then
    mb=$(git -C "$DIR" merge-base HEAD origin/master 2>/dev/null || git -C "$DIR" merge-base HEAD origin/main 2>/dev/null)
    if [[ -n $mb ]]; then
      ct=$(git -C "$DIR" log -1 --format=%ct "$mb" 2>/dev/null)
      if [[ $ct =~ ^[0-9]+$ ]]; then
        AGE=$(( (NOW - ct) / 86400 ))
        mkdir -p "$CDIR" && printf '%s %s' "$NOW" "$AGE" > "$agef"
      fi
    fi
  fi
fi

# Off unless CC_STATUSLINE_MAIN_CHECKOUT names a path — e.g. a primary checkout
# that per your team's convention should always stay on the default branch.
GUARD=""
if [[ -n ${CC_STATUSLINE_MAIN_CHECKOUT:-} ]]; then
  mc=${CC_STATUSLINE_MAIN_CHECKOUT%/}
  if [[ -n $mc && ( $DIR == "$mc" || $DIR == "$mc/"* ) && -n $BRANCH && $BRANCH != master && $BRANCH != main ]]; then
    GUARD="main checkout"
  fi
fi

PRD=""
if [[ -n $OWNER && -n $REPO && -n $BRANCH && $BRANCH != master && $BRANCH != main ]]; then
  PR_CACHE="$CDIR/pr-${OWNER}-${REPO}-${BRANCH//\//_}.json"
  cage=$(( NOW - $(mtime "$PR_CACHE") ))
  aage=$(( NOW - $(mtime "$PR_CACHE.attempt") ))
  if (( cage > 90 && aage > 60 )) && [[ -x "$here/statusline-pr.sh" ]]; then
    # `set -m` gives the background job its own process group (bash only does this
    # automatically in interactive shells), so it survives after this script exits
    # instead of dying with it — the closest portable equivalent to Linux's setsid,
    # which isn't available on macOS.
    ( set -m; "$here/statusline-pr.sh" "$PR_CACHE" "$OWNER" "$REPO" "$BRANCH" "$DIR" >/dev/null 2>&1 & ) >/dev/null 2>&1
  fi
  [[ -s $PR_CACHE ]] && PRD=$(cat "$PR_CACHE" 2>/dev/null)
fi

P_NUM="" P_DEC="" P_CMT=0 P_UNRES=0 P_UNCUR=0 P_TESTED="" P_FAIL=0 P_RUN=0
P_POS=1 P_TOT=1 P_MERGE="" P_MSTATE="" P_URL="" P_CITOT=0 P_FAILURL="" P_BASEAGE="" P_BKURL="" P_ACTION="" P_QUEUE="" P_STEPS="" P_STATE=""
if [[ -n $PRD ]]; then
  mapfile -t C < <(jq -r '[ (.pr // ""), (.decision // ""), (.commented // 0), (.unresolved // 0),
    (.unresolved_current // 0), (.tested // ""), (.ci_fail // 0), (.ci_run // 0),
    (.train_pos // 1), (.train_total // 1), (.mergeable // ""),
    (.merge_state // ""), (.url // ""), (.ci_total // 0), (.ci_first_url // ""),
    (.base_age // ""), (.bk_url // ""), (.action // ""), (.queue_ready // false),
    ((.fail_steps // []) | join(",")), (.state // "") ] | .[] | tostring' <<<"$PRD" 2>/dev/null)
  if (( ${#C[@]} == 21 )); then
    P_NUM=${C[0]} P_DEC=${C[1]} P_CMT=${C[2]} P_UNRES=${C[3]} P_UNCUR=${C[4]}
    P_TESTED=${C[5]} P_FAIL=${C[6]} P_RUN=${C[7]} P_POS=${C[8]} P_TOT=${C[9]}
    P_MERGE=${C[10]} P_MSTATE=${C[11]} P_URL=${C[12]} P_CITOT=${C[13]} P_FAILURL=${C[14]}
    P_BASEAGE=${C[15]} P_BKURL=${C[16]} P_ACTION=${C[17]} P_QUEUE=${C[18]} P_STEPS=${C[19]} P_STATE=${C[20]}
  fi
fi
[[ -z $PR_NUM && -n $P_NUM ]] && PR_NUM=$P_NUM

# Off unless CC_STATUSLINE_TICKET_RE names a branch pattern. Must capture exactly
# three groups: board, number, rest-of-branch — e.g.
# '^andrew\.w-([a-z]+)-([0-9]+)-?(.*)$'. CC_STATUSLINE_TICKET_URL_FMT is a
# printf template with one %s for the ticket key.
CHIP="" CHIP_URL="" SHOWB=""
if [[ -n ${CC_STATUSLINE_TICKET_RE:-} && $BRANCH =~ ${CC_STATUSLINE_TICKET_RE} ]]; then
  CHIP="${BASH_REMATCH[1]^^}-${BASH_REMATCH[2]}"
  [[ -n ${CC_STATUSLINE_TICKET_URL_FMT:-} ]] && printf -v CHIP_URL "${CC_STATUSLINE_TICKET_URL_FMT}" "$CHIP"
  SHOWB=${BASH_REMATCH[3]:-}
else
  SHOWB=$BRANCH
fi
# Only outside herdr: its sidebar already names the space and the branch.
[[ -n ${HERDR_ENV:-} ]] && SHOWB=""

kfmt() { local n=$1
  (( n >= 1000000 )) && { printf '%d.%01dM' $(( n / 1000000 )) $(( (n % 1000000) / 100000 )); return; }
  (( n >= 1000 )) && { printf '%dk' $(( n / 1000 )); return; }; printf '%d' "$n"; }
# Days until a fortnight, then weeks: shorter than "10 days" and more precise
# than "1 week". The clock icon carries the unit's meaning.
age_fmt() { local d=$1
  (( d >= 14 )) && { printf '%dw' $(( d / 7 )); return; }
  (( d >= 1 )) && { printf '%dd' "$d"; return; }; printf 'today'; }

TOK_FMT=$(kfmt "$TOKENS")
if (( CTXSIZE >= 1000000 )); then CSZ="$((CTXSIZE/1000000))M"; else CSZ="$((CTXSIZE/1000))k"; fi
COST_FMT=$(printf '%.2f' "$COST")
COST_COLOUR=""; [[ $CENTS =~ ^[0-9]+$ ]] && (( CENTS == 0 )) && COST_COLOUR=$D
AGE_FMT=""; [[ -n $AGE ]] && AGE_FMT=$(age_fmt "$AGE")
BASE_FMT=""; [[ $P_BASEAGE =~ ^[0-9]+$ ]] && (( P_BASEAGE >= 7 )) && BASE_FMT=$(age_fmt "$P_BASEAGE")
STEP_FIRST=${P_STEPS%%,*}
STEP_COMMAS=${P_STEPS//[^,]/}; STEP_EXTRA=${#STEP_COMMAS}
TOK_COLOUR=$GRN; (( PCT >= 80 )) && TOK_COLOUR=$RED || { (( PCT >= 60 )) && TOK_COLOUR=$YEL; }
AGE_COLOUR=$D; [[ -n $AGE ]] && { (( AGE >= 14 )) && AGE_COLOUR=$RED || { (( AGE >= 7 )) && AGE_COLOUR=$YEL; }; }

DROP=0
declare -a L1_T L1_O L1_P L2_T L2_O L2_P
add() { local -n T="${1}_T" O="${1}_O" P="${1}_P"; T+=("$3"); O+=("$4"); P+=("$2"); }
join() { local -n T="${1}_T" O="${1}_O" P="${1}_P"; local i
  JT=""; JO=""
  for i in "${!T[@]}"; do
    (( P[i] != 0 && P[i] <= DROP )) && continue
    [[ -n $JT ]] && { JT+=" . "; JO+="${D} · ${R}"; }
    JT+="${T[i]}"; JO+="${O[i]}"
  done; }

assemble() {
  L1_T=() L1_O=() L1_P=() L2_T=() L2_O=() L2_P=()

  # ---- line 1: the local branch, before any PR exists ----
  [[ -n $GUARD ]] && add L1 0 "$I_WARN $GUARD" "${RED}${B}${I_WARN} ${GUARD}${R}"
  [[ ${HERDR_TASK:-} == 1 ]] && add L1 0 "$I_GEAR worker" "${MAG}${I_GEAR} worker${R}"
  [[ -n $AGENT ]] && add L1 6 "$I_GEAR $AGENT" "${MAG}${I_GEAR} ${AGENT}${R}"

  add L1 0 "$I_DB $TOK_FMT/$CSZ" "${D}${I_DB} ${R}${TOK_COLOUR}${TOK_FMT}${R}${D}/${CSZ}${R}"
  add L1 0 "$I_COST $COST_FMT" "${D}${I_COST} ${R}${COST_COLOUR}${COST_FMT}${R}"
  [[ -n $CHIP ]] && { link "$I_TAG $CHIP" "$CHIP_URL"; add L1 0 "$I_TAG $CHIP" "${CYN}${LNK}${R}"; }
  if [[ -n $SHOWB ]]; then
    local sb=$SHOWB
    (( DROP >= 3 )) && (( ${#sb} > 18 )) && sb="${sb:0:17}…"
    add L1 1 "$I_BRANCH $sb" "${D}${I_BRANCH}${R}${BLU}${sb}${R}"
  fi
  [[ $P_TOT =~ ^[0-9]+$ ]] && (( P_TOT > 1 )) &&
    add L1 1 "$I_TRAIN $P_POS/$P_TOT" "${D}${I_TRAIN} ${P_POS}/${P_TOT}${R}"
  if [[ -n $AGE_FMT ]]; then
    local at="$I_CLOCK $AGE_FMT"
    add L1 2 "$at" "${AGE_COLOUR}${at}${R}"
  fi
  if [[ -n $BASE_FMT ]]; then
    add L1 2 "$I_WARN rebase base $BASE_FMT" "${YEL}${I_WARN} rebase base ${BASE_FMT}${R}"
  fi

  local pair lbl val v c t pri
  for pair in "5h:$RL5:3" "7d:$RL7:4"; do
    IFS=: read -r lbl val pri <<<"$pair"
    [[ -z $val || $val == null ]] && continue
    v=${val%.*}; c=$D
    (( v >= 80 )) && c=$RED || { (( v >= 50 )) && c=$YEL; }
    t="$lbl ${v}%"
    add L1 "$pri" "$t" "${c}${t}${R}"
  done

  # ---- line 2: the PR, once one exists ----
  [[ -z $PR_NUM ]] && return

  if [[ $P_STATE == MERGED ]]; then
    link "$I_PR #${PR_NUM} $I_OK merged" "$P_URL"
    add L2 0 "$I_PR #${PR_NUM} $I_OK merged" "${GRN}${LNK}${R}"
    return
  fi

  local pm="" pc=$D
  case "${P_DEC:-$PR_STATE}" in
    APPROVED|approved) pm=" $I_OK LGTM" pc=$GRN ;;
    CHANGES_REQUESTED|changes_requested) pm=" $I_FAIL changes" pc=$RED ;;
    draft) pm=" draft" pc=$D ;;
    *) if [[ $P_CMT =~ ^[0-9]+$ ]] && (( P_CMT > 0 )); then pm=" $I_THREAD commented" pc=$YEL
       else pm=" awaiting" pc=$D; fi ;;
  esac
  (( DROP >= 4 )) && pm=""
  link "$I_PR #${PR_NUM}${pm}" "$P_URL"
  add L2 0 "$I_PR #${PR_NUM}${pm}" "${pc}${LNK}${R}"

  if [[ $P_MERGE == CONFLICTING ]]; then
    link "$I_WARN resolve conflicts" "${P_URL:+$P_URL/conflicts}"
    add L2 0 "$I_WARN resolve conflicts" "${RED}${B}${LNK}${R}"
  elif [[ $P_MSTATE == BEHIND ]]; then
    add L2 3 "$I_WARN behind base" "${YEL}${I_WARN} behind base${R}"
  fi

  if [[ -n $P_STEPS ]]; then
    local first=$STEP_FIRST st
    (( DROP >= 4 )) && (( ${#first} > 22 )) && first="${first:0:21}…"
    st="$I_BUILD $first"; (( STEP_EXTRA > 0 )) && st+=" +$STEP_EXTRA"
    link "$st" "${P_BKURL:-$P_FAILURL}"
    add L2 0 "$st" "${RED}${LNK}${R}"
  elif [[ $P_TESTED == false ]]; then
    link "$I_BUILD untested" "$P_URL"
    add L2 0 "$I_BUILD untested" "${YEL}${LNK}${R}"
  elif [[ $P_RUN =~ ^[0-9]+$ ]] && (( P_RUN > 0 )); then
    link "$I_BUILD $(( P_CITOT - P_RUN ))/$P_CITOT" "${P_URL:+$P_URL/checks}"
    add L2 2 "$I_BUILD $(( P_CITOT - P_RUN ))/$P_CITOT" "${YEL}${LNK}${R}"
  elif [[ $P_FAIL =~ ^[0-9]+$ ]] && (( P_FAIL > 0 )); then
    link "$I_BUILD ${P_FAIL}/${P_CITOT}" "${P_FAILURL:-$P_URL}"
    add L2 0 "$I_BUILD ${P_FAIL}/${P_CITOT}" "${RED}${LNK}${R}"
  elif [[ ${P_CITOT:-0} =~ ^[0-9]+$ ]] && (( P_CITOT > 0 )); then
    link "$I_BUILD $P_CITOT" "${P_URL:+$P_URL/checks}"
    add L2 3 "$I_BUILD $P_CITOT" "${GRN}${LNK}${R}"
  fi

  if [[ $P_UNCUR =~ ^[0-9]+$ ]] && (( P_UNCUR > 0 )); then
    local ut="$I_THREAD $P_UNCUR open"
    (( P_UNRES > P_UNCUR )) && ut+=" +$((P_UNRES-P_UNCUR))"
    link "$ut" "${P_URL:+$P_URL/files}"
    add L2 0 "$ut" "${YEL}${LNK}${R}"
  elif [[ $P_UNRES =~ ^[0-9]+$ ]] && (( P_UNRES > 0 )); then
    link "$I_THREAD $P_UNRES stale" "${P_URL:+$P_URL/files}"
    add L2 1 "$I_THREAD $P_UNRES stale" "${D}${LNK}${R}"
  fi

  if [[ -n $P_ACTION ]]; then
    link "$I_REVIEW $P_ACTION" "$P_URL"
    add L2 2 "$I_REVIEW $P_ACTION" "${YEL}${LNK}${R}"
  elif [[ $P_QUEUE == true ]]; then
    link "$I_OK queue-ready" "$P_URL"
    add L2 1 "$I_OK queue-ready" "${GRN}${LNK}${R}"
  fi
}

COLS=${COLUMNS:-0}; (( COLS < 40 )) && COLS=120
COLS=$(( COLS - ${CC_STATUSLINE_MARGIN:-6} ))
# Each row fits itself: a crowded line 2 must not strip segments off line 1.
OUT1="" OUT2=""
render_row() {
  local d
  for d in 0 1 2 3 4 5 6; do
    DROP=$d; assemble; join "$1"
    (( ${#JT} <= COLS )) && break
  done
  OUT=$JO
}
render_row L1; OUT1=$OUT
render_row L2; OUT2=$OUT

if [[ -n $OUT1 ]]; then printf '%s\n' "$OUT1"; fi
if [[ -n $OUT2 ]]; then printf '%s\n' "$OUT2"; fi
exit 0
