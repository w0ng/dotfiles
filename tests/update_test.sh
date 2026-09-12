#!/bin/bash
#
# Tests for update.sh.
#
# Run from the repository root:
#
#   bash tests/update_test.sh
#
# update.sh is sourced rather than executed, so its steps can be called one at
# a time. Nothing here touches the real machine. Every tool it drives is a stub
# that records its arguments, HOMEBREW_PREFIX points at a scratch tree holding
# fake rustup, tpm and antidote installs, and HOME, ZDOTDIR and both XDG
# variables point into the same scratch directory. The XDG pair matters as much
# as HOME, because two probes read them first and only fall back to HOME, so
# without them a machine that exports either reaches its real tpm clone or its
# real antidote checkout from inside the suite.
#
# Most of these guard the unattended contract. A step that prompts, or that
# stops the run when it fails, is the bug this suite exists to catch.

# shellcheck source-path=SCRIPTDIR source=./harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

setup() {
  WORK_DIR="$(mktemp -d)"
  STUB_LOG="${WORK_DIR}/calls.log"
  : >"${STUB_LOG}"

  mkdir -p "${WORK_DIR}/stubs" "${WORK_DIR}/home/.config/zsh"

  # One stub for every tool, recording what it was called with. STUB_STATUS_<x>
  # lets a test make one of them fail without touching the others.
  local tool
  for tool in brew npm git nvim zsh; do
    cat >"${WORK_DIR}/stubs/${tool}" <<STUB
#!/bin/bash
printf '${tool} %s\n' "\$*" >> "\${STUB_LOG}"
eval "\${STUB_OUTPUT_${tool}:-}"
exit "\${STUB_STATUS_${tool}:-0}"
STUB
  done
  chmod +x "${WORK_DIR}/stubs/"*

  # The Homebrew prefix update.sh probes for the tools that are not on PATH.
  # Real files, so the -x test they are found by means something.
  fake_prefix_tool 'opt/rustup/bin/rustup'
  fake_prefix_tool 'opt/tpm/share/tpm/bin/update_plugins'
  fake_prefix_tool 'opt/antidote/share/antidote/antidote'
  # Sourced by antidote rather than run, so its presence is what the probe
  # looks for.
  : >"${WORK_DIR}/brew/opt/antidote/share/antidote/antidote.zsh"

  BREW="${WORK_DIR}/stubs/brew"
  NPM="${WORK_DIR}/stubs/npm"
  GIT_BIN="${WORK_DIR}/stubs/git"
  NVIM_BIN="${WORK_DIR}/stubs/nvim"
  ZSH_BIN="${WORK_DIR}/stubs/zsh"
  HOME="${WORK_DIR}/home"
  ZDOTDIR="${WORK_DIR}/home/.config/zsh"
  XDG_CONFIG_HOME="${WORK_DIR}/home/.config"
  XDG_DATA_HOME="${WORK_DIR}/home/.local/share"
  export STUB_LOG WORK_DIR BREW NPM GIT_BIN NVIM_BIN ZSH_BIN HOME ZDOTDIR
  export XDG_CONFIG_HOME XDG_DATA_HOME

  # Read by homebrew_prefix(), which returns it rather than asking brew.
  HOMEBREW_PREFIX="${WORK_DIR}/brew"
  # Keeps the Homebrew probe in the sourced bootstrap.sh away from the real
  # prefixes, so no test can eval the machine's own `brew shellenv`.
  BREW_PREFIXES="${WORK_DIR}/no-brew"
  export HOMEBREW_PREFIX BREW_PREFIXES

  # shellcheck source-path=SCRIPTDIR source=../update.sh
  source "${REPO_ROOT}/update.sh"
  # update.sh sets errexit for its own run; leaving it on here would abort a
  # test the moment it called a step that legitimately returns non-zero.
  # nounset goes with it, and not only for the stub environment. bash 3.2
  # treats an empty array as unbound, and a stub leaves variables unset that a
  # real run always has.
  set +e +u +o pipefail

  DRY_RUN=false
  GREEDY=false
  DOTFILES_DIR="${WORK_DIR}/repo"
  # step_npm reads the package list out of bootstrap's own declarations, so the
  # scratch repo needs a bootstrap.sh to declare some.
  mkdir -p "${DOTFILES_DIR}"
  cat >"${DOTFILES_DIR}/bootstrap.sh" <<'FAKE'
mod_neovim() {
  npm_global bash-language-server
  npm_global typescript
}
FAKE
}

teardown() {
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
  unset STUB_STATUS_brew STUB_STATUS_npm STUB_STATUS_git STUB_STATUS_nvim \
    STUB_STATUS_zsh STUB_OUTPUT_git
}

fake_prefix_tool() {
  local path="${WORK_DIR}/brew/$1"
  mkdir -p "$(dirname "${path}")"
  cat >"${path}" <<STUB
#!/bin/bash
printf '$(basename "$1") %s\n' "\$*" >> "\${STUB_LOG}"
exit 0
STUB
  chmod +x "${path}"
}

# A checkout whose git stub answers the three questions step_repo asks.
fake_clean_checkout() {
  local head="${1:-cafe1234}"
  mkdir -p "${DOTFILES_DIR}/.git"
  export STUB_OUTPUT_git="
case \"\$*\" in
  *'status --porcelain'*) ;;
  *'rev-parse @{u}'*) ;;
  *'rev-list --count'*) printf '3\n' ;;
  *'rev-parse HEAD'*) printf '${head}\n' ;;
esac"
}

#######################################
# Wiring
#######################################

# Both directions, because a step function nobody lists never runs, and a name
# in STEPS with no function fails the whole run at validate_steps.
test_every_step_has_a_function() {
  validate_steps "${STEPS[@]}" 2>/dev/null
  assert_success $? 'every listed step has a step_ function'
}

test_every_step_function_is_listed() {
  local name
  while read -r name; do
    assert_contains " ${STEPS[*]} " " ${name} " "step_${name} is in STEPS"
  done < <(known_steps)
}

# The file reads in the order it runs, which is easy to break by appending a
# new step at the bottom.
test_definitions_are_in_steps_order() {
  local defined expected
  defined="$(grep -oE '^step_[a-z]+' "${REPO_ROOT}/update.sh" \
    | sed 's/^step_//' | tr '\n' ' ')"
  expected="${STEPS[*]} "

  assert_eq "${expected}" "${defined}" 'definitions follow STEPS order'
}

# brew upgrades tmux, neovim, node and antidote themselves, so the steps that
# drive those have to run after it, not before.
test_brew_precedes_the_steps_it_upgrades() {
  local order=" ${STEPS[*]} " name
  local brew_at="${order%% brew *}"
  for name in npm rust tmux neovim zsh; do
    local step_at="${order%% "${name}" *}"
    ((${#brew_at} < ${#step_at})) \
      || fail "${name} must come after brew"
  done
}

test_usage_documents_every_flag() {
  local output flag
  output="$(usage)"
  for flag in --list --dry-run --greedy --help; do
    assert_contains "${output}" "${flag}" "usage mentions ${flag}"
  done
}

test_parse_args_collects_flags_and_steps() {
  parse_args --dry-run --greedy brew zsh
  assert_eq 'true' "${DRY_RUN}" '--dry-run sets DRY_RUN'
  assert_eq 'true' "${GREEDY}" '--greedy sets GREEDY'
  assert_eq 'brew zsh' "${REQUESTED[*]}" 'bare arguments are steps'
}

test_parse_args_rejects_an_unknown_flag() {
  local status=0
  parse_args --nope 2>/dev/null || status=$?
  assert_eq '1' "${status}" 'an unknown flag fails'
}

test_informational_flags_return_ten() {
  local status=0
  parse_args --list >/dev/null || status=$?
  assert_eq '10' "${status}" '--list reports that it printed'
}

test_validate_steps_rejects_a_typo() {
  local status=0
  validate_steps brew nosuchstep 2>/dev/null || status=$?
  assert_eq '1' "${status}" 'a bad step name fails'
}

#######################################
# Steps
#######################################

test_dry_run_changes_nothing() {
  DRY_RUN=true
  GREEDY=true
  fake_clean_checkout

  local name output=''
  for name in "${STEPS[@]}"; do
    output+="$("step_${name}")"
  done

  # A positive assertion first. Without one, every assertion below passes just
  # as well when the steps skipped for an unrelated reason and ran nothing.
  assert_contains "${output}" 'brew upgrade' 'the upgrade was printed'
  assert_contains "${output}" 'update_plugins all' 'so was the tmux one'
  # Read-only queries are expected even under --dry-run; mutations are not.
  assert_not_contains "$(calls)" 'brew upgrade' 'nothing was upgraded'
  assert_not_contains "$(calls)" 'npm update' 'nothing was updated'
  assert_not_contains "$(calls)" 'pull --ff-only' 'nothing was pulled'
  assert_not_contains "$(calls)" 'nvim --headless' 'neovim never started'
}

test_brew_updates_then_upgrades() {
  step_brew >/dev/null
  assert_contains "$(calls)" 'brew update --quiet' 'the index is refreshed'
  assert_contains "$(calls)" 'brew upgrade' 'packages are upgraded'
}

# After the upgrades, because that is what leaves the old versions and the
# orphaned dependencies behind for it to collect.
test_brew_housekeeping_follows_the_upgrades() {
  step_brew >/dev/null
  local output
  output="$(calls)"
  local task
  for task in autoremove cleanup doctor; do
    assert_contains "${output}" "brew ${task}" "housekeeping runs ${task}"
  done
  assert_eq 'brew upgrade' "$(grep -E 'brew (upgrade|autoremove)' \
    "${STUB_LOG}" | head -1)" 'the upgrade comes first'
}

# doctor exits non-zero for any warning at all, and a machine with third-party
# taps always has one. Failing the run over it would make the exit status a
# scheduled job reads mean nothing.
test_brew_doctor_warnings_do_not_fail_the_step() {
  export STUB_STATUS_brew=0
  local status=0
  # Only doctor fails; everything before it succeeds.
  cat >"${BREW}" <<'STUB'
#!/bin/bash
printf 'brew %s\n' "$*" >> "${STUB_LOG}"
[[ "$1" == doctor ]] && exit 1
exit 0
STUB
  chmod +x "${BREW}"

  local output
  output="$(step_brew 2>&1)" || status=$?
  assert_eq '0' "${status}" 'a doctor warning is not a failed step'
  assert_contains "${output}" 'brew doctor' 'but it is reported'
}

# Homebrew 6 asks before an upgrade that reaches past the package named, and
# there is nobody to answer.
test_brew_opts_out_of_ask_mode() {
  local output
  output="$(HOMEBREW_NO_ASK='' bash -c '
    source "'"${REPO_ROOT}"'/update.sh"
    BREW="'"${BREW}"'"
    step_brew >/dev/null
    printf "%s" "${HOMEBREW_NO_ASK}"')"
  assert_eq '1' "${output}" 'HOMEBREW_NO_ASK is exported'
}

# Greedy casks can want a password, which is the one thing here that can stall
# an unattended run, so it has to stay behind the flag.
test_greedy_is_opt_in() {
  step_brew >/dev/null
  assert_not_contains "$(calls)" '--greedy' 'off by default'

  : >"${STUB_LOG}"
  GREEDY=true
  step_brew >/dev/null
  assert_contains "$(calls)" 'upgrade --cask --greedy' 'on with the flag'
}

# Homebrew runs `sudo -A` when SUDO_ASKPASS is set, so an askpass that cannot
# answer turns a cask's password prompt into a failure this run reports rather
# than a wait nothing will end. --greedy widens that exposure; it is not what
# creates it.
test_brew_refuses_a_password_prompt_without_a_terminal() {
  step_brew </dev/null >/dev/null
  assert_eq '/usr/bin/false' "${SUDO_ASKPASS:-unset}" \
    'an unanswerable askpass is set when there is no terminal'
}

test_repo_leaves_a_dirty_checkout_alone() {
  mkdir -p "${DOTFILES_DIR}/.git"
  export STUB_OUTPUT_git="
case \"\$*\" in
  *'status --porcelain'*) printf ' M bootstrap.sh\n' ;;
esac"

  local output
  output="$(step_repo)"
  assert_contains "${output}" 'uncommitted changes' 'it says why'
  assert_not_contains "$(calls)" 'pull' 'a dirty checkout is never pulled'
}

test_repo_pulls_without_asking_for_a_merge() {
  fake_clean_checkout
  step_repo >/dev/null
  # --ff-only, because a merge commit would open an editor nobody is watching.
  assert_contains "$(calls)" 'pull --ff-only' 'the pull cannot start a merge'
}

test_repo_points_at_bootstrap_for_new_packages() {
  # Two different revisions, so the pull looks like it brought something.
  mkdir -p "${DOTFILES_DIR}/.git"
  export STUB_OUTPUT_git="
case \"\$*\" in
  *'status --porcelain'*) ;;
  *'rev-parse @{u}'*) ;;
  *'rev-list --count'*) printf '3\n' ;;
  *'rev-parse HEAD'*) printf '%s\n' \"\${RANDOM}\" ;;
esac"

  local output
  output="$(step_repo)"
  assert_contains "${output}" 'bootstrap.sh' 'new commits point at bootstrap'
}

# A bare `npm update -g` takes every global on the machine, including the npm
# inside Homebrew's node keg, which brew would then be tracking a version it
# did not install.
test_npm_updates_only_what_bootstrap_declares() {
  step_npm >/dev/null
  assert_eq 'npm update -g bash-language-server typescript' "$(calls)" \
    'exactly the declared packages, and npm itself is not one of them'
}

test_npm_refuses_to_guess_the_package_list() {
  : >"${DOTFILES_DIR}/bootstrap.sh"
  local status=0
  step_npm >/dev/null 2>&1 || status=$?
  assert_eq '1' "${status}" 'an empty list is a failed step'
  assert_eq '' "$(calls)" 'and never falls back to every global'
}

test_tmux_updates_every_installed_plugin() {
  step_tmux >/dev/null
  assert_contains "$(calls)" 'update_plugins all' 'tpm updates all of them'
}

test_rust_leaves_rustup_to_its_owner() {
  step_rust >/dev/null
  # Homebrew or the work provisioning owns the binary; a self-update leaves
  # that owner tracking a version it no longer controls.
  assert_contains "$(calls)" 'rustup update --no-self-update' \
    'the toolchain updates, rustup does not update itself'
}

test_zsh_makes_the_static_bundle_rebuild() {
  local plugins="${ZDOTDIR}/.zsh_plugins.txt"
  local before
  : >"${plugins}"
  # Dated, then compared against that date rather than against a marker file:
  # bash 3.2's -nt compares whole seconds, so a marker written in the same
  # second as the touch is not older than it.
  touch -t 200001010000 "${plugins}"
  before="$(stat -f %m "${plugins}")"

  step_zsh >/dev/null

  assert_contains "$(calls)" 'antidote update --bundles' 'bundles are fetched'
  # .zshrc regenerates the bundle only when the plugin list is the newer file,
  # so without this an added plugin file is never sourced.
  [[ "$(stat -f %m "${plugins}")" != "${before}" ]] \
    || fail 'the plugin list was not touched'
}

test_steps_skip_a_tool_that_is_not_installed() {
  BREW="${WORK_DIR}/stubs/absent"
  NPM="${WORK_DIR}/stubs/absent"
  NVIM_BIN="${WORK_DIR}/stubs/absent"
  HOMEBREW_PREFIX="${WORK_DIR}/empty"

  local name status
  for name in brew npm rust tmux neovim zsh; do
    status=0
    "step_${name}" >/dev/null 2>&1 || status=$?
    assert_eq '0' "${status}" "step_${name} skips rather than fails"
  done
  assert_eq '' "$(calls)" 'nothing was run'
}

#######################################
# The unattended contract
#######################################

# A -c that fails aborts the ones after it, so a trailing `-c qa` would be the
# first casualty of an error, and a headless Neovim with nothing to quit it
# waits forever.
test_neovim_always_quits_itself() {
  step_neovim >/dev/null
  local output
  output="$(calls)"
  assert_contains "${output}" "qa!" 'the chunk quits on success'
  assert_contains "${output}" "cq!" 'and quits on failure, with a status'
  assert_contains "${output}" 'force = true' 'no confirmation buffer'
}

# Neither half raises on a failed update. vim.pack records the error on the
# plugin and appends it to nvim-pack.log, and nvim-treesitter returns false
# rather than erroring. Without these two checks the step returns 0 and the
# exit status a scheduled job reads says the update worked.
test_neovim_looks_for_the_failures_that_do_not_raise() {
  step_neovim >/dev/null
  local output
  output="$(calls)"
  assert_contains "${output}" 'nvim-pack.log' 'the pack log is read back'
  assert_contains "${output}" '# Error' 'and checked for the error heading'
  # The guard, not the message. The message survives a chunk that calls update
  # and throws the boolean away.
  assert_contains "${output}" 'if not ts.update' 'the parser result is tested'
}

test_a_failing_nvim_fails_the_step() {
  export STUB_STATUS_nvim=1
  local status=0
  step_neovim >/dev/null 2>&1 || status=$?
  assert_eq '1' "${status}" 'a non-zero nvim is a failed step'
}

# Two runs, because the second loads the plugin code the first installed, and
# nvim-treesitter only supports the parsers pinned by the copy compiling them.
test_neovim_updates_parsers_after_plugins() {
  step_neovim >/dev/null
  local first second
  first="$(grep -c 'vim.pack.update' "${STUB_LOG}")"
  second="$(grep -c 'nvim-treesitter' "${STUB_LOG}")"
  assert_eq '1' "${first}" 'plugins are updated once'
  assert_eq '1' "${second}" 'parsers are updated once'
  assert_eq '2' "$(grep -c '^nvim ' "${STUB_LOG}")" 'in separate sessions'
}

# The whole reason a step returns a status instead of exiting. An unreachable
# remote in one step must not cost you the other six.
test_a_failing_step_does_not_stop_the_run() {
  export STUB_STATUS_npm=1
  local status=0
  main npm zsh >/dev/null 2>&1 || status=$?

  assert_eq '1' "${status}" 'the run reports the failure'
  assert_contains "$(calls)" 'antidote update' 'the later step still ran'
}

# Asserted on the variables alone. Reading them out of main's stdout instead
# passes on the scratch path in the "repo at ..." line, which holds a digit.
test_git_cannot_stop_on_a_credential_prompt() {
  main --dry-run repo >/dev/null 2>&1
  assert_eq '0' "${GIT_TERMINAL_PROMPT:-unset}" 'GIT_TERMINAL_PROMPT is 0'
}

# git's own variable covers its credential prompt and nothing else. A key
# passphrase or an unknown host key is ssh asking, and origin here is ssh.
test_ssh_cannot_stop_on_a_passphrase_prompt() {
  main --dry-run repo >/dev/null 2>&1
  assert_contains "${GIT_SSH_COMMAND:-unset}" 'BatchMode=yes' \
    'ssh is put in batch mode'
}

# launchd and cron hand a job a PATH with no Homebrew on it. Without the
# shellenv eval in preflight, six of the seven steps skip and the run still
# exits 0, which in a job log is indistinguishable from an up-to-date machine.
test_preflight_puts_homebrew_on_a_bare_path() {
  mkdir -p "${WORK_DIR}/prefix/bin"
  cat >"${WORK_DIR}/prefix/bin/brew" <<STUB
#!/bin/bash
[[ "\$1" == shellenv ]] \
  && printf 'export PATH="%s:\$PATH"\n' "${WORK_DIR}/stubs"
exit 0
STUB
  chmod +x "${WORK_DIR}/prefix/bin/brew"
  BREW_PREFIXES="${WORK_DIR}/prefix"
  # Found by name, the way a real run finds it, rather than by absolute path.
  BREW=brew
  PATH=/usr/bin:/bin

  main brew >/dev/null 2>&1
  assert_contains "$(calls)" 'brew upgrade' 'the brew step found brew'
}

main
