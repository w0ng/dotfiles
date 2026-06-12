# dotfiles

Personal macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quickstart

Clone the repo to your home directory and run the bootstrap script:

```sh
git clone https://github.com/w0ng/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
```

The script will:

1. Install [Homebrew](https://brew.sh) (if not already present)
2. Install all required applications via `brew`
3. Install global npm packages (LSP servers for neovim)
4. Install `stylua` via `cargo`
5. Install the `gist` Ruby gem
6. Install [Zinit](https://github.com/zdharma-continuum/zinit) (zsh plugin manager)
7. Install [packer.nvim](https://github.com/wbthomason/packer.nvim) (neovim plugin manager)
8. Symlink all config files into `$HOME` using `stow`

After bootstrapping, open neovim and run `:PackerSync` to install plugins.

## Manual stow

Each directory in this repo is a stow package. To symlink configs individually, run from `~/dotfiles`:

```sh
stow git/
```

Config files are then symlinked into `$HOME`:

```
$ ls -la ~ | grep .git
lrwxr-xr-x   1 andrew  staff     34  9 Dec 21:33 .gitattributes_global -> dotfiles/git/.gitattributes_global
lrwxr-xr-x   1 andrew  staff     23  9 Dec 21:33 .gitconfig -> dotfiles/git/.gitconfig
lrwxr-xr-x   1 andrew  staff     30  9 Dec 21:33 .gitignore_global -> dotfiles/git/.gitignore_global
```

## Packages

| Package | Description |
|---|---|
| `dircolors` | `ls` colour schemes |
| `dprint` | dprint formatter config |
| `editline` | editline (`.editrc`) config |
| `fd` | fd ignore rules |
| `fzf` | fzf shell integration and options |
| `git` | git config, global ignore and attributes |
| `ideavim` | IdeaVim config for JetBrains IDEs |
| `kitty` | Kitty terminal emulator config |
| `mysql` | MySQL client config |
| `nvim` | Neovim config (LSP, plugins, keymaps) |
| `prettier` | Prettier formatter config |
| `readline` | GNU Readline (`.inputrc`) config |
| `stylua` | StyLua Lua formatter config |
| `tmux` | tmux config |
| `weechat` | WeeChat IRC client config |
| `zsh` | Zsh shell config (`.zshrc`, `.zprofile`) |
