#!/usr/bin/env bash
# Caches PR review, CI and (optionally) train state for statusline.sh, which must
# never block on the network. Spawned detached; a lock keeps multiple panes on the
# same branch from stampeding the API at once.

set -uo pipefail

cache=${1:-} owner=${2:-} repo=${3:-} branch=${4:-} dir=${5:-}
[[ -n $cache && -n $owner && -n $repo && -n $branch ]] || exit 0
command -v gh >/dev/null 2>&1 || exit 0

mtime() { stat -f %m -- "$1" 2>/dev/null || stat -c %Y -- "$1" 2>/dev/null || echo 0; }

mkdir -p "$(dirname "$cache")"
# mkdir is atomic and portable (no flock on macOS); a lock dir older than 5
# minutes is assumed abandoned by a killed process and reclaimed.
lockdir="$cache.lock.d"
if [[ -d $lockdir ]] && (( $(date +%s) - $(mtime "$lockdir") > 300 )); then
  rmdir "$lockdir" 2>/dev/null
fi
mkdir "$lockdir" 2>/dev/null || exit 0
trap 'rmdir "$lockdir" 2>/dev/null' EXIT
: > "$cache.attempt"

pr_for() {
  timeout 25 gh api graphql -f owner="$owner" -f repo="$repo" -f head="$1" -f query='
    query($owner:String!,$repo:String!,$head:String!){
      repository(owner:$owner,name:$repo){
        pullRequests(headRefName:$head,first:1,states:[OPEN,MERGED],orderBy:{field:CREATED_AT,direction:DESC}){
          nodes{ number url baseRefName isDraft state reviewDecision mergeable mergeStateStatus
            reviewThreads(first:100){ nodes{ isResolved isOutdated } }
            reviews(first:50){ nodes{ state } }
            labels(first:20){ nodes{ name } }
            comments(last:50){ nodes{ author{ login } body } }
            commits(last:1){ nodes{ commit{ statusCheckRollup{ state
              contexts(first:100){ nodes{
                __typename
                ... on CheckRun{ name conclusion status detailsUrl }
                ... on StatusContext{ context state targetUrl } } } } } } } } }
        children:pullRequests(baseRefName:$head,first:5,states:[OPEN,MERGED]){ nodes{ headRefName state } }
      }
    }' 2>/dev/null
}

root=$(pr_for "$branch")
# GitHub computes mergeability lazily and answers UNKNOWN while it does; one
# re-ask a moment later is what turns a fresh PR into a real verdict.
if [[ $(jq -r '.data.repository.pullRequests.nodes[0].mergeable // ""' <<<"$root" 2>/dev/null) == UNKNOWN ]]; then
  sleep 3
  again=$(pr_for "$branch")
  [[ -n $(jq -r '.data.repository.pullRequests.nodes[0].number // ""' <<<"$again" 2>/dev/null) ]] && root=$again
fi
node() { jq -r "$1 // \"\"" <<<"${2:-$root}" 2>/dev/null; }

number=$(node '.data.repository.pullRequests.nodes[0].number')
if [[ -z $number ]]; then
  # Only record "no PR" when GitHub actually answered. A failed call leaves the
  # previous cache in place, so a blip shows slightly stale data rather than
  # silently erasing the PR row.
  if [[ -n $(jq -r 'if .data.repository.pullRequests then "ok" else "" end' <<<"$root" 2>/dev/null) ]]; then
    printf '{"branch":%s,"pr":null,"updated":%s}\n' "$(jq -Rn --arg b "$branch" '$b')" "$(date +%s)" > "$cache.tmp"
    mv "$cache.tmp" "$cache"
  fi
  exit 0
fi

pos=1 total=1
base=$(node '.data.repository.pullRequests.nodes[0].baseRefName')
parent=$base
base_age=""

# Off unless CC_STATUSLINE_PR_TRAIN=1: walking base/child chains costs extra
# GraphQL calls per branch, worth it only if you actually work in stacked PRs.
if [[ -n ${CC_STATUSLINE_PR_TRAIN:-} ]]; then
  # How stale the parent of a stacked branch is: rebasing it rewrites every
  # child, so it is worth knowing before starting work. Slow git is fine out here.
  if [[ -n $dir && -n $parent && $parent != master && $parent != main ]]; then
    bmb=$(git -C "$dir" merge-base "origin/$parent" origin/master 2>/dev/null || git -C "$dir" merge-base "origin/$parent" origin/main 2>/dev/null)
    if [[ -n $bmb ]]; then
      bct=$(git -C "$dir" log -1 --format=%ct "$bmb" 2>/dev/null)
      [[ $bct =~ ^[0-9]+$ ]] && base_age=$(( ($(date +%s) - bct) / 86400 ))
    fi
  fi
  # Count only PRs still open: once a parent lands, GitHub retargets this PR at
  # master and the stack is one shorter, so a merged ancestor must not inflate it.
  for _ in 1 2 3 4 5; do
    [[ -n $base && $base != master && $base != main ]] || break
    resp=$(pr_for "$base")
    [[ -n $(node '.data.repository.pullRequests.nodes[0].number' "$resp") ]] || break
    [[ $(node '.data.repository.pullRequests.nodes[0].state' "$resp") == OPEN ]] || break
    pos=$((pos + 1)); total=$((total + 1))
    base=$(node '.data.repository.pullRequests.nodes[0].baseRefName' "$resp")
  done
  child=$(node '[.data.repository.children.nodes[] | select(.state == "OPEN")][0].headRefName')
  for _ in 1 2 3 4 5; do
    [[ -n $child ]] || break
    total=$((total + 1))
    resp=$(pr_for "$child")
    child=$(node '[.data.repository.children.nodes[] | select(.state == "OPEN")][0].headRefName' "$resp")
  done
fi

# CC_STATUSLINE_CI_CHECK_RE names the CI check that gates merging (used to detect
# "untested" before it has run and to find its build URL). CC_STATUSLINE_CI_BOT_RE
# + CC_STATUSLINE_CI_STEP_RE (a regex with a named `s` group) mine a CI bot's PR
# comment for the specific failing step. All three are off by default, since this
# script has no idea what CI system or bots any given repo uses; without them the
# statusline still shows a plain pass/fail count from the check-run rollup.
jq -c --argjson pos "$pos" --argjson total "$total" --argjson now "$(date +%s)" \
  --arg parent "$parent" --arg base_age "$base_age" \
  --arg ci_check_re "${CC_STATUSLINE_CI_CHECK_RE:-}" \
  --arg ci_bot_re "${CC_STATUSLINE_CI_BOT_RE:-}" \
  --arg ci_step_re "${CC_STATUSLINE_CI_STEP_RE:-}" '
  .data.repository.pullRequests.nodes[0] as $p
  | ([$p.commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]?
      | {name:(.name // .context), state:(.conclusion // .state), url:(.detailsUrl // .targetUrl // "")}]) as $ctx
  | ([$ctx[] | select(.state == "FAILURE" or .state == "ERROR" or .state == "TIMED_OUT")]) as $bad
  | ([$bad[] | select(.name != "OWNERS")]) as $badci
  | (if $ci_check_re != "" then ([$ctx[] | select(.name | test($ci_check_re)) | .url][0] // "") else "" end) as $bk
  | (($bk | capture("builds/(?<b>[0-9]+)").b?) // "") as $bkbuild
  | (if $ci_bot_re != "" and $ci_step_re != "" then
      ([$p.comments.nodes[]?
        | select(.author.login | test($ci_bot_re))
        | select($bkbuild != "" and (.body | contains("builds/" + $bkbuild)))
        | (.body | capture($ci_step_re).s?)
        | select(. != null)
        | sub("^:[a-z0-9_+-]+: "; "") | sub(" \\(trigger\\)$"; "")] | unique)
    else [] end) as $steps
  | ([$p.labels.nodes[]?.name]) as $labels
  | ([$p.reviewThreads.nodes[]? | select(.isResolved == false)]) as $open
  | {
      updated: $now,
      pr: $p.number, url: $p.url, draft: $p.isDraft, state: $p.state,
      decision: ($p.reviewDecision // ""),
      commented: ([$p.reviews.nodes[]? | select(.state == "COMMENTED")] | length),
      unresolved: ($open | length),
      unresolved_current: ([$open[] | select(.isOutdated == false)] | length),
      mergeable: ($p.mergeable // ""),
      merge_state: ($p.mergeStateStatus // ""),
      rollup: ($p.commits.nodes[0].commit.statusCheckRollup.state // ""),
      tested: (if $ci_check_re != "" then ([$ctx[] | select(.name | test($ci_check_re))] | length > 0) else true end),
      ci_total: ($ctx | length),
      ci_fail: ($badci | length),
      ci_run: ([$ctx[] | select(.state == "PENDING" or .state == "IN_PROGRESS" or .state == "QUEUED" or .state == "EXPECTED")] | length),
      ci_first_fail: ($badci[0].name // ""),
      ci_first_url: ($badci[0].url // ""),
      bk_url: $bk,
      fail_steps: $steps,
      action: ([$labels[] | select(startswith("Action required:")) | sub("^Action required: "; "")][0] // ""),
      queue_ready: ([$labels[] | select(. == "merge-queue-ready")] | length > 0),
      label_stale: ([$labels[] | select(. == "stale")] | length > 0),
      owners_fail: ([$bad[] | select(.name == "OWNERS")] | length > 0),
      train_pos: $pos, train_total: $total,
      parent: $parent, base_age: $base_age
    }' <<<"$root" > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" || rm -f "$cache.tmp"
