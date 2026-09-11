#!/bin/bash
#
# Tests for bootstrap.sh.
#
# Run from the repository root:
#
#   bash tests/bootstrap_test.sh
#
# bootstrap.sh is sourced rather than executed, so its functions can be called
# in isolation. Every test points DOTFILES_DIR and STOW_TARGET at a scratch
# directory and stubs BREW/STOW/NPM, so nothing here touches the real machine.
# No test framework: a dependency to run the tests would defeat the point.

# shellcheck source-path=SCRIPTDIR source=./harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

setup() {
  WORK_DIR="$(mktemp -d)"
  STUB_LOG="${WORK_DIR}/calls.log"
  : >"${STUB_LOG}"

  mkdir -p "${WORK_DIR}/repo" "${WORK_DIR}/home" "${WORK_DIR}/stubs"

  # Stubs record their arguments and succeed. `brew list` returning nothing
  # keeps the installed-package index empty unless a test says otherwise.
  cat >"${WORK_DIR}/stubs/brew" <<'STUB'
#!/bin/bash
printf 'brew %s\n' "$*" >> "${STUB_LOG}"
case "$1 $2" in
  'list --formula') printf '%s\n' "${STUB_FORMULAE:-}" ;;
  'list --cask') printf '%s\n' "${STUB_CASKS:-}" ;;
esac
case "$1 $2" in
  'trust --json') printf '%s\n' "${STUB_TRUSTED:-}" ;;
  'services list') printf '%s\n' "${STUB_SERVICES:-}" ;;
esac
case "$1" in
  tap) [[ $# -eq 1 ]] && printf '%s\n' "${STUB_TAPS:-}" ;;
  --prefix) printf '%s\n' "${WORK_DIR}/brew" ;;
esac
exit 0
STUB
  cat >"${WORK_DIR}/stubs/stow" <<'STUB'
#!/bin/bash
printf 'stow %s\n' "$*" >> "${STUB_LOG}"
exit 0
STUB
  cat >"${WORK_DIR}/stubs/npm" <<'STUB'
#!/bin/bash
printf 'npm %s\n' "$*" >> "${STUB_LOG}"
[[ "$1 $2" == 'ls -g' ]] && printf '%s\n' "${STUB_NPM_PATHS:-}"
exit 0
STUB
  chmod +x "${WORK_DIR}/stubs/"*
  export STUB_LOG WORK_DIR

  DOTFILES_DIR="${WORK_DIR}/repo"
  STOW_TARGET="${WORK_DIR}/home"
  BREW="${WORK_DIR}/stubs/brew"
  STOW="${WORK_DIR}/stubs/stow"
  NPM="${WORK_DIR}/stubs/npm"
  # Points the Homebrew probe away from the real prefixes, so no test can eval
  # the machine's own `brew shellenv`.
  BREW_PREFIXES="${WORK_DIR}/no-brew"
  export DOTFILES_DIR STOW_TARGET BREW STOW NPM BREW_PREFIXES

  # Cleared so a previous test's cache cannot leak in.
  unset HOMEBREW_PREFIX BACKUP_DIR
  # shellcheck source-path=SCRIPTDIR source=../bootstrap.sh
  source "${REPO_ROOT}/bootstrap.sh"
  # bootstrap.sh sets errexit for its own run; leaving it on here would abort a
  # test the moment it called a function that legitimately returns non-zero.
  set +e +u +o pipefail

  INDEX_LOADED=false
  DRY_RUN=false
}

teardown() {
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
  unset STUB_FORMULAE STUB_CASKS STUB_TAPS STUB_TRUSTED STUB_NPM_PATHS STUB_SERVICES
}

#######################################
# Tests
#######################################

test_listed_matches_whole_lines_only() {
  local list
  list="$(printf 'node\nripgrep\nzsh')"

  listed "${list}" node
  assert_success $? 'listed finds first entry'
  listed "${list}" zsh
  assert_success $? 'listed finds last entry'
  listed "${list}" nod
  assert_failure $? 'listed rejects a prefix'
  listed "${list}" rep
  assert_failure $? 'listed rejects a suffix'
}

test_brew_formula_skips_when_already_installed() {
  export STUB_FORMULAE='ripgrep'
  local output
  output="$(brew_formula ripgrep)"

  assert_contains "${output}" 'ripgrep' 'reports the formula'
  assert_not_contains "$(calls)" 'brew install' 'does not install again'
}

test_brew_formula_installs_when_missing() {
  export STUB_FORMULAE=''
  brew_formula ripgrep >/dev/null

  assert_contains "$(calls)" 'brew install ripgrep' 'installs the formula'
}

test_brew_formula_uses_bare_name_for_tapped_formula() {
  # `brew list` reports sketchybar, but installing needs the qualified name.
  export STUB_FORMULAE='sketchybar'
  brew_formula felixkratz/formulae/sketchybar >/dev/null

  assert_not_contains "$(calls)" 'brew install' \
    'recognises a tapped formula by its bare name'
}

test_package_index_is_queried_once() {
  export STUB_FORMULAE='ripgrep'
  brew_formula ripgrep >/dev/null
  brew_formula ripgrep >/dev/null
  brew_formula ripgrep >/dev/null

  local list_calls
  list_calls="$(calls | grep -c 'brew list --formula')"
  assert_eq '1' "${list_calls}" 'brew list runs once for three lookups'
}

test_install_is_remembered_across_modules() {
  export STUB_FORMULAE=''
  brew_formula node >/dev/null
  brew_formula node >/dev/null

  local install_calls
  install_calls="$(calls | grep -c 'brew install node')"
  assert_eq '1' "${install_calls}" 'second call skips the reinstall'
}

# An app already in /Applications arrived some other way, typically an MDM
# push. Installing over it fails outright, so the cask must be skipped.
test_brew_cask_skips_an_app_already_on_disk() {
  export STUB_CASKS=''
  # Ghostty.app is present on any machine this repo has provisioned; the point
  # is that a bundle argument matching a real directory suppresses the install.
  local existing='Ghostty.app'
  if [[ ! -d "/Applications/${existing}" ]]; then
    return 0 # nothing to assert against on this machine
  fi

  brew_cask ghostty "${existing}" >/dev/null
  assert_not_contains "$(calls)" 'brew install' \
    'a cask whose app is already installed is skipped'
}

test_brew_cask_installs_when_the_bundle_is_absent() {
  export STUB_CASKS=''
  brew_cask someapp 'DefinitelyNotInstalled.app' >/dev/null

  assert_contains "$(calls)" 'brew install --cask someapp' \
    'a cask with no app on disk still installs'
}

# `brew services list` prints one line per service, "name state user plist".
# Only "started" means the thing is up; every other state, error included, is a
# service that is not running and has to be started.
test_brew_service_skips_one_already_started() {
  export STUB_SERVICES='sketchybar started andrew ~/Library/LaunchAgents/sh.brew.sketchybar.plist'
  local output
  output="$(brew_service sketchybar)"

  assert_contains "${output}" 'sketchybar' 'reports the service'
  assert_not_contains "$(calls)" 'brew services start' 'does not start it again'
}

test_brew_service_starts_a_stopped_one() {
  export STUB_SERVICES='sketchybar none'
  brew_service sketchybar >/dev/null

  assert_contains "$(calls)" 'brew services start sketchybar' \
    'a stopped service is started'
}

# A crashed service still has a line in the listing, so matching the name alone
# would leave the bar down.
test_brew_service_restarts_one_that_errored() {
  export STUB_SERVICES='sketchybar error 256 andrew'
  brew_service sketchybar >/dev/null

  assert_contains "$(calls)" 'brew services start sketchybar' \
    'an errored service is started rather than left down'
}

test_brew_service_matches_the_whole_name() {
  export STUB_SERVICES='sketchybard started andrew'
  brew_service sketchybar >/dev/null

  assert_contains "$(calls)" 'brew services start sketchybar' \
    'a longer service name does not satisfy a shorter one'
}

# Finder drops .DS_Store into package directories. It is gitignored, but stow
# reads the filesystem, and one colliding with an existing ~/.DS_Store aborts
# the whole package.
test_stow_ignores_ds_store() {
  mkdir -p "${DOTFILES_DIR}/pkg"
  printf 'x\n' >"${DOTFILES_DIR}/pkg/.DS_Store"
  printf 'real\n' >"${DOTFILES_DIR}/pkg/.realrc"

  stow_package pkg >/dev/null

  assert_contains "$(calls)" '--ignore=\.DS_Store' 'stow is told to skip .DS_Store'
}

# CLIs the work tooling bundle already puts on PATH: brew's copy would shadow
# it with a different version, so a work machine leaves it to the bundle.
test_personal_formula_installs_under_the_personal_profile() {
  export STUB_FORMULAE=''
  PROFILE=personal
  personal_formula sometool >/dev/null

  assert_contains "$(calls)" 'brew install sometool' 'personal profile installs it'
}

test_personal_formula_skips_under_the_work_profile() {
  export STUB_FORMULAE=''
  PROFILE=work
  local output
  output="$(personal_formula sometool)"

  assert_contains "${output}" 'work tooling bundle' 'explains the skip'
  assert_not_contains "$(calls)" 'brew install' 'work profile installs nothing'
}

test_personal_formula_removes_a_shadowing_brew_copy_on_work() {
  export STUB_FORMULAE='sometool'
  PROFILE=work
  personal_formula sometool >/dev/null

  assert_contains "$(calls)" 'brew uninstall sometool' \
    'work profile removes the shadowing copy'
}

# Apps the employer manages are installed on a personal machine and left alone
# on a work one, where a brew copy would fight the managed one.
test_personal_cask_installs_under_the_personal_profile() {
  export STUB_CASKS=''
  PROFILE=personal
  personal_cask someapp 'DefinitelyNotInstalled.app' >/dev/null

  assert_contains "$(calls)" 'brew install --cask someapp' \
    'personal profile installs the cask'
}

test_personal_cask_skips_under_the_work_profile() {
  export STUB_CASKS=''
  PROFILE=work
  local output
  output="$(personal_cask someapp 'DefinitelyNotInstalled.app')"

  assert_contains "${output}" 'managed on work machines' 'explains the skip'
  assert_not_contains "$(calls)" 'brew install' 'work profile installs nothing'
}

# A machine that later became managed, or an earlier run before the app was
# declared managed, can leave a brew copy behind.
test_personal_cask_removes_a_brew_copy_under_the_work_profile() {
  export STUB_CASKS='someapp'
  PROFILE=work
  personal_cask someapp 'DefinitelyNotInstalled.app' >/dev/null

  assert_contains "$(calls)" 'brew uninstall --cask someapp' \
    'work profile removes the brew copy'
}

# Tools write runtime state into their own package directory through a folded
# stow symlink. Those files are gitignored and never stowed, so displacing them
# would move live state, such as a herdr session or an nvim lockfile, into the
# backup.
test_package_files_lists_only_tracked_files() {
  mkdir -p "${DOTFILES_DIR}/pkg/.config/pkg"
  (cd "${DOTFILES_DIR}" && git init -q . && printf 'runtime.log\n' >.gitignore)
  printf 'real config\n' >"${DOTFILES_DIR}/pkg/.config/pkg/config.toml"
  printf 'live state\n' >"${DOTFILES_DIR}/pkg/.config/pkg/runtime.log"
  (cd "${DOTFILES_DIR}" && git add pkg/.config/pkg/config.toml 2>/dev/null)

  local listed
  listed="$(package_files pkg | tr '\n' ' ')"
  assert_contains "${listed}" 'config.toml' 'tracked file is listed'
  assert_not_contains "${listed}" 'runtime.log' 'gitignored runtime state is not'
}

test_stow_package_warns_for_unknown_package() {
  local output
  output="$(stow_package nonexistent)"

  assert_contains "${output}" 'no such package' 'warns about the package'
  assert_not_contains "$(calls)" 'stow ' 'does not invoke stow'
}

test_stow_package_backs_up_a_conflicting_real_file() {
  mkdir -p "${DOTFILES_DIR}/zsh"
  printf 'from repo\n' >"${DOTFILES_DIR}/zsh/.zshrc"
  printf 'pre-existing\n' >"${STOW_TARGET}/.zshrc"

  stow_package zsh >/dev/null

  [[ -e "${STOW_TARGET}/.zshrc" ]] \
    && fail 'the conflicting file should have been moved away'
  local backup
  backup="$(find "${STOW_TARGET}/.dotfiles-backup" -name '.zshrc' 2>/dev/null)"
  [[ -n "${backup}" ]] || fail 'no backup was written'
  assert_eq 'pre-existing' "$(cat "${backup}" 2>/dev/null)" \
    'the backup holds the original content'
}

test_stow_package_leaves_existing_symlinks_alone() {
  mkdir -p "${DOTFILES_DIR}/zsh"
  printf 'from repo\n' >"${DOTFILES_DIR}/zsh/.zshrc"
  ln -s "${DOTFILES_DIR}/zsh/.zshrc" "${STOW_TARGET}/.zshrc"

  stow_package zsh >/dev/null

  [[ -L "${STOW_TARGET}/.zshrc" ]] \
    || fail 'an already-stowed symlink should be untouched'
  [[ -d "${STOW_TARGET}/.dotfiles-backup" ]] \
    && fail 'nothing should have been backed up'
}

# The hazard the backup directory exists to avoid: a file reached through a
# folded parent symlink resolves back into the repo, and moving it would
# destroy the file being stowed.
test_stow_package_never_moves_a_file_that_resolves_into_the_repo() {
  mkdir -p "${DOTFILES_DIR}/nvim/.config/nvim"
  printf 'config\n' >"${DOTFILES_DIR}/nvim/.config/nvim/init.lua"
  mkdir -p "${STOW_TARGET}/.config"
  ln -s "${DOTFILES_DIR}/nvim/.config/nvim" "${STOW_TARGET}/.config/nvim"

  stow_package nvim >/dev/null

  assert_eq 'config' "$(cat "${DOTFILES_DIR}/nvim/.config/nvim/init.lua")" \
    'the source file survives'
}

test_dry_run_changes_nothing() {
  DRY_RUN=true
  mkdir -p "${DOTFILES_DIR}/zsh"
  printf 'from repo\n' >"${DOTFILES_DIR}/zsh/.zshrc"
  printf 'pre-existing\n' >"${STOW_TARGET}/.zshrc"
  export STUB_FORMULAE=''

  brew_formula ripgrep >/dev/null
  stow_package zsh >/dev/null

  assert_eq 'pre-existing' "$(cat "${STOW_TARGET}/.zshrc")" \
    'the conflicting file is untouched'
  # Read-only queries are expected even under --dry-run; mutations are not.
  assert_not_contains "$(calls)" 'brew install' 'nothing was installed'
  assert_not_contains "$(calls)" 'stow --dir' 'nothing was stowed'
}

test_dry_run_does_not_claim_a_stow_happened() {
  DRY_RUN=true
  mkdir -p "${DOTFILES_DIR}/zsh"
  printf 'x\n' >"${DOTFILES_DIR}/zsh/.zshrc"

  local output
  output="$(stow_package zsh)"
  assert_not_contains "${output}" 'stowed zsh' \
    'dry run must not report a completed stow'
}

test_npm_global_reads_scoped_names() {
  STUB_NPM_PATHS="$(printf '/x/node_modules/typescript\n%s' \
    '/x/node_modules/@scope/pkg')"
  export STUB_NPM_PATHS

  npm_global typescript >/dev/null
  assert_not_contains "$(calls)" 'npm install' 'plain name already installed'

  : >"${STUB_LOG}"
  INDEX_LOADED=false
  npm_global @scope/pkg >/dev/null
  assert_not_contains "$(calls)" 'npm install' 'scoped name already installed'
}

test_npm_global_installs_a_missing_package() {
  export STUB_NPM_PATHS=''
  npm_global typescript >/dev/null

  assert_contains "$(calls)" 'npm install -g typescript' 'installs the package'
}

test_parse_args_collects_flags_and_modules() {
  parse_args --dry-run --no-update zsh neovim
  assert_success $? 'parse_args succeeds'
  assert_eq 'true' "${DRY_RUN}" '--dry-run is set'
  assert_eq 'true' "${SKIP_UPDATE}" '--no-update is set'
  assert_eq 'zsh neovim' "${REQUESTED[*]}" 'module names are collected'
}

test_parse_args_rejects_an_unknown_flag() {
  local status=0
  parse_args --nope 2>/dev/null || status=$?
  assert_eq '1' "${status}" 'an unknown flag fails'
}

# 10 is the "already printed what was asked for" status, which main turns into
# a clean exit.
test_informational_flags_return_ten() {
  local status=0
  parse_args --help >/dev/null || status=$?
  assert_eq '10' "${status}" '--help returns 10'

  status=0
  parse_args --list >/dev/null || status=$?
  assert_eq '10' "${status}" '--list returns 10'
}

test_usage_documents_every_flag() {
  local output
  output="$(usage)"
  local flag
  for flag in --list --modules --dry-run --no-update --help; do
    assert_contains "${output}" "${flag}" "usage mentions ${flag}"
  done
}

test_validate_modules_accepts_the_enabled_list() {
  validate_modules "${MODULES[@]}" 2>/dev/null
  assert_success $? 'every enabled module has a mod_ function'
}

test_validate_modules_rejects_a_typo() {
  local status=0
  validate_modules zsh nosuchmodule 2>/dev/null || status=$?
  assert_eq '1' "${status}" 'a bad module name fails'
}

# The mod_ functions are written in MODULES order so the file reads in the
# order it runs. Easy to break by appending a new module at the end of the file.
test_definitions_are_in_modules_order() {
  local defined expected
  defined="$(grep -oE '^mod_[a-z]+' "${REPO_ROOT}/bootstrap.sh" \
    | sed 's/^mod_//' | tr '\n' ' ')"
  expected="${MODULES[*]} "

  assert_eq "${expected}" "${defined}" \
    'function definitions follow MODULES order'
}

# Dependency order: anything whose config drives another module's tools must
# come after it.
test_dependent_modules_follow_their_dependencies() {
  local joined=" ${MODULES[*]} "
  # The trailing space matters: %% strips it along with the match, and the
  # assertions below look for whole words.
  local before_neovim="${joined%% neovim *} "
  local before_wm="${joined%% windowmanager *} "

  assert_contains "${before_neovim}" ' cli ' \
    'cli precedes neovim, whose config drives fzf and ripgrep'
  assert_contains "${before_neovim}" ' runtimes ' \
    'runtimes precedes neovim, which installs npm language servers'
  assert_contains "${before_wm}" ' cli ' \
    'cli precedes windowmanager, whose sketchybar config needs jq'
}

# Guards the ordering rule in MODULES: stow arrives before anything is stowed.
test_core_precedes_stowing_modules() {
  local joined=" ${MODULES[*]} "
  assert_contains "${joined}" ' core ' 'core is enabled'
  local before="${joined%% core *}"
  assert_not_contains "${before}" ' zsh ' 'zsh does not precede core'
  assert_not_contains "${before}" ' neovim ' 'neovim does not precede core'
}

test_brew_trust_skips_an_entry_already_trusted() {
  export STUB_TRUSTED='{"formulae":["some/tap/thing"],"casks":[]}'

  brew_trust --formula some/tap/thing >/dev/null

  assert_not_contains "$(calls)" 'brew trust --formula' \
    'an already-trusted formula is not trusted again'
}

test_brew_trust_trusts_an_entry_that_is_absent() {
  export STUB_TRUSTED='{"formulae":[],"casks":[]}'

  brew_trust --formula some/tap/thing >/dev/null

  assert_contains "$(calls)" 'brew trust --formula some/tap/thing' \
    'an untrusted formula is trusted'
}

test_resolve_profile_refuses_to_guess_without_a_terminal() {
  PROFILE=''
  PROFILE_FILE="${WORK_DIR}/absent-profile"

  local status=0
  resolve_profile </dev/null 2>/dev/null || status=$?

  assert_eq '1' "${status}" 'refuses rather than defaulting to a profile'
}

# The repo paths worth maintaining are employer-specific, so the script creates
# the section and registers nothing. Registering here is what used to write an
# absolute work path into a config file.
test_ensure_maintenance_section_creates_it_without_registering() {
  HOME="${WORK_DIR}/home"
  mkdir -p "${HOME}/work/big/.git"

  ensure_maintenance_section >/dev/null

  assert_contains "$(<"${HOME}/.config/git/config.local")" '[maintenance]' \
    'the section is created'
  assert_not_contains "$(<"${HOME}/.config/git/config.local")" 'repo =' \
    'no repo is registered'
}

test_ensure_maintenance_section_is_idempotent() {
  HOME="${WORK_DIR}/home"
  mkdir -p "${HOME}/.config/git"
  printf '[maintenance]\n\trepo = /somewhere/big\n' >"${HOME}/.config/git/config.local"

  ensure_maintenance_section >/dev/null

  local content
  content="$(<"${HOME}/.config/git/config.local")"
  assert_eq '1' "$(grep -c '^\[maintenance\]' <<<"${content}")" \
    'the section is not added twice'
  assert_contains "${content}" 'repo = /somewhere/big' \
    'an existing entry is left alone'
}

test_report_overlay_files_says_how_to_register_maintenance() {
  HOME="${WORK_DIR}/home"
  mkdir -p "${HOME}/.config/git"
  printf '[maintenance]\n' >"${HOME}/.config/git/config.local"

  local output
  output="$(report_overlay_files)"

  assert_contains "${output}" 'maintenance register --config-file' \
    'prints the command to run by hand'
}

test_report_overlay_files_separates_present_from_missing() {
  HOME="${WORK_DIR}/home"
  mkdir -p "${HOME}/.config/git"
  : >"${HOME}/.config/git/config.local"

  local output
  output="$(report_overlay_files)"

  assert_contains "${output}" 'config.local' 'lists a file that exists'
  assert_contains "${output}" 'MISSING' 'flags the files that do not'
}

# Reads bootstrap.sh rather than running it. A stowed config whose tool is
# never installed fails silently at the point of use, which is the failure this
# repo has shipped most often, so it is worth catching in the source.
test_every_stowed_package_declares_its_tool() {
  # Tools deliberately not installed from here. ideavim's config is useful
  # whenever a JetBrains IDE is present, but the IDE itself is employer-managed
  # on one machine and unwanted on the other, so no profile should install it.
  local exempt=' ideavim '
  # Package directory names that differ from the formula providing them.
  local aliases='nvim=neovim neovide=neovide-app'

  local declared pkg name pair
  # Tap qualification stripped, because a package directory is named for the
  # bare tool.
  declared=" $(grep -oE '^[[:space:]]*(brew_formula|brew_cask|personal_formula|personal_cask|npm_global)[[:space:]]+[^"$ ]+' \
    "${REPO_ROOT}/bootstrap.sh" | awk '{print $2}' | sed "s|.*/||" | tr '\n' ' ') "

  while read -r pkg; do
    [[ -n "${pkg}" ]] || continue
    case "${exempt}" in *" ${pkg} "*) continue ;; esac
    name="${pkg}"
    for pair in ${aliases}; do
      [[ "${pkg}" == "${pair%%=*}" ]] && name="${pair#*=}"
    done
    assert_contains "${declared}" " ${name} " \
      "stow_package ${pkg} has a matching install line"
  done < <(grep -oE '^[[:space:]]*stow_package[[:space:]]+[a-z]+' \
    "${REPO_ROOT}/bootstrap.sh" | awk '{print $2}')
}

# Two modules installing the same package is harmless at runtime but means one
# of them is lying about what it owns, and the second install line will drift.
test_no_package_is_declared_by_two_modules() {
  local dupes
  dupes="$(grep -oE '^[[:space:]]*(brew_formula|brew_cask|personal_formula|personal_cask|npm_global)[[:space:]]+[^"$ ]+' \
    "${REPO_ROOT}/bootstrap.sh" | awk '{print $2}' | sort | uniq -d | tr '\n' ' ')"

  assert_eq '' "${dupes}" 'no package is declared twice'
}

# install_homebrew decided from `command -v brew` alone, so a shell without
# /opt/homebrew on PATH, such as a login shell started before the zsh package
# was stowed, re-ran the entire Homebrew installer over a working install.
test_install_homebrew_finds_an_install_that_is_not_on_path() {
  local prefix output
  prefix="${WORK_DIR}/off-path"
  mkdir -p "${prefix}/bin"
  cat >"${prefix}/bin/brew" <<STUB
#!/bin/bash
case "\$1" in
  shellenv) printf 'export PATH="%s:\$PATH"\n' "${prefix}/bin" ;;
  --prefix) printf '%s\n' "${prefix}" ;;
  --version) printf 'Homebrew 4.0.0\n' ;;
esac
exit 0
STUB
  chmod +x "${prefix}/bin/brew"

  # Should this regress, install_homebrew falls through to the real Homebrew
  # installer. A curl that returns nothing keeps that branch from reaching the
  # network, because the command substitution feeding `bash -c` comes back
  # empty.
  mkdir -p "${WORK_DIR}/safe"
  printf '#!/bin/bash\nexit 0\n' >"${WORK_DIR}/safe/curl"
  chmod +x "${WORK_DIR}/safe/curl"

  BREW=brew # a bare name, so PATH alone decides whether it resolves
  BREW_PREFIXES="${prefix}"
  SKIP_UPDATE=true
  unset HOMEBREW_PREFIX
  output="$(PATH="${WORK_DIR}/safe:/usr/bin:/bin" install_homebrew 2>&1)"

  assert_contains "${output}" 'already installed' 'adopts the off-PATH install'
  assert_not_contains "${output}" 'installing Homebrew' 'no second installer run'
}

# Homebrew 6 asks before any install whose plan reaches past the package named,
# which a single dependency triggers, and a prompt stops an unattended run.
test_install_homebrew_opts_out_of_ask_mode() {
  SKIP_UPDATE=true
  unset HOMEBREW_NO_ASK HOMEBREW_NO_AUTO_UPDATE
  install_homebrew >/dev/null 2>&1

  assert_eq '1' "${HOMEBREW_NO_ASK:-}" 'ask mode off for the run'
  assert_eq '1' "${HOMEBREW_NO_AUTO_UPDATE:-}" 'auto-update stays off too'
}

# Defined in harness.sh, called here so compgen sees this suite's tests.
main "$@"
