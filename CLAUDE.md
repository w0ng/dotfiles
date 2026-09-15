# CLAUDE.md

## What this is

Personal macOS dotfiles (Apple Silicon; Homebrew at `/opt/homebrew`), managed
with [GNU Stow](https://www.gnu.org/software/stow/).

`README.md` is the overview: what this repo installs, how to run
`bootstrap.sh` and `update.sh`, and which machine-local hooks exist. Read it
before setting up a new machine. Why a thing is built the way it is lives in the
code beside it, not there.

## Stow packages

Almost every top-level directory is a stow package whose internal layout
mirrors `$HOME`: stow links `bat/.config/bat/config` to `~/.config/bat/config`.
`macos/` and `alfred/` are the exceptions. `macos/` holds `defaults.bash`, which
`mod_macos` runs, and stowing it would drop `~/defaults.bash` in your home
directory. `alfred/` holds workflow source that `mod_alfred` copies, because
Alfred rewrites an installed workflow's `info.plist` in place and would detach a
symlink from this repo. Before editing anything under `alfred/`, read the
module docstring of the workflow you are touching, which holds its data design,
and `install_alfred_workflow`, which holds what an installed copy keeps across
a run.

Two consequences:

- Editing a file inside a package edits the live config, because the `$HOME`
  path is a symlink back into this repo.
- A new file does nothing until you restow its package. Run the module that
  owns it rather than `stow` directly, because `stow_package` passes
  `--no-folding` and ignores `.DS_Store`, and a bare `stow <package>` gets
  neither. `awk '/^mod_/{m=$1} /stow_package <pkg>/{print m}' bootstrap.sh`
  names the owner.

## Setup

`bootstrap.sh` takes a fresh macOS install to a working machine and is the only
sanctioned way to install anything here. To add a tool, declare it in the module
that owns its area and run that module. A tool installed by hand works on this
Mac and is absent from the next one.

A module is a `mod_<name>` function that declares tools with `brew_formula`,
`brew_cask` or `npm_global` and links config with `stow_package`, or copies it
with `install_alfred_workflow` for the one package that cannot be linked. Every
module is idempotent.

A tool from a third-party tap needs `brew_tap` and `brew_trust` ahead of its
declaration, because Homebrew 6 refuses to load a formula or cask from an
untrusted tap. `mod_windowmanager` is the worked example.

A work machine's device management installs its own browsers, chat clients and
CLI tools. Homebrew's copy sits earlier on `PATH`, where it shadows the managed
one. Declare anything in that overlap with `personal_formula` or
`personal_cask`, which install on a personal machine and skip on a work one.

A config stowed with no binary declared is this repo's most common bug, and it
fails silently at the point of use. Pair every `stow_package` line with an
install line, and every `install_alfred_workflow` line with the script that
workflow runs. Run `bash tests/bootstrap_test.sh` after editing `bootstrap.sh`
or `alfred/`.
It asserts exactly that pairing, and lists the tools deliberately installed
from elsewhere. Renaming a helper here can break `update.sh` while that suite
stays green, so run `bash tests/update_test.sh` as well.

`tests/sketchybar_test.sh` does the same for the AeroSpace bar driver, so run
it after editing `sketchybar/.config/sketchybar/`. `tests/lint_test.sh` is the
style gate for every bash, zsh, Python and Lua file here, so run it after
editing any of them. Every suite takes its assertions and runner from
`tests/harness.sh`.

Verify by exercising the tool: run the module, then run the binary it
installed. A stowed file does not prove the binary is there.

## Updating

`update.sh` is the other half of bootstrap. It upgrades what bootstrap
installed and installs nothing, and it sources `bootstrap.sh` for the output
helpers, the `run` wrapper and the tool probes rather than repeating them, so a
change to those reaches both. `step_alfred` refreshes the copied Alfred
workflow, which a pull cannot reach. Every step must stay unattended, because a
scheduled job may be what runs it. A step runs with no terminal attached, a
failure reports itself and lets the rest of the run finish, and the exit status
says whether any step failed. Run `bash tests/update_test.sh` after editing
it.

## Machine-local settings

Nothing employer-specific is tracked here, and every stowed file is a symlink
into this public repo, so appending a work setting to `~/.config/zsh/.zshrc`
writes it into the repo. Four installers have already done exactly that.
Machine-local settings go in the `.local` hook files instead, starting with
`~/.config/zsh/.zshenv.local` for anything a language server or an agent has to
inherit and `~/.config/zsh/.zshrc.local` for interactive shells. `README.md`
lists each hook and what it reaches.

## Current toolchain

These replaced earlier stacks that are not coming back. Do not propose reverting
to one.

- **zsh**: antidote for plugins (`zsh/.config/zsh/.zsh_plugins.txt`), atuin for
  history, and a prompt written in zsh itself (`zsh/.config/zsh/prompt.zsh`).
  Not prezto, not starship.
- **neovim**: native `vim.pack` (Neovim 0.12+), config under
  `nvim/.config/nvim/`. Not packer.nvim. Plugins install themselves on first
  launch, so there is no manual plugin step.

## Conventions

### Commits

Conventional Commits, e.g. `fix(nvim): correct deprecated gruvbox config`.
Types in use: `feat`, `fix`, `docs`, `style`, `refactor`, `chore`, `perf`.
Scope is the stow package or area, and is optional. Description is lowercase
with no trailing period.

### Shell style

The Google Shell Style Guide is the baseline. `shfmt` and `shellcheck` enforce
it. `.editorconfig` carries layout and `.shellcheckrc` carries idiom, and both
files hold their own reasons, including which optional checks were measured
against this repo and rejected. Read those two for the current set.

Deliberate deviations from Google:

- **80 columns is advisory.** shfmt does not wrap and shellcheck does not
  measure width, so nothing can enforce it.
- **`#!/usr/bin/env bash`, not Google's `#!/bin/bash`.** Google's fleet is
  Linux, where `/bin/bash` is current. Here it is 3.2.57 from 2007, and
  `mod_cli` declares Homebrew's 5.3. This applies to the sketchybar plugins
  too, which sketchybar execs directly, so there the shebang picks the
  interpreter.
- **Two lookup tables are exempt from shfmt.** Each is listed with a reason in
  `LINT_EXCLUDE` in `tests/lint_test.sh`.

One case the gate cannot cover. `.shellcheckrc` and `.editorconfig` sit at the
repo root, and shellcheck and editorconfig both search upward from the path
they are given. Editing through a stowed symlink such as
`~/.config/sketchybar/...`, the normal way to work here, searches from
`~/.config` and reaches neither. That buffer gets shellcheck's defaults, so a
`[ -z "$x" ]` written there looks fine and fails `bash tests/lint_test.sh`
later. Edit under `~/dotfiles/` when the style matters.

### Lua style

`stylua`, configured by `stylua/.config/stylua/stylua.toml`. The gate points at
that copy rather than the stowed `~/.config/stylua/`, so it does not depend on
stow having run.

### zsh style

Same layout rules, applied by hand. `zsh -n` is the whole gate: it proves a
file parses, and nothing checks style. Treat the shell rules above as
unenforced here. shellcheck refuses zsh outright and shfmt's zsh dialect fails
on `prompt.zsh`'s `coproc`, so revisit when a later shfmt parses that file.

### Python style

PEP 8 as enforced by `ruff check`, formatting by `ruff format`, 88 columns, all
configured in `ruff.toml`. Its comments hold the reasons, including why
`target-version` is pinned below the interpreter that usually runs these
scripts. Raising that pin reopens a failure that stays silent until runtime.

Type checking is `pyrefly`, which `mod_neovim` declares and `plugin/lsp.lua`
enables. Ruff does no inference, so the two servers attach to the same buffer
without overlapping. It is an editor tool only: `tests/lint_test.sh` does not
run it, so a type error fails nothing.

### Script discovery

`tests/lint_test.sh` finds scripts by shebang and by extension, over tracked
files and untracked ones that are not ignored, because a new script is in scope
before it is ever `git add`ed.

Give a new script a shebang or a known extension. One with neither is invisible
to every tool above, and `test_every_extensionless_file_is_classified` fails
until it is either discovered as a script or named in `KNOWN_NON_SCRIPTS`.

### Comments

Default to no comment. The code shows how. A comment carries why: a constraint,
a trade-off, a gotcha.

```sh
# Cached, because `brew --prefix` is another 0.35s of Ruby startup.
```

Never narrate the code ("loop over users") or a change ("now uses X"), which
belongs in a commit message. Keep tool directives like `shellcheck disable` and
`---@param`. When in doubt, keep a why and delete a how.

One standing exception: a Nerd Font glyph carries its name beside it, as
`icon="󰂄" # nf-md-battery_charging`. A private-use character renders as an
empty box anywhere the font is not loaded, GitHub included, so this is the one
case where the code cannot show itself. Look each name up in Nerd Fonts'
`glyphnames.json`, which nothing here vendors, and keep one naming generation
per block: `fa-volume_high` and `fa-volume_up` are the same glyph from
different Font Awesome releases.

Before finishing, delete the redundant comments you added.
