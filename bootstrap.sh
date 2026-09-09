#!/bin/bash
#
# Provision a macOS machine from this dotfiles repo.
#
# Usage:
#   bash bootstrap.sh                # run every module listed in MODULES
#   bash bootstrap.sh zsh neovim     # run only these modules
#   bash bootstrap.sh --list         # print the enabled modules
#   bash bootstrap.sh --modules      # print every module this script defines
#   bash bootstrap.sh --dry-run      # print what would happen, change nothing
#   bash bootstrap.sh --no-update    # skip `brew update` (faster re-runs)
#   bash bootstrap.sh --profile=work # personal or work; asked once, remembered
#   bash bootstrap.sh --help
#
# A module installs the tools for one area and symlinks their config with GNU
# stow. Modules are idempotent, so re-running only does outstanding work.
#
# When adding a tool, declare it in a module rather than installing it by hand,
# and give every stow_package line a matching install line. A stowed config
# whose binary is missing fails silently at the point of use.
#
# Sourcing this file defines its functions without running anything, and the
# tools it drives (BREW, STOW, NPM, GIT) and paths it reads or writes
# (DOTFILES_DIR, STOW_TARGET, BREW_PREFIXES) are overridable, so tests can stub
# them. See
# tests/bootstrap_test.sh. Targets bash 3.2, the version macOS ships.

set -euo pipefail

# Ordered so that a module only runs once whatever it relies on is present:
# system defaults first, then stow, then the standalone tools, then the modules
# whose configs call those tools.
readonly MODULES=(
  macos         # system defaults
  apps          # desktop applications
  core          # stow, which every stowing module below needs
  cli           # fd, fzf, ripgrep, jq and friends
  files         # yazi, and the decoders it previews with
  gittools      # git, gh, delta
  terminal      # ghostty
  atuin         # shell history
  multiplexer   # tmux, herdr
  runtimes      # node, which mod_neovim's npm language servers run on
  neovim        # nvim, its GUI, the servers and formatters it drives, ideavim
  windowmanager # aerospace, sketchybar, borders; sketchybar needs jq
  agents        # coding-agent CLIs
  zsh           # shell; .zshrc initialises most of the tools above
)

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# The same path with symlinks resolved. displace_conflicts compares `pwd -P`
# output against it, and on macOS /tmp and /var are themselves symlinks, so a
# repo reached through one would fail that comparison and the script would move
# its own files into the backup directory.
DOTFILES_PHYSICAL="$(cd "${DOTFILES_DIR}" 2>/dev/null && pwd -P)"
DOTFILES_PHYSICAL="${DOTFILES_PHYSICAL:-${DOTFILES_DIR}}"
STOW_TARGET="${STOW_TARGET:-${HOME}}"
BREW="${BREW:-brew}"
STOW="${STOW:-stow}"
NPM="${NPM:-npm}"
GIT="${GIT:-git}"
# Space-separated so a test can point the probe at a scratch prefix instead of
# running the real /opt/homebrew/bin/brew.
BREW_PREFIXES="${BREW_PREFIXES:-/opt/homebrew /usr/local}"

DRY_RUN=false
SKIP_UPDATE=false
REQUESTED=()

# personal or work. Work machines need overrides this repo deliberately does
# not carry: a commit identity, and employer-specific shell settings. Chosen
# with --profile, remembered here, so later runs need no flag.
PROFILE=""
PROFILE_FILE="${PROFILE_FILE:-${HOME}/.config/dotfiles/profile}"

#######################################
# Output
#######################################

if [[ -t 1 ]]; then
  readonly RED=$'\033[0;31m'
  readonly GREEN=$'\033[0;32m'
  readonly YELLOW=$'\033[1;33m'
  readonly BLUE=$'\033[0;34m'
  readonly BOLD=$'\033[1m'
  readonly RESET=$'\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

info() {
  printf '%s==>%s %s%s%s\n' "${BLUE}" "${RESET}" "${BOLD}" "$*" "${RESET}"
}
success() { printf '%s  ✓%s %s\n' "${GREEN}" "${RESET}" "$*"; }
skip() { printf '   ·  %s\n' "$*"; }
warn() { printf '%s  !%s %s\n' "${YELLOW}" "${RESET}" "$*"; }
error() { printf '%s  ✗%s %s\n' "${RED}" "${RESET}" "$*" >&2; }

step() {
  printf '\n%s── %s %s%s\n' \
    "${BOLD}" "$*" "$(printf '─%.0s' {1..40})" "${RESET}"
}

# Runs a command, or describes it under --dry-run.
run() {
  if [[ "${DRY_RUN}" == true ]]; then
    printf '   →  %s\n' "$*"
  else
    "$@"
  fi
}

# False under --dry-run, so success messages cannot claim a change that the run
# never made.
did_run() {
  [[ "${DRY_RUN}" != true ]]
}

# Reads the remembered profile. A pure getter. resolve_profile does the asking,
# because this is called from inside "$(...)" where a failure could not stop the
# script.
profile() {
  if [[ -z "${PROFILE}" && -r "${PROFILE_FILE}" ]]; then
    PROFILE="$(<"${PROFILE_FILE}")"
  fi
  printf '%s' "${PROFILE}"
}

# Establishes the profile before any module runs. Never guesses, because the
# profile decides whether employer-managed apps get installed or removed, so a
# wrong default does real work in the wrong direction.
resolve_profile() {
  # Assign directly rather than through "$(profile)", because a subshell's
  # assignment would not reach this shell, leaving PROFILE empty for every later
  # reader.
  if [[ -z "${PROFILE}" && -r "${PROFILE_FILE}" ]]; then
    PROFILE="$(<"${PROFILE_FILE}")"
  fi
  if [[ -n "${PROFILE}" ]]; then
    success "profile: ${PROFILE}"
    return 0
  fi

  if [[ ! -t 0 ]]; then
    error "no profile set. Pass --profile=personal or --profile=work."
    return 1
  fi

  local answer
  while true; do
    printf 'Is this a personal or work machine? [personal/work] ' >&2
    read -r answer || {
      printf '\n' >&2
      error "no profile chosen."
      return 1
    }
    case "${answer}" in
      p | personal)
        PROFILE=personal
        break
        ;;
      w | work)
        PROFILE=work
        break
        ;;
      *) warn "answer 'personal' or 'work'." ;;
    esac
  done
  remember_profile
}

remember_profile() {
  [[ "${DRY_RUN}" == true ]] && return 0
  mkdir -p "$(dirname "${PROFILE_FILE}")"
  printf '%s\n' "${PROFILE}" >"${PROFILE_FILE}"
  success "profile: ${PROFILE} (remembered in ~${PROFILE_FILE#"${HOME}"})"
}

usage() {
  sed -n '/^# Usage:/,/^# *bash bootstrap.sh --help$/p' "${BASH_SOURCE[0]}" \
    | sed 's/^# \{0,1\}//'
}

#######################################
# Installed-package index
#######################################

# `brew list <name>` costs ~0.35s of Ruby startup and this script asks about
# ~50 packages; listing everything once costs ~0.02s. Newline-delimited strings
# rather than associative arrays, which bash 3.2 lacks.
INSTALLED_FORMULAE=''
INSTALLED_CASKS=''
INSTALLED_TAPS=''
INSTALLED_TRUSTED=''
INSTALLED_NPM=''
INDEX_LOADED=false

load_package_index() {
  [[ "${INDEX_LOADED}" == true ]] && return 0

  INSTALLED_FORMULAE="$("${BREW}" list --formula 2>/dev/null || true)"
  INSTALLED_CASKS="$("${BREW}" list --cask 2>/dev/null || true)"
  INSTALLED_TAPS="$("${BREW}" tap 2>/dev/null || true)"
  # JSON, not a plain list, because `brew trust` has no line-oriented output.
  # The check below matches it as a quoted substring rather than parsing it,
  # which keeps this free of a jq dependency that mod_cli has not installed yet
  # on a fresh machine.
  INSTALLED_TRUSTED="$("${BREW}" trust --json v1 2>/dev/null || true)"
  if command -v "${NPM}" >/dev/null 2>&1; then
    # Paths arrive as .../node_modules/<name> or .../node_modules/@scope/name.
    INSTALLED_NPM="$("${NPM}" ls -g --depth=0 --parseable 2>/dev/null \
      | sed -e 's|.*/node_modules/||' || true)"
  fi
  INDEX_LOADED=true
}

# Whether $2 appears as a whole line in the newline-delimited list $1.
listed() {
  case $'\n'"$1"$'\n' in
    *$'\n'"$2"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}

# Records a just-installed package so a later module skips it without
# re-querying brew. $1 is one of formula, cask, tap, npm.
remember() {
  case "$1" in
    formula) INSTALLED_FORMULAE="${INSTALLED_FORMULAE}"$'\n'"$2" ;;
    cask) INSTALLED_CASKS="${INSTALLED_CASKS}"$'\n'"$2" ;;
    tap) INSTALLED_TAPS="${INSTALLED_TAPS}"$'\n'"$2" ;;
    npm) INSTALLED_NPM="${INSTALLED_NPM}"$'\n'"$2" ;;
  esac
}

#######################################
# Package helpers
#######################################

# $1 may be tap-qualified. `brew install` wants the qualified name, `brew list`
# reports the bare one.
brew_formula() {
  local spec="$1"
  local name="${1##*/}"

  load_package_index
  if listed "${INSTALLED_FORMULAE}" "${name}"; then
    skip "${name}"
    return 0
  fi
  info "installing ${spec}"
  run "${BREW}" install "${spec}"
  remember formula "${name}"
  success "${name}"
}

# $2 is an optional app bundle, e.g. 'Google Chrome.app'. If it is already in
# /Applications this skips the cask, because the app arrived some other way,
# typically pushed by an employer's device management, and installing over it
# fails outright while adopting it needs a sudo prompt no installer should
# spring.
brew_cask() {
  local spec="$1"
  local name="${1##*/}"
  local bundle="${2:-}"

  load_package_index
  if listed "${INSTALLED_CASKS}" "${name}"; then
    skip "${name} (cask)"
    return 0
  fi
  if [[ -n "${bundle}" && -d "/Applications/${bundle}" ]]; then
    skip "${name} (already installed outside brew)"
    return 0
  fi
  info "installing ${spec} (cask)"
  run "${BREW}" install --cask "${spec}"
  remember cask "${name}"
  success "${name} (cask)"
}

# rustup installs the toolchain manager, not a toolchain. Without an explicit
# default, cargo and rustc are shims that error on every call. That is the
# state a work machine's own provisioning leaves it in.
rust_toolchain() {
  local rustup candidate

  # Wanted on both machines, but rustup arrives differently on each: Homebrew's
  # is keg-only and never on PATH, while a work machine has it provisioned into
  # ~/.cargo/bin already. Take whichever exists.
  for candidate in \
    "$(homebrew_prefix)/opt/rustup/bin/rustup" \
    "${HOME}/.cargo/bin/rustup"; do
    if [[ -x "${candidate}" ]]; then
      rustup="${candidate}"
      break
    fi
  done
  [[ -n "${rustup:-}" ]] || return 0

  if "${rustup}" toolchain list 2>/dev/null | grep -q 'no installed toolchains'; then
    info "installing the default Rust toolchain (this downloads ~1GB)"
    run "${rustup}" default stable
    success "rust toolchain installed"
  else
    skip "rust toolchain already installed"
  fi

  # rustfmt and clippy come with the default profile; rust-analyzer does not,
  # and nvim's config enables it.
  if "${rustup}" component list --installed 2>/dev/null | grep -q '^rust-analyzer'; then
    skip "rust-analyzer"
    return 0
  fi
  run "${rustup}" component add rust-analyzer
  success "rust-analyzer"
}

# A CLI the employer's tooling bundle already puts on PATH in /usr/local/bin.
# Homebrew's copy sits earlier on PATH and would shadow it, so a work machine
# would silently run a different version from the one its tooling was tested
# against. Under the work profile the formula is left to the bundle, and a brew
# copy from an earlier run is removed so it stops shadowing.
personal_formula() {
  local spec="$1"
  local name="${1##*/}"

  if [[ "$(profile)" != work ]]; then
    brew_formula "${spec}"
    return 0
  fi

  load_package_index
  if listed "${INSTALLED_FORMULAE}" "${name}"; then
    info "removing ${name} — provided by the work tooling bundle"
    run "${BREW}" uninstall "${spec}"
    success "removed ${name}"
    return 0
  fi
  skip "${name} (provided by the work tooling bundle)"
}

# A cask the employer's device management owns on a work machine. Installing it
# there would fight the managed copy and its update channel, so under the work
# profile it is never installed, and a brew copy from an earlier run, or from
# a machine that later became managed, is removed.
personal_cask() {
  local spec="$1"
  local name="${1##*/}"
  local bundle="${2:-}"

  if [[ "$(profile)" != work ]]; then
    brew_cask "${spec}" "${bundle}"
    return 0
  fi

  load_package_index
  if listed "${INSTALLED_CASKS}" "${name}"; then
    info "removing ${name} (cask) — managed on work machines"
    run "${BREW}" uninstall --cask "${spec}"
    success "removed ${name} (cask)"
    return 0
  fi
  skip "${name} (managed on work machines)"
}

brew_tap() {
  local tap="$1"

  load_package_index
  if listed "${INSTALLED_TAPS}" "${tap}"; then
    skip "${tap} (tap)"
    return 0
  fi
  info "tapping ${tap}"
  run "${BREW}" tap "${tap}"
  remember tap "${tap}"
  success "${tap} (tap)"
}

# Homebrew 6 refuses to load a formula or cask from a third-party tap until it
# is trusted. $1 is --formula or --cask, $2 the fully qualified name.
brew_trust() {
  local kind="$1"
  local name="$2"

  load_package_index
  case "${INSTALLED_TRUSTED}" in
    *"\"${name}\""*)
      skip "${name} (trusted)"
      return 0
      ;;
  esac
  info "trusting ${name}"
  run "${BREW}" trust "${kind}" "${name}"
  INSTALLED_TRUSTED="${INSTALLED_TRUSTED}"$'\n'"\"${name}\""
  success "${name} (trusted)"
}

npm_global() {
  local pkg="$1"

  if ! command -v "${NPM}" >/dev/null 2>&1; then
    warn "npm is not on PATH — skipping ${pkg}"
    return 0
  fi
  load_package_index
  if listed "${INSTALLED_NPM}" "${pkg}"; then
    skip "${pkg} (npm)"
    return 0
  fi
  info "installing ${pkg} (npm)"
  run "${NPM}" install -g "${pkg}"
  remember npm "${pkg}"
  success "${pkg} (npm)"
}

# Puts an already-installed Homebrew on PATH. Both prefixes are probed rather
# than assuming Apple Silicon, and eval is how brew publishes its environment --
# there is no non-eval form.
# Returns:
#   1 if no brew was found at either prefix.
brew_shellenv() {
  local prefix
  # shellcheck disable=SC2086 # word splitting is how the list is iterated
  for prefix in ${BREW_PREFIXES}; do
    if [[ -x "${prefix}/bin/brew" ]]; then
      eval "$("${prefix}/bin/brew" shellenv)"
      return 0
    fi
  done
  return 1
}

# Cached, because `brew --prefix` is another 0.35s of Ruby startup.
homebrew_prefix() {
  if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
    HOMEBREW_PREFIX="$("${BREW}" --prefix 2>/dev/null || true)"
  fi
  printf '%s' "${HOMEBREW_PREFIX}"
}

#######################################
# Stow
#######################################

# Where displaced files go, one directory per run. Deliberately not a sibling
# of the file it replaces. When a parent directory is already a folded stow
# symlink into the repo, a backup written beside the target lands inside the
# package itself.
backup_dir() {
  if [[ -z "${BACKUP_DIR:-}" ]]; then
    BACKUP_DIR="${STOW_TARGET}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  fi
  printf '%s' "${BACKUP_DIR}"
}

# Paths a package would create, relative to the stow target.
#
# Tracked files only, because stow links what git tracks, so only those can
# conflict. Listing with find would also match runtime state a tool writes into
# its own package directory through a folded symlink, such as herdr's
# session.json and logs, and displace_conflicts would move that live state
# aside.
# Falls back to find when the repo is not a git checkout, such as a tarball
# download or the scratch directories the tests build.
package_files() {
  local pkg="$1"

  [[ -d "${DOTFILES_DIR}/${pkg}" ]] || return 0
  (
    cd "${DOTFILES_DIR}/${pkg}" || return 0
    git ls-files 2>/dev/null \
      || find . -type f ! -name '*.pre-stow*' | sed 's|^\./||'
  )
}

# Moves real files aside so stow can take their place. A fresh macOS ships its
# own ~/.zshenv, and an app may write a default config before it is stowed.
displace_conflicts() {
  local pkg="$1"
  local target live resolved dest

  while IFS= read -r target; do
    [[ -n "${target}" ]] || continue
    live="${STOW_TARGET}/${target}"
    [[ -e "${live}" ]] || continue
    [[ -L "${live}" ]] && continue

    # A folded parent symlink makes ${live} resolve back into the package, so
    # moving it would destroy the file being stowed.
    resolved="$(cd "$(dirname "${live}")" && pwd -P)/$(basename "${live}")"
    case "${resolved}" in
      "${DOTFILES_PHYSICAL}"/*) continue ;;
    esac

    dest="$(backup_dir)/${target}"
    warn "${target} exists — backing up to ${dest#"${STOW_TARGET}"/}"
    run mkdir -p "$(dirname "${dest}")"
    run mv "${live}" "${dest}"
  done < <(package_files "${pkg}")
}

stow_package() {
  local pkg="$1"

  if [[ ! -d "${DOTFILES_DIR}/${pkg}" ]]; then
    warn "no such package: ${pkg}"
    return 0
  fi
  displace_conflicts "${pkg}"
  # --no-folding links each file rather than symlinking a whole directory. A
  # folded directory is the repo, so anything a tool writes beside its config,
  # such as logs, sockets or session state, lands in version control.
  # --ignore keeps Finder's .DS_Store out. It is gitignored, but stow scans the
  # filesystem rather than git, so an untracked one still gets linked, and
  # colliding with an existing ~/.DS_Store aborts the whole package.
  run "${STOW}" --dir "${DOTFILES_DIR}" --target "${STOW_TARGET}" \
    --ignore='\.DS_Store' --no-folding --restow "${pkg}"
  if did_run; then
    success "stowed ${pkg}"
  fi
}

#######################################
# Modules, in MODULES order
#######################################

# macos/ is run, not stowed.
mod_macos() {
  step "macOS defaults"
  info "applying macos/defaults.bash (Dock and Finder will restart)"
  run bash "${DOTFILES_DIR}/macos/defaults.bash"
  success "defaults written"
}

mod_apps() {
  step "applications"
  personal_cask 1password '1Password.app'
  personal_cask affinity 'Affinity.app'
  brew_cask alfred 'Alfred 5.app'
  personal_cask brave-browser 'Brave Browser.app'
  personal_cask chatgpt 'ChatGPT.app'
  personal_cask claude 'Claude.app'
  brew_cask cleanshot 'CleanShot X.app'
  personal_cask discord 'Discord.app'
  personal_cask docker-desktop 'Docker.app'
  personal_cask figma 'Figma.app'
  personal_cask firefox 'Firefox.app'
  personal_cask google-chrome 'Google Chrome.app'
  brew_cask handy 'Handy.app'
  brew_cask iina 'IINA.app'
  brew_cask imageoptim 'ImageOptim.app'
  personal_cask nordvpn 'NordVPN.app'
  brew_cask obsidian 'Obsidian.app'
  personal_cask slack 'Slack.app'
  personal_cask spotify 'Spotify.app'
  personal_cask telegram 'Telegram.app'
  personal_cask whatsapp 'WhatsApp.app'
  personal_cask zoom 'zoom.us.app'
}

mod_core() {
  step "core"
  brew_formula stow
}

mod_cli() {
  step "command-line tools"
  brew_formula bat
  brew_formula btop
  personal_formula direnv
  brew_formula eza
  brew_formula fd
  brew_formula ffmpeg
  brew_formula fzf
  brew_formula jq
  brew_formula ripgrep
  brew_formula shellcheck
  personal_formula uv
  brew_formula vivid
  brew_formula zoxide
  stow_package bat
  stow_package btop
  stow_package fd
  stow_package fzf
}

mod_files() {
  step "file manager"
  brew_formula yazi
  # Preview decoders. yazi shells out per file type and renders an empty pane
  # when one is missing rather than saying so, which reads as a yazi bug.
  brew_formula imagemagick # SVG, HEIC and font previews
  brew_formula poppler     # PDF previews
  brew_formula sevenzip    # archive listings
  # ffmpeg, for video thumbnails, and the fd/ripgrep/fzf/zoxide that back
  # yazi's find, search and jump commands, all come from mod_cli.
  stow_package yazi
}

# Work machines commit under a different identity. The git config includes
# config.work for anything under ~/work/, and git skips a missing include
# silently, so without this check, work commits go out under the personal
# address with nothing to notice.
require_work_gitconfig() {
  local target="${HOME}/.config/git/config.work" email

  if [[ -r "${target}" ]]; then
    skip "work git identity (~${target#"${HOME}"})"
    return 0
  fi
  if [[ "${DRY_RUN}" == true ]]; then
    printf '   →  create %s with the work commit identity\n' "${target}"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    warn "~${target#"${HOME}"} is missing — work repos will commit as the personal identity"
    return 0
  fi

  warn "~${target#"${HOME}"} is missing; work repos would commit as the personal identity"
  printf 'Work commit email (blank to skip): ' >&2
  read -r email
  if [[ -z "${email}" ]]; then
    warn "skipped; run again or write ~${target#"${HOME}"} by hand"
    return 0
  fi
  printf '[user]\n\temail = %s\n' "${email}" >"${target}"
  chmod 600 "${target}"
  success "wrote ~${target#"${HOME}"}"
}

# Creates the untracked local git config with an empty [maintenance] section.
#
# Deliberately registers nothing. `git maintenance register` writes an absolute
# repo path into whichever config it is handed, and the repos worth maintaining
# are employer-specific, so you fill the list in by hand on the machine that
# needs it, and this only puts the section there to hold it. Which repos are
# worth it is a judgement anyway. The tasks pay off on a repo with deep history
# and do nothing noticeable on a small one.
#
# The list has to be unconditional config rather than a gitdir-conditional
# include, because the launchd job runs `git for-each-repo
# --config=maintenance.repo` from outside any repo, where a conditional include
# never applies.
ensure_maintenance_section() {
  local target="${HOME}/.config/git/config.local"

  if grep -q '^\[maintenance\]' "${target}" 2>/dev/null; then
    skip "git maintenance section (~${target#"${HOME}"})"
    return 0
  fi
  if [[ "${DRY_RUN}" == true ]]; then
    printf '   →  add a [maintenance] section to %s\n' "${target}"
    return 0
  fi

  mkdir -p "$(dirname "${target}")"
  # Appended, because the file may already hold settings this script did not
  # write.
  printf '[maintenance]\n' >>"${target}"
  chmod 600 "${target}"
  success "added [maintenance] to ~${target#"${HOME}"}"
}

# Reports the untracked files a work machine is expected to have. This repo
# deliberately ships none of them, because they hold employer-specific
# settings, but they come from two different places, which the notes below spell
# out: the private overlay supplies some, and bootstrap itself writes the rest.
#
# None is required, because every config that reads one skips it when absent, so
# this is a checklist rather than a failure. It runs last so the answer is the
# final thing on screen, and unconditionally for the work profile. A partial run
# should still say what the machine is missing.
#
# Each path is the one the reading config actually opens, not where the file is
# conventionally kept. A copy anywhere else is silently ignored rather than
# reported here. No zsh entry any more, because the shell's only machine-local
# mechanism is $ZDOTDIR/functions, a directory the overlay stows into rather
# than a single file worth checking for.
report_overlay_files() {
  local entry path note missing=0

  step "untracked local files"
  for entry in \
    "${HOME}/.claude/CLAUDE.md|overlay: Canva coding guides and repo conventions" \
    "${HOME}/.claude/settings.json|overlay: work permissions, MCP allow/deny, plugins" \
    "${HOME}/.claude/statusline.zsh|overlay: work statusline" \
    "${HOME}/.config/aerospace/browser.local|overlay: the app alt-shift-b opens, Brave without it" \
    "${HOME}/.config/nvim/lua/local.lua|overlay: nvim eager roots, vendored formatter paths" \
    "${HOME}/.config/git/config.local|bootstrap writes: holds the git maintenance repo list" \
    "${HOME}/.config/git/config.work|bootstrap writes: git identity for repos under ~/work/"; do
    path="${entry%%|*}"
    note="${entry#*|}"
    if [[ -r "${path}" ]]; then
      success "~${path#"${HOME}"}  ${note}"
    else
      warn "~${path#"${HOME}"}  ${note} — MISSING"
      missing=$((missing + 1))
    fi
  done

  if ((missing)); then
    skip "${missing} missing — see the note on each"
  fi

  # ensure_maintenance_section leaves the section empty on purpose; say so out
  # loud, because an empty section otherwise reads as a bug.
  local maintenance="${HOME}/.config/git/config.local"
  if [[ -r "${maintenance}" ]] \
    && ! grep -qE '^[[:space:]]*repo[[:space:]]*=' "${maintenance}"; then
    warn "git maintenance has no repo registered. Add each one worth maintaining:"
    skip "git -C <repo> maintenance register --config-file ~/.config/git/config.local"
  fi
  return 0
}

mod_gittools() {
  step "git tooling"
  # Not a personal_formula, because the work tooling wrapper delegates to
  # whichever git is on PATH, so brew's copy is what it runs. Removing it drops
  # the wrapper back to Apple's older git rather than leaving the bundle's own.
  brew_formula git
  personal_formula gh
  # .gitconfig sets delta as the pager for diff/log/reflog/show and as
  # interactive.diffFilter, so all of those break without it.
  brew_formula git-delta
  # .gitconfig registers the lfs filter, so cloning or checking out a repo that
  # uses LFS fails without it.
  personal_formula git-lfs
  # Terminal diff viewer. Its config is stowed below, so declaring the binary
  # here is what keeps the pair together on a fresh machine.
  brew_formula hunk
  stow_package git
  stow_package hunk

  if [[ "$(profile)" == work ]]; then
    require_work_gitconfig
    ensure_maintenance_section
  fi
}

mod_terminal() {
  step "terminal"
  brew_cask ghostty 'Ghostty.app'
  # The ligature variant, not the NL one, so `font-feature = -calt` can switch
  # ligatures off without swapping fonts.
  brew_cask font-maple-mono-nf-cn
  stow_package ghostty
}

mod_atuin() {
  step "atuin"
  brew_formula atuin
  stow_package atuin
}

mod_multiplexer() {
  step "multiplexer"
  # Not a personal_formula, unlike most work-bundled tools, because tpm depends
  # on the tmux formula, so skipping it would install tmux as a dependency and
  # then remove it on the next run. Brew's copy shadows the bundle's, since
  # /opt/homebrew sits ahead of /usr/local on PATH, and it also gets a newer
  # tmux.
  brew_formula tmux
  brew_formula herdr
  stow_package tmux
  stow_package herdr

  # The formula provides tpm itself; the plugins it manages are cloned on first
  # launch into ~/.config/tmux/plugins, which tpm derives from the config path.
  # tmux.conf's last line runs it.
  brew_formula tpm
}

mod_runtimes() {
  step "runtimes"
  # Current node rather than a pinned node@N: pinned formulae are keg-only, so
  # they never put npm on PATH, and mod_neovim's language servers are npm
  # packages.
  #
  # Not a personal_formula, even though the work tooling bundle ships its own
  # node. That one's global module directory is root-owned, so `npm install -g`
  # fails against it and no language server can install.
  brew_formula node

  # rustup itself is personal-only, because a work machine's own provisioning
  # supplies one, but the toolchain setup runs on both, since neither source
  # installs a compiler on its own.
  personal_formula rustup
  rust_toolchain
}

mod_neovim() {
  step "neovim"
  brew_formula neovim
  brew_formula tree-sitter-cli # nvim-treesitter compiles parsers from source
  brew_cask neovide-app 'Neovide.app'

  # Language servers and formatters live here because nvim's config is the
  # only thing that drives them: conform.nvim calls the formatters by name,
  # and init.lua enables a server for each of the rest.
  brew_formula lua-language-server
  brew_formula buf # drives buf_ls via `buf lsp serve`
  brew_formula dprint
  brew_formula shfmt
  brew_formula stylua

  npm_global bash-language-server
  npm_global cssmodules-language-server
  npm_global stylelint-lsp
  # Must be 7 or newer, because only the native compiler speaks --lsp, which is
  # what the tsc server drives.
  npm_global typescript
  npm_global vscode-langservers-extracted # cssls, html, jsonls, eslint

  stow_package nvim
  stow_package neovide
  stow_package dprint
  stow_package stylua
  # JetBrains IDEs are not installed from here, but when one is present it
  # reads this. Kept close to nvim's config on purpose.
  stow_package ideavim
}

mod_windowmanager() {
  step "window management"
  brew_tap felixkratz/formulae
  brew_tap nikitabobko/tap
  brew_trust --formula felixkratz/formulae/sketchybar
  brew_trust --formula felixkratz/formulae/borders
  brew_trust --cask nikitabobko/tap/aerospace
  brew_formula felixkratz/formulae/sketchybar
  brew_formula felixkratz/formulae/borders
  brew_cask nikitabobko/tap/aerospace 'AeroSpace.app'
  stow_package aerospace
  stow_package sketchybar
}

mod_agents() {
  step "agents"
  # No bundle argument, because this cask ships a bare `claude` binary, not an
  # app, so the /Applications check cannot see the managed copy. personal_cask
  # keeps it off work machines, where /usr/local/bin/claude is managed and
  # newer.
  personal_cask claude-code
  brew_cask codex

  # ~/.claude is profile-exclusive rather than shared. The work machine's
  # CLAUDE.md, skills and permission lists are employer-specific, its statusline
  # talks to corporate GitHub, Buildkite and Jira, and permissions.allow merges
  # across scopes rather than overriding, so a shared base would leak entries
  # into work that work could never remove. The overlay supplies the whole
  # directory there instead.
  #
  # hooks/ is absent on purpose, because herdr installs its own hook and
  # overwrites it on every integration update, so tracking it would churn this
  # repo with herdr's version bumps.
  if [[ "$(profile)" == work ]]; then
    skip "claude config (the overlay supplies it on work machines)"
  else
    stow_package claude
  fi
}

mod_zsh() {
  step "zsh"
  # Homebrew's zsh, not /bin/zsh, because macOS pins 5.9 and will not update it.
  brew_formula zsh
  # antidote compiles $ZDOTDIR/.zsh_plugins.txt into a static bundle on first
  # start. .zshrc skips its whole plugin block when the formula is absent.
  brew_formula antidote

  stow_package zsh

  set_login_shell
}

# Editing /etc/shells needs root and chsh asks for a password, so both prompts
# are announced first. A refusal only warns, because a managed machine may
# restrict sudo or hold the user record in a configuration profile, and
# everything else here works fine on the system zsh.
set_login_shell() {
  local shell_path current

  shell_path="$(homebrew_prefix)/bin/zsh"
  if [[ ! -x "${shell_path}" ]]; then
    warn "${shell_path} is missing — leaving the login shell alone"
    return 0
  fi

  # Not $SHELL: it is inherited from login and stays stale for the rest of the
  # session after chsh, which makes it look as though nothing happened.
  current="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null \
    | awk '{print $2}')"
  if [[ "${current}" == "${shell_path}" ]]; then
    success "login shell is already ${shell_path}"
    return 0
  fi

  if ! grep -qxF "${shell_path}" /etc/shells; then
    warn "adding ${shell_path} to /etc/shells — sudo will ask for a password"
    if ! run sudo sh -c "printf '%s\n' '${shell_path}' >> /etc/shells"; then
      warn "could not write /etc/shells; login shell left as ${current}"
      return 0
    fi
  fi

  # chsh rejects any shell absent from /etc/shells, so there is no point trying
  # when the step above failed.
  warn "switching login shell — chsh will ask for your password"
  if run chsh -s "${shell_path}"; then
    if did_run; then
      success "login shell set to ${shell_path} — open a new terminal for it"
    fi
  else
    warn "chsh failed; login shell left as ${current}"
  fi
}

#######################################
# Homebrew
#######################################

# A managed machine already has Homebrew and this is a no-op. A personal Mac
# does not, and the official installer pulls in the Xcode command-line tools
# first and prompts once for sudo.
# Returns:
#   1 if brew could not be put on PATH.
install_homebrew() {
  # An install can exist without being on this shell's PATH. A login shell
  # started before the zsh package was stowed carries no /opt/homebrew. Testing
  # PATH alone would reinstall Homebrew over a working copy.
  brew_shellenv || true

  if command -v "${BREW}" >/dev/null 2>&1; then
    success "Homebrew already installed"
  elif [[ "${DRY_RUN}" == true ]]; then
    printf '   →  install Homebrew from https://brew.sh (prompts for sudo)\n'
    return 0
  else
    info "installing Homebrew — this asks for confirmation and your password"
    # Not wrapped in run(), because the command substitution would download the
    # installer even when run() only prints the command.
    /bin/bash -c "$(curl -fsSL \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # A fresh install is not on this shell's PATH either.
    brew_shellenv || true
  fi

  if ! command -v "${BREW}" >/dev/null 2>&1; then
    error "Homebrew is still not on PATH. Install it: https://brew.sh"
    return 1
  fi
  success "Homebrew $("${BREW}" --version | head -1 | awk '{print $2}') at \
$(homebrew_prefix)"

  if [[ "${SKIP_UPDATE}" == true ]]; then
    skip "brew update (--no-update)"
  else
    # No info() line, because `brew update` prints its own "==> Updating
    # Homebrew..." even under --quiet, and two near-identical lines read like it
    # ran twice.
    run "${BREW}" update --quiet
  fi

  # Having just updated deliberately, stop brew updating again mid-run, because
  # a later install would otherwise resolve against a different formula index
  # than the one this run started with.
  export HOMEBREW_NO_AUTO_UPDATE=1

  # Ask mode is Homebrew 6's default for install, upgrade and reinstall. It
  # prompts whenever the plan reaches past the package named, which a single
  # dependency is enough to trigger. This script has to run unattended.
  export HOMEBREW_NO_ASK=1
}

#######################################
# Entry point
#######################################

known_modules() {
  compgen -A function mod_ | sed 's/^mod_//' | sort
}

# Returns 10 when a flag has already printed what was asked for, 1 on a bad one.
parse_args() {
  local arg

  REQUESTED=()
  for arg in "$@"; do
    case "${arg}" in
      --dry-run) DRY_RUN=true ;;
      --no-update) SKIP_UPDATE=true ;;
      --profile=*)
        PROFILE="${arg#*=}"
        case "${PROFILE}" in
          personal | work) remember_profile ;;
          *)
            error "unknown profile: ${PROFILE} (expected personal or work)"
            return 1
            ;;
        esac
        ;;
      --list)
        printf 'enabled modules:\n'
        printf '  %s\n' "${MODULES[@]}"
        return 10
        ;;
      --modules)
        known_modules
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

# Checked before anything is installed, so a typo costs nothing.
validate_modules() {
  local module
  local status=0

  for module in "$@"; do
    if ! declare -F "mod_${module}" >/dev/null; then
      error "no such module: ${module}"
      status=1
    fi
  done
  if ((status != 0)); then
    printf 'known modules: %s\n' "$(known_modules | tr '\n' ' ')" >&2
  fi
  return "${status}"
}

main() {
  local parse_status=0
  local to_run module

  parse_args "$@" || parse_status=$?
  ((parse_status == 10)) && return 0
  ((parse_status != 0)) && return "${parse_status}"

  to_run=("${MODULES[@]}")
  ((${#REQUESTED[@]})) && to_run=("${REQUESTED[@]}")
  validate_modules "${to_run[@]}" || return 1

  step "preflight"
  if [[ "$(uname)" != Darwin ]]; then
    error "macOS only for now."
    return 1
  fi
  success "repo at ${DOTFILES_DIR}"
  [[ "${DRY_RUN}" == true ]] && warn "dry run — nothing will be changed"

  step "profile"
  resolve_profile || return 1

  step "homebrew"
  install_homebrew || return 1

  for module in "${to_run[@]}"; do
    "mod_${module}"
  done

  printf '\n%s%sDone.%s Ran: %s\n' \
    "${GREEN}" "${BOLD}" "${RESET}" "${to_run[*]}"
  if [[ " ${to_run[*]} " == *" zsh "* ]]; then
    printf 'Restart your shell — antidote builds the plugin bundle first.\n'
  fi

  [[ "$(profile)" == work ]] && report_overlay_files
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
