# CLAUDE.md

## What this is

Personal macOS dotfiles (Apple Silicon; Homebrew at `/opt/homebrew`), managed
with [GNU Stow](https://www.gnu.org/software/stow/). Default branch: `master`.

## Architecture: stow packages

Almost every top-level directory is a stow package whose internal layout
mirrors `$HOME`: stow links `bat/.config/bat/config` to `~/.config/bat/config`.
`macos/` is the exception. It holds `defaults.bash`, which `mod_macos` runs, and
stowing it would drop `~/defaults.bash` in your home directory.

Two consequences:

- Editing a file inside a package edits the live config, because the `$HOME`
  path is a symlink back into this repo.
- A new file does nothing until you restow its package. Run the module that
  owns it rather than `stow` directly, because `stow_package` passes
  `--no-folding` and ignores `.DS_Store`, and a bare `stow <package>` gets
  neither.

## Setup

`bootstrap.sh` takes a fresh macOS install to a working machine and is the only
sanctioned way to install anything here. To add a tool, declare it in the module
that owns its area and run that module. Installing by hand produces drift. It
works on this Mac and silently breaks on the next one.

A module is a `mod_<name>` function that declares tools with `brew_formula` /
`brew_cask` / `npm_global` and links config with `stow_package`; `MODULES` at
the top of the script lists the enabled ones. `bash bootstrap.sh --help`
documents the flags. Every module is idempotent.

A config stowed with no binary declared is this repo's most common bug. Six
tools have shipped that way, each failing silently. Pair every `stow_package`
line with an install line. `tests/bootstrap_test.sh` asserts exactly that, and
carries the exception list for tools deliberately installed from elsewhere.

Verify by exercising the tool: run the module, then run the thing itself. A
file existing proves nothing.

## Current toolchain

These replaced earlier stacks that are not coming back. Do not propose reverting
to one.

- **zsh**: antidote (plugins in `zsh/.config/zsh/.zsh_plugins.txt`) + a prompt
  written in zsh itself (`zsh/.config/zsh/prompt.zsh`, styled after the old
  prezto "w0ng" theme, git segment queried asynchronously) + atuin history.
  This replaced prezto-via-zinit, and then starship.
- **neovim**: native `vim.pack` (Neovim 0.12+), config under
  `nvim/.config/nvim/`. This replaced packer.nvim, and plugins install
  themselves on first launch, so there is no manual plugin step.

## Conventions

### Commits

[Conventional Commits](https://www.conventionalcommits.org/), written
`<type>(<scope>): <description>`, e.g. `fix(nvim): correct deprecated gruvbox
config`.

- **type**: `feat`, `fix`, `docs`, `refactor`, `chore`, `style`, `build`,
  `perf`, `revert`.
- **scope** (optional): the package or area, such as `zsh`, `nvim`, `ghostty`,
  `bootstrap`.
- **description**: imperative mood, lowercase, no trailing period.

### Code

Comment the why: a constraint, a trade-off, a gotcha a human would otherwise
hit. Skip what restates the code or narrates the change ("now uses X", "added
to fix Y"). Both age into noise. `bootstrap.sh` and
`zsh/.config/zsh/prompt.zsh` are the two files to imitate.

### Prose

This applies to comments, commit messages and the READMEs alike.

No em dashes, and no `--` standing in for one. End the sentence, or use a
comma. A colon is fine ahead of a list, a gloss or an example, but not as a
mid-sentence "because": write the "because".

Sentence case headings, no decorative emoji, straight quotes. Say what the code
does rather than how it feels, and name the actor instead of writing in the
passive. Bold is for a label at the head of a list item, not for emphasis in
the middle of a sentence.
