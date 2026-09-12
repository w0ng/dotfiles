#!/bin/bash
#
# Update everything bootstrap.sh installed, in one unattended run.
#
# Usage:
#   bash update.sh                 # run every step in STEPS
#   bash update.sh brew neovim     # run only these steps
#   bash update.sh --list          # print the steps
#   bash update.sh --dry-run       # print what would happen, change nothing
#   bash update.sh --greedy        # also re-sync casks that update themselves
#   bash update.sh --help
#
# bootstrap.sh installs what is missing and upgrades nothing. This upgrades and
# installs nothing. A tool that was never installed is bootstrap's business, so
# every step skips when its own tool is absent rather than reaching for a
# package manager.
#
# Unattended is the constraint the whole file is written around, because the
# caller may be a scheduled job with no terminal to answer from. Every step
# runs with no terminal attached, and the comment beside each one says what
# that takes. main records a failing step and runs the rest anyway, so one
# unreachable remote cannot cost you the other six, and it exits non-zero when
# any step failed, which is what a scheduled job reads.
#
# bootstrap.sh is sourced rather than copied from. Sourcing it runs nothing,
# and it already has what this needs: the output helpers, the `run` wrapper
# behind --dry-run, the tool probes, and the usage and validation helpers the
# entry point calls. Targets bash 3.2, the version macOS ships.

set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=./bootstrap.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap.sh"

# Ordered so a manager is upgraded before whatever runs under it: brew brings
# the new tmux, neovim, node, rustup and antidote, and the five steps after it
# update what those load. repo comes first, because a pull can change the
# config every later step reads.
#
# Not readonly. bash 3.2 scopes a readonly assignment in a sourced file to the
# function that sourced it, and tests/update_test.sh sources this from setup,
# where that would leave every test reading an empty list.
STEPS=(
  repo
  brew
  npm
  rust
  tmux
  neovim
  zsh
)

# Suffixed, unlike the BREW and NPM inherited from bootstrap, because NVIM is
# already taken: Neovim exports it inside a :terminal buffer, pointing at that
# instance's socket, and a :terminal is exactly where this gets run.
GIT_BIN="${GIT_BIN:-git}"
NVIM_BIN="${NVIM_BIN:-nvim}"
ZSH_BIN="${ZSH_BIN:-zsh}"

# Parsers build from source, so the run after a plugin update is minutes rather
# than seconds. The bound only exists so an unattended run cannot wait forever.
readonly TREESITTER_TIMEOUT_MS=900000

GREEDY=false
FAILED=()

#######################################
# Tool probes
#######################################

# antidote is a set of zsh functions rather than a binary, so this finds the
# directory to run rather than a command to call. The candidates mirror
# .zshrc's own probe: a Homebrew formula on macOS, a git clone under XDG data
# anywhere else.
antidote_dir() {
  local candidate
  for candidate in \
    "$(homebrew_prefix)/opt/antidote/share/antidote" \
    "${XDG_DATA_HOME:-${HOME}/.local/share}/antidote"; do
    if [[ -r "${candidate}/antidote.zsh" ]]; then
      printf '%s' "${candidate}"
      return 0
    fi
  done
  return 1
}

# The npm packages bootstrap declares, read out of its own declarations so the
# two lists cannot drift. tests/bootstrap_test.sh reads them the same way.
declared_npm_globals() {
  grep -oE '^[[:space:]]*npm_global[[:space:]]+[^[:space:]]+' \
    "${DOTFILES_DIR}/bootstrap.sh" | awk '{print $2}'
}

#######################################
# Steps, in STEPS order
#######################################

# Every stowed file is a symlink into this repo, so a pull updates the live
# configs immediately. It cannot install what the new commits added, because
# installing is bootstrap's job, so this says so instead of running it.
step_repo() {
  step "repo"
  local before after count

  if [[ ! -d "${DOTFILES_DIR}/.git" ]]; then
    skip "not a git checkout, nothing to pull"
    return 0
  fi
  # A pull across local edits either refuses or rewrites them, and there is
  # nobody here to choose, so an edited checkout is left exactly as it is.
  if [[ -n "$("${GIT_BIN}" -C "${DOTFILES_DIR}" status --porcelain)" ]]; then
    warn "uncommitted changes, leaving the repo alone"
    return 0
  fi
  if ! "${GIT_BIN}" -C "${DOTFILES_DIR}" rev-parse '@{u}' >/dev/null 2>&1; then
    skip "no upstream branch, nothing to pull"
    return 0
  fi

  before="$("${GIT_BIN}" -C "${DOTFILES_DIR}" rev-parse HEAD)"
  info "pulling ${DOTFILES_DIR}"
  # --ff-only, because a merge needs an editor and a decision, and this run has
  # neither.
  run "${GIT_BIN}" -C "${DOTFILES_DIR}" pull --ff-only --quiet || return 1
  did_run || return 0

  after="$("${GIT_BIN}" -C "${DOTFILES_DIR}" rev-parse HEAD)"
  if [[ "${before}" == "${after}" ]]; then
    success "already up to date"
    return 0
  fi
  count="$("${GIT_BIN}" -C "${DOTFILES_DIR}" rev-list --count \
    "${before}..${after}")"
  success "pulled ${count} commit(s)"
  warn "run 'bash bootstrap.sh' to install anything they added"
}

step_brew() {
  step "homebrew"
  local status=0

  if ! command -v "${BREW}" >/dev/null 2>&1; then
    skip "homebrew is not installed"
    return 0
  fi

  # Ask mode is Homebrew 6's default for upgrade, and it prompts as soon as the
  # plan reaches past the package named, which one dependency is enough to do.
  export HOMEBREW_NO_ASK=1

  # A cask that installs from a .pkg wants a password, and --greedy is not the
  # only way to reach one. Homebrew runs `sudo -A` when SUDO_ASKPASS is set, so
  # an askpass that cannot answer turns that prompt into a failure this run can
  # report instead of a wait that never ends. Only with no terminal. Run by
  # hand, answering the prompt is the point.
  if [[ ! -t 0 ]]; then
    export SUDO_ASKPASS=/usr/bin/false
  fi

  run "${BREW}" update --quiet || status=1
  # Having just updated deliberately, stop brew updating again mid-run, so
  # every upgrade below resolves against the index this run started with.
  export HOMEBREW_NO_AUTO_UPDATE=1
  run "${BREW}" upgrade || status=1

  if [[ "${GREEDY}" == true ]]; then
    # Casks that declare auto_updates ship their own updater, and `brew
    # upgrade` leaves them alone rather than overwrite it, so brew's record of
    # them drifts from what is on disk until this re-syncs it. Occasionally is
    # enough for that, and it re-downloads every one of them, hence the flag.
    run "${BREW}" upgrade --cask --greedy || status=1
  fi

  # Housekeeping, after the upgrades rather than before, because that is what
  # leaves the outdated versions and the newly orphaned dependencies behind.
  # autoremove only takes dependencies nothing still needs; everything
  # bootstrap declares was installed on request and is exempt.
  run "${BREW}" autoremove || status=1
  run "${BREW}" cleanup || status=1
  # doctor reports rather than fixes, and exits non-zero for any warning at
  # all, which a machine with third-party taps and a work tooling bundle on
  # PATH always has. Printing what it found is useful; failing the run over it
  # would make the exit status this script hands a scheduled job meaningless.
  run "${BREW}" doctor || warn "brew doctor had something to say, above"
  return "${status}"
}

step_npm() {
  step "npm"
  local packages

  if ! command -v "${NPM}" >/dev/null 2>&1; then
    skip "npm is not installed"
    return 0
  fi

  # Named, not a bare `npm update -g`, which takes every global on the machine.
  # Two of those are not this script's to touch: the npm inside Homebrew's node
  # keg, which brew owns and would then be tracking a version it did not
  # install, and anything installed by hand, which bootstrap does not know
  # about and should be made to declare rather than quietly maintained.
  packages="$(declared_npm_globals)"
  if [[ -z "${packages}" ]]; then
    warn "found no npm_global lines in bootstrap.sh; has the grep gone stale?"
    return 1
  fi
  info "updating the global packages bootstrap declares"
  # shellcheck disable=SC2086 # deliberately split into one argument per package
  run "${NPM}" update -g ${packages} || return 1
}

step_rust() {
  step "rust"
  local rustup

  # bootstrap's probe, so this upgrades the same rustup mod_runtimes installed.
  rustup="$(rustup_bin)" || {
    skip "rustup is not installed"
    return 0
  }

  info "updating the rust toolchain"
  # --no-self-update, because whoever installed rustup owns the binary: brew on
  # a personal machine, the work provisioning on a work one. Letting it replace
  # itself leaves that owner tracking a version it no longer controls.
  run "${rustup}" update --no-self-update || return 1
}

step_tmux() {
  step "tmux"
  local updater config="${XDG_CONFIG_HOME:-${HOME}/.config}"

  # Homebrew's tpm first, then a clone under the tmux config directory, which
  # is the same order tmux.conf uses to source it.
  updater="$(first_executable \
    "$(homebrew_prefix)/opt/tpm/share/tpm/bin/update_plugins" \
    "${config}/tmux/plugins/tpm/bin/update_plugins")" || {
    skip "tpm is not installed"
    return 0
  }

  info "updating tmux plugins (tpm)"
  # Only what is already cloned, because tpm installs nothing. A plugin new to
  # tmux.conf still needs prefix + I once. It reads the list through tmux but
  # needs no session of its own, and leaves the running ones alone.
  run "${updater}" all || return 1
}

# Two runs, not one. The second loads the plugin code the first installed,
# which matters for tree-sitter, because nvim-treesitter only supports the
# parser versions pinned by the copy of itself that compiles them.
step_neovim() {
  step "neovim"
  local status=0
  local plugins parsers

  if ! command -v "${NVIM_BIN}" >/dev/null 2>&1; then
    skip "neovim is not installed"
    return 0
  fi

  info "updating plugins (vim.pack)"
  # force, because the default opens a confirmation buffer for a human to read
  # and :write, and headless has no human.
  #
  # A plugin that fails to fetch does not raise. vim.pack records the error on
  # the plugin, appends it to nvim-pack.log under an `# Error` heading, and
  # returns normally. Without reading that back, a failed update reaches
  # neither stdout nor the exit status, which is the one thing a scheduled job
  # has to be able to see. The log only ever grows, so the lines past the count
  # taken first are this run's.
  plugins="local log = vim.fn.stdpath('log') .. '/nvim-pack.log'; "
  plugins+="local read = function() "
  plugins+="return vim.fn.filereadable(log) == 1 "
  plugins+="and vim.fn.readfile(log) or {} end; "
  plugins+="local seen = #read(); "
  plugins+="vim.pack.update(nil, { force = true }); "
  plugins+="local added = vim.list_slice(read(), seen + 1); "
  plugins+="if vim.iter(added):any(function(l) return l:find('^# Error') end) "
  plugins+="then error('a plugin failed to update, see ' .. log) end"
  nvim_lua "${plugins}" || status=1

  info "updating tree-sitter parsers"
  # Its own pcall guards it, because nvim-treesitter is a plugin like any
  # other. On a machine where it has not been installed yet, a bare require
  # would fail the step over something that is not an error. Its update returns
  # false when a parser fails to compile, and that return is the only signal.
  # The summary it prints says 198/200 and the process still exits 0.
  parsers="local has_ts, ts = pcall(require, 'nvim-treesitter'); "
  parsers+="if not has_ts then return end; "
  parsers+="if not ts.update(nil, { summary = true })"
  parsers+=":wait(${TREESITTER_TIMEOUT_MS}) then "
  parsers+="error('some tree-sitter parsers failed to build') end"
  nvim_lua "${parsers}" || status=1
  return "${status}"
}

# Runs one Lua chunk in a headless Neovim.
#
# The chunk ends the session itself rather than leaving it to a trailing -c
# 'qa'. A failing -c aborts the ones after it, so that trailing quit is the
# first thing an error would skip, and headless has no UI to notice. The editor
# would wait for a keypress that never comes. pcall turns the error into a cq
# instead, which both ends the process and gives the step a status to report.
nvim_lua() {
  local chunk="$1"
  local wrapped

  wrapped="local ok, err = pcall(function() ${chunk} end); "
  wrapped+="if not ok then io.stderr:write(tostring(err), '\n') end; "
  wrapped+="vim.cmd(ok and 'qa!' or 'cq!')"
  run "${NVIM_BIN}" --headless -c "lua ${wrapped}"
}

step_zsh() {
  step "zsh"
  local dir plugins

  dir="$(antidote_dir)" || {
    skip "antidote is not installed"
    return 0
  }
  if ! command -v "${ZSH_BIN}" >/dev/null 2>&1; then
    skip "zsh is not installed"
    return 0
  fi

  info "updating plugin bundles (antidote)"
  # Through zsh, because antidote is zsh functions and this is bash.
  # --bundles skips the self-update half. A Homebrew install cannot self-update
  # and says so in two lines on every run, and where antidote is a git clone
  # instead, updating the manager is not what this step is for.
  run "${ZSH_BIN}" "${dir}/antidote" update --bundles || return 1

  # Fetching updates the clones; the static bundle .zshrc sources is generated
  # from what is on disk, and an updated plugin can add a file it does not
  # source yet. Touching the plugin list makes .zshrc rebuild the bundle on the
  # next shell, which is one line here instead of a second copy of its careful
  # two-pass build.
  plugins="${ZDOTDIR:-${HOME}/.config/zsh}/.zsh_plugins.txt"
  if [[ -e "${plugins}" ]]; then
    run touch "${plugins}"
    did_run && success "the bundle rebuilds on the next shell"
  fi
  return 0
}

#######################################
# Entry point
#######################################

usage() { usage_from "${BASH_SOURCE[0]}"; }

known_steps() { names_with_prefix step_; }

# Returns 10 when a flag has already printed what was asked for, 1 on a bad one.
parse_args() {
  local arg

  REQUESTED=()
  for arg in "$@"; do
    case "${arg}" in
      --dry-run) DRY_RUN=true ;;
      --greedy) GREEDY=true ;;
      --list)
        printf 'steps:\n'
        printf '  %s\n' "${STEPS[@]}"
        return 10
        ;;
      -h | --help)
        usage
        return 10
        ;;
      -*)
        error "unknown flag: ${arg}"
        return 1
        ;;
      *) REQUESTED+=("${arg}") ;;
    esac
  done
}

validate_steps() { validate_names step_ step "$@"; }

main() {
  local parse_status=0
  local to_run name

  parse_args "$@" || parse_status=$?
  ((parse_status == 10)) && return 0
  ((parse_status != 0)) && return "${parse_status}"

  to_run=("${STEPS[@]}")
  ((${#REQUESTED[@]})) && to_run=("${REQUESTED[@]}")
  validate_steps "${to_run[@]}" || return 1

  step "preflight"
  if [[ "$(uname)" != Darwin ]]; then
    error "macOS only for now."
    return 1
  fi
  success "repo at ${DOTFILES_DIR}"
  [[ "${DRY_RUN}" == true ]] && warn "dry run, changing nothing"

  # launchd and cron hand a job PATH=/usr/bin:/bin:/usr/sbin:/sbin, which has
  # no Homebrew on it, and every step below looks for its tool by name or under
  # the Homebrew prefix. Without this, six of the seven skip and the run still
  # exits 0, so the job log reads exactly like a machine that is up to date.
  brew_shellenv || warn "no Homebrew found; most steps will skip"

  # A prompt nobody is there to answer is a hung job rather than a failed one,
  # and four steps reach git over the network: repo directly, and tmux, neovim
  # and zsh through their plugin managers.
  export GIT_TERMINAL_PROMPT=0
  # git's own variable covers its credential prompt and nothing else. A key
  # passphrase or an unknown host key is ssh asking, and origin here is ssh.
  export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes"

  FAILED=()
  for name in "${to_run[@]}"; do
    # Calling it as a condition keeps errexit out of the way, so one failing
    # step reports itself and the rest of the run still happens.
    if ! "step_${name}"; then
      error "${name} failed"
      FAILED+=("${name}")
    fi
  done

  printf '\n'
  if ((${#FAILED[@]})); then
    printf '%s%sFailed:%s %s\n' "${RED}" "${BOLD}" "${RESET}" "${FAILED[*]}"
    return 1
  fi
  printf '%s%sDone.%s Ran: %s\n' "${GREEN}" "${BOLD}" "${RESET}" "${to_run[*]}"
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
