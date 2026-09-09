# CLAUDE.md

## What this is

Personal macOS dotfiles (Apple Silicon; Homebrew at `/opt/homebrew`), managed
with [GNU Stow](https://www.gnu.org/software/stow/).

`README.md` documents the install flow and the update command for each package
manager. Read it before updating a tool or setting up a new machine.

## Stow packages

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
  neither. `awk '/^mod_/{m=$1} /stow_package <pkg>/{print m}' bootstrap.sh`
  names the owner.

## Setup

`bootstrap.sh` takes a fresh macOS install to a working machine and is the only
sanctioned way to install anything here. To add a tool, declare it in the module
that owns its area and run that module. A tool installed by hand works on this
Mac and is absent from the next one.

A module is a `mod_<name>` function that declares tools with `brew_formula`,
`brew_cask` or `npm_global` and links config with `stow_package`. Every module
is idempotent.

A tool from a third-party tap needs `brew_tap` and `brew_trust` ahead of its
declaration, because Homebrew 6 refuses to load a formula or cask from an
untrusted tap. `mod_windowmanager` is the worked example.

A work machine's device management installs its own browsers, chat clients and
CLI tools. Homebrew's copy sits earlier on `PATH`, where it shadows the managed
one. Declare anything in that overlap with `personal_formula` or
`personal_cask`, which install on a personal machine and skip on a work one.

A config stowed with no binary declared is this repo's most common bug, and it
fails silently at the point of use. Pair every `stow_package` line with an
install line. Run `bash tests/bootstrap_test.sh` after editing `bootstrap.sh`.
It asserts exactly that pairing, and lists the tools deliberately installed
from elsewhere.

Verify by exercising the tool: run the module, then run the binary it
installed. A stowed file does not prove the binary is there.

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
to fix Y"). Both go stale as the code changes. `bootstrap.sh` and
`zsh/.config/zsh/prompt.zsh` are the two files to imitate.

### Prose

This applies to comments, commit messages and the READMEs.

Four rules apply everywhere: no em dashes, including `--` standing in for one.
Sentence case headings. Straight quotes. Say what the code does rather than how
it feels.

Those four cover comments. Before a README or a commit body, read the rest in
`claude/.claude/skills/pstack-skills/skills/unslop/SKILL.md` and apply every
one. Nothing loads that file for you.
