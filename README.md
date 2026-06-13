# dotfiles

Personal macOS dotfiles managed with GNU [`stow`](https://www.gnu.org/software/stow/).
Each top-level directory is a stow "package" whose layout mirrors `$HOME`; running
`stow <package>` symlinks its contents into place.

Sets up a terminal environment (zsh with antidote + starship + atuin, kitty, tmux),
Neovim with LSP, and assorted CLI tooling (ripgrep, fd, fzf, delta, lsd, …).

## Prerequisites

[Homebrew](https://brew.sh) and GNU `stow`:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install stow
```

Clone this repo into `$HOME`:

```sh
git clone https://github.com/w0ng/dotfiles.git ~/dotfiles && cd ~/dotfiles
```

## Install dependencies (macOS)

Everything is available via Homebrew **except antidote**, which must be git-cloned
(see below).

### Shell — zsh + prompt + history

```sh
brew install starship atuin zoxide direnv fzf
```

antidote (the zsh plugin manager) must be cloned to the exact path `~/.zshrc`
expects — do **not** `brew install` it, as Homebrew uses a different path:

```sh
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.local/share/antidote
```

Plugins listed in `~/.zsh_plugins.txt` clone themselves on the next shell launch.

### CLI tools

```sh
brew install lsd fd ripgrep coreutils
```

- `lsd` — `ls` replacement (aliased in `.zshrc`)
- `fd` / `ripgrep` — used by aliases, fzf-tab, and Neovim
- `coreutils` — provides `gdircolors`, which drives `LS_COLORS` theming
- Optional: `brew install bat vivid gist` (`vivid` regenerates the `dircolors-*` themes)

### Neovim

Requires **Neovim ≥ 0.12** — the config uses native `vim.pack`, and plugins install
automatically on first `nvim` launch.

```sh
brew install neovim tree-sitter-cli dprint stylua lua-language-server node
```

LSP servers from npm:

```sh
npm install -g vscode-langservers-extracted cssmodules-language-server stylelint-lsp @typescript/native-preview
```

- `tree-sitter-cli` (the `tree-sitter` command — Homebrew's `tree-sitter` formula is library-only) + Xcode Command Line Tools (`xcode-select --install`) compile Treesitter parsers
- `dprint` / `stylua` are the formatters, run via conform.nvim
- Optional: `brew install rust` — only needed if `fff.nvim` can't download a prebuilt binary and has to build it

### Git

```sh
brew install git git-delta
```

`git-delta` is the configured diff pager (`[pager] diff = delta`).

### Tmux

```sh
brew install tmux reattach-to-user-namespace
```

`reattach-to-user-namespace` backs the `pbcopy` clipboard integration in `.tmux.conf`.

### Terminal & fonts

```sh
brew install --cask kitty font-commit-mono-nerd-font
```

`kitty.conf` sets `font_family CommitMono Nerd Font`.

### Optional packages

```sh
brew install mysql weechat   # for the mysql/ and weechat/ configs
```

`ideavim/` is consumed by JetBrains IDEs (install the IDE separately). `readline/`
and `editline/` need no extra packages.

## Symlink with stow

From `~/dotfiles`, stow the packages you want, e.g.:

```sh
stow zsh nvim git tmux kitty starship atuin dircolors dprint stylua fd fzf -t ~
```

Config files are now symlinks back into this repo, so you edit them in place:

```sh
nvim ~/.zshrc      # edits ~/dotfiles/zsh/.zshrc
```

After adding a new file to an already-stowed package, re-run `stow -R <package> -t ~`
to pick it up.

## Post-install

Reload the shell, then launch Neovim once to let `vim.pack` install plugins:

```sh
exec zsh
nvim
```

## macOS system defaults

`.macos/defaults.bash` applies personal macOS preferences and `.macos/Library/Fonts/`
holds bundled fonts. Review before running:

```sh
bash ~/dotfiles/.macos/defaults.bash
```

## References

- [Managing dotfiles with GNU Stow](https://venthur.de/2021-12-19-managing-dotfiles-with-stow.html)
