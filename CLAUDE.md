# CLAUDE.md

Guidance for working in this repository.

## What this is

Personal macOS dotfiles (Apple Silicon; Homebrew at `/opt/homebrew`), managed
with [GNU Stow](https://www.gnu.org/software/stow/). Default branch: `master`.

## Architecture: stow packages

Every top-level directory is a **stow package** whose internal layout mirrors
`$HOME`. Stow symlinks the package contents into the home directory:

- `zsh/.zshrc` → `~/.zshrc`
- `starship/.config/starship.toml` → `~/.config/starship.toml`
- `git/.gitconfig` → `~/.gitconfig`

Implications when making changes:

- Editing a file inside a package edits the **live config** — the `$HOME` path is
  a symlink back into this repo.
- Adding a **new** file to a package has no effect until the package is
  (re)stowed: `cd ~/dotfiles && stow <package>`.
- To place a config at `~/.config/foo/bar.toml`, create
  `<package>/.config/foo/bar.toml`, then stow it.

## Setup

`bootstrap.sh` is the entry point for a fresh machine. It installs Homebrew plus
`BREW_FORMULAE`/`BREW_CASKS`, the Rust toolchain (for `stylua`), `node@20` and the
npm LSP servers, the `gist` gem, clones
[antidote](https://github.com/mattmc3/antidote), and stows every package in
`STOW_PACKAGES`. Neovim plugins install on first launch (no manual step).

When adding a tool or package, update `bootstrap.sh` too: CLI tools go in
`BREW_FORMULAE`, GUI apps in `BREW_CASKS`, new stow packages in `STOW_PACKAGES`.

## Current toolchain (do not reintroduce the old stack)

- **zsh**: antidote (plugins declared in `zsh/.zsh_plugins.txt`) + starship prompt
  (`starship/.config/starship.toml`, styled to mimic the old prezto "w0ng" theme)
  + atuin history. This replaced the previous prezto-via-zinit setup — do not
  reference zinit or prezto.
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
- **scope** (optional): the package or area, e.g. `zsh`, `nvim`, `kitty`,
  `bootstrap`.
- **description**: imperative mood, lowercase, no trailing period.

Examples:

- `feat(zsh): migrate from prezto/zinit to antidote`
- `fix(nvim): correct deprecated gruvbox config`
- `docs: add CLAUDE.md`

### Code

Match the style of the file you are editing, including its comment density — the
zsh and starship configs favour explanatory comments; keep that.
