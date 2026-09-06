# CLAUDE.md

## What this is

Personal macOS dotfiles (Apple Silicon; Homebrew at `/opt/homebrew`), managed
with [GNU Stow](https://www.gnu.org/software/stow/). Default branch: `master`.

## Architecture: stow packages

Almost every top-level directory is a **stow package** whose internal layout
mirrors `$HOME`: `bat/.config/bat/config` is stowed to `~/.config/bat/config`.
`macos/` is the exception — it holds `defaults.bash`, which `mod_macos` runs,
and stowing it would drop `~/defaults.bash` in your home directory.

Two consequences:

- Editing a file inside a package edits the **live config** — the `$HOME` path
  is a symlink back into this repo.
- A **new** file does nothing until its package is restowed. Run the module
  that owns it rather than `stow` directly: `stow_package` passes
  `--no-folding` and ignores `.DS_Store`, and a bare `stow <package>` gets
  neither.

## Setup

`bootstrap.sh` takes a fresh macOS install to a working machine and is the only
sanctioned way to install anything here. To add a tool, declare it in the module
that owns its area and run that module. Installing by hand produces **drift** —
it works on this Mac and silently breaks on the next one.

A module is a `mod_<name>` function that declares tools with `brew_formula` /
`brew_cask` / `npm_global` and links config with `stow_package`; `MODULES` at
the top of the script lists the enabled ones. `bash bootstrap.sh --help`
documents the flags. Every module is idempotent.

**A config stowed with no binary declared is this repo's most common bug** — six
tools have shipped that way, each failing silently. Pair every `stow_package`
line with an install line. `tests/bootstrap_test.sh` asserts exactly that, and
carries the exception list for tools deliberately installed from elsewhere.

Verify by **exercising** the tool: run the module, then run the thing itself. A
file existing proves nothing.

## Current toolchain (the old stacks are not coming back)

- **zsh**: antidote (plugins in `zsh/.config/zsh/.zsh_plugins.txt`) + a prompt
  written in zsh itself (`zsh/.config/zsh/prompt.zsh`, styled after the old
  prezto "w0ng" theme, git segment queried asynchronously) + atuin history.
  This replaced prezto-via-zinit, and then starship.
- **neovim**: native `vim.pack` (Neovim 0.12+), config under
  `nvim/.config/nvim/`. This replaced packer.nvim, and plugins install
  themselves on first launch, so there is no manual plugin step.

## Conventions

### Commits

[Conventional Commits](https://www.conventionalcommits.org/) —
`<type>(<scope>): <description>`, e.g. `fix(nvim): correct deprecated gruvbox
config`.

- **type**: `feat`, `fix`, `docs`, `refactor`, `chore`, `style`, `build`,
  `perf`, `revert`.
- **scope** (optional): the package or area — `zsh`, `nvim`, `ghostty`,
  `bootstrap`.
- **description**: imperative mood, lowercase, no trailing period.

### Code

Comment the **why** — a constraint, a trade-off, a gotcha a human would
otherwise hit. Skip what restates the code or narrates the change ("now uses
X", "added to fix Y"): both age into noise. `bootstrap.sh` and
`zsh/.config/zsh/prompt.zsh` set the bar.
