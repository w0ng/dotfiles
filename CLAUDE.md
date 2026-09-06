# CLAUDE.md

Guidance for working in this repository.

## What this is

Personal macOS dotfiles (Apple Silicon; Homebrew at `/opt/homebrew`), managed
with [GNU Stow](https://www.gnu.org/software/stow/). Default branch: `master`.

## Architecture: stow packages

Almost every top-level directory is a **stow package** whose internal layout
mirrors `$HOME`. Stow symlinks the package contents into the home directory:

- `zsh/.config/zsh/.zshrc` → `~/.config/zsh/.zshrc`
- `bat/.config/bat/config` → `~/.config/bat/config`
- `git/.config/git/config` → `~/.config/git/config`

`macos/` is the exception: it holds `defaults.bash`, which `mod_macos` runs.
Stowing it would put `~/defaults.bash` in your home directory.

Implications when making changes:

- Editing a file inside a package edits the **live config** — the `$HOME` path is
  a symlink back into this repo.
- Adding a **new** file to a package has no effect until the package is
  restowed. Run the module that owns it rather than stow directly —
  `stow_package` passes `--no-folding` and ignores `.DS_Store`, and a bare
  `stow <package>` gets neither.
- To place a config at `~/.config/foo/bar.toml`, create
  `<package>/.config/foo/bar.toml`, then stow it.

## Setup

`bootstrap.sh` takes a fresh macOS install to a working machine, and is the only
sanctioned way to install anything here. **Never install or uninstall by hand** —
declare the tool in a module, then run that module. A tool installed manually is
invisible drift: it works on this Mac and silently breaks on the next one.

It installs Homebrew if missing, then runs each module named in `MODULES` at the
top of the script. A module is a `mod_<name>` function that declares its tools
with `brew_formula` / `brew_cask` / `npm_global` and links its config with
`stow_package`. Enable one by uncommenting its line in `MODULES`.

```sh
bash bootstrap.sh              # every enabled module
bash bootstrap.sh --list       # which modules are enabled
bash bootstrap.sh --dry-run    # print, change nothing
bash bootstrap.sh --no-update  # skip `brew update`
bash bootstrap.sh <module>     # just this one, ignoring MODULES
```

Everything is idempotent. Neovim plugins install themselves on first launch
(native `vim.pack`), so there is no manual plugin step.

When adding a tool, put it in the module that owns its area, together with a
`stow_package` line if this repo carries its config. **A config stowed with no
binary declared is the most common bug in this repo's history** — dprint, stylua,
git-delta, media-control, buf and hunk all shipped that way, each failing
silently. `tests/bootstrap_test.sh` asserts that every `stow_package` has a
matching install line, so a new one now fails there rather than on someone's
fresh machine; that test's exception list is where a tool deliberately not
installed from here gets recorded. Still verify by running the module and
exercising the tool, not by checking that a file exists.

## Current toolchain (do not reintroduce the old stack)

- **zsh**: antidote (plugins declared in `zsh/.config/zsh/.zsh_plugins.txt`) + a prompt
  written in zsh itself (`zsh/.config/zsh/prompt.zsh`, styled after the old
  prezto "w0ng" theme, git segment queried asynchronously) + atuin history.
  This replaced prezto-via-zinit, and then starship — do not reference zinit,
  prezto or starship.
- **neovim**: native `vim.pack` (Neovim 0.12+), config under `nvim/.config/nvim/`.
  This replaced packer.nvim — there is no `:PackerSync`.

Note: `README.md` may lag the current toolchain; trust this file and the actual
config over the README.

## Conventions

### Commits — Conventional Commits

Follow the [Conventional Commits](https://www.conventionalcommits.org/) spec:

```
<type>(<scope>): <description>
```

- **type**: one of `feat`, `fix`, `docs`, `refactor`, `chore`, `style`, `build`,
  `perf`, `revert`.
- **scope** (optional): the package or area, e.g. `zsh`, `nvim`, `ghostty`,
  `bootstrap`.
- **description**: imperative mood, lowercase, no trailing period.

Examples:

- `feat(zsh): migrate from prezto/zinit to antidote`
- `fix(nvim): correct deprecated gruvbox config`
- `docs: add CLAUDE.md`

### Code

Match the style of the file you are editing, including its comment density — the
zsh and prompt configs favour explanatory comments; keep that.
