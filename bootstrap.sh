#!/usr/bin/env bash
#
# bootstrap.sh — initialise dotfiles on a new macOS machine
#
# Usage: bash bootstrap.sh
#
# Run from the dotfiles directory (~/dotfiles) after cloning the repo.
# Installs all required applications, then symlinks config files via stow.

set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { printf "${BLUE}==>${RESET} ${BOLD}%s${RESET}\n" "$*"; }
success() { printf "${GREEN}  ✓${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}  !${RESET} %s\n" "$*"; }
error()   { printf "${RED}  ✗${RESET} %s\n" "$*" >&2; }
step()    { printf "\n${BOLD}%s${RESET}\n" "── $* ──────────────────────────────────────"; }

# ── preflight ────────────────────────────────────────────────────────────────

step "Preflight checks"

if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is macOS-only."
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$DOTFILES_DIR" != "$HOME/dotfiles" ]]; then
  warn "Script is running from $DOTFILES_DIR"
  warn "Stow expects the repo to live at ~/dotfiles for symlinks to resolve correctly."
  read -rp "Continue anyway? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi

success "Running from $DOTFILES_DIR"

# ── Homebrew ─────────────────────────────────────────────────────────────────

step "Homebrew"

if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script (Apple Silicon path)
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
else
  success "Homebrew already installed"
  eval "$(brew shellenv)"
fi

info "Updating Homebrew..."
brew update --quiet

# ── Homebrew formulae ────────────────────────────────────────────────────────

step "Homebrew formulae"

BREW_FORMULAE=(
  # dotfile management
  stow

  # shell
  zsh

  # editors
  neovim

  # treesitter parser compilation — nvim-treesitter's `main` branch builds
  # parsers from source on first launch via the tree-sitter CLI
  tree-sitter-cli

  # terminal multiplexer
  tmux

  # fuzzy finder and file search
  fzf
  fd

  # GNU coreutils (provides gls, gdircolors used in .zshrc)
  coreutils

  # interactive shell tooling (configured in zsh/.zshrc)
  lsd        # used by the fzf-tab cd preview
  bat        # cat replacement (aliased to `cat`)
  starship   # prompt
  atuin      # shell history (Ctrl-R)
  zoxide     # smart cd (aliased to `cd`)
  direnv     # per-directory environment

  # formatters (used by neovim formatter.nvim + efm-langserver)
  prettierd

  # language servers (brew-based)
  efm-langserver
  lua-language-server

  # version management
  node@20    # used for npm global LSP installs
  ruby       # used for gist gem

  # rust toolchain (for stylua)
  rustup

  # git tooling
  git
  gh         # GitHub CLI

  # irc client
  weechat

  # gist CLI (gem installed later)
  # mysql client config
  mysql-client
)

for formula in "${BREW_FORMULAE[@]}"; do
  # Skip comment lines
  [[ "$formula" == \#* ]] && continue
  if brew list --formula "$formula" &>/dev/null 2>&1; then
    success "$formula already installed"
  else
    info "Installing $formula..."
    brew install "$formula"
  fi
done

# ── Homebrew casks ───────────────────────────────────────────────────────────

step "Homebrew casks"

BREW_CASKS=(
  kitty    # terminal emulator
)

for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null 2>&1; then
    success "$cask already installed"
  else
    info "Installing $cask (cask)..."
    brew install --cask "$cask"
  fi
done

# ── Rust / Cargo ─────────────────────────────────────────────────────────────

step "Rust / Cargo"

# rustup was installed by brew; initialise the toolchain if needed.
# cargo also backs fff.nvim, which builds its Rust binary on first nvim launch
# (via the PackChanged hook in init.lua) when no prebuilt binary is available.
if ! command -v cargo &>/dev/null; then
  info "Initialising Rust toolchain..."
  rustup-init -y --no-modify-path
  source "$HOME/.cargo/env"
else
  success "cargo already available"
fi

if ! command -v stylua &>/dev/null; then
  info "Installing stylua via cargo..."
  cargo install stylua
else
  success "stylua already installed"
fi

# ── Node.js / npm global packages ────────────────────────────────────────────

step "Node.js / npm globals"

# Ensure the pinned node@20 binary is on PATH for this session
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"

if ! command -v node &>/dev/null; then
  error "node not found. Check that node@20 was installed correctly."
  exit 1
fi

success "Node $(node --version), npm $(npm --version)"

NPM_GLOBALS=(
  # TypeScript LSP
  typescript
  typescript-language-server

  # CSS / HTML / JSON / ESLint LSPs (all from this package)
  vscode-langservers-extracted

  # GraphQL LSP
  graphql-language-service-cli

  # Prisma LSP
  "@prisma/language-server"

  # Stylelint LSP
  stylelint-lsp

  # CSS Modules LSP
  cssmodules-language-server
)

for pkg in "${NPM_GLOBALS[@]}"; do
  if npm list -g --depth=0 "$pkg" &>/dev/null 2>&1; then
    success "$pkg already installed globally"
  else
    info "npm install -g $pkg..."
    npm install -g "$pkg"
  fi
done

# ── Ruby gems ────────────────────────────────────────────────────────────────

step "Ruby gems"

# Use brew ruby so gem install lands in the right gemdir
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$(gem environment gemdir)/bin:$PATH"

if ! gem list gist -i &>/dev/null 2>&1; then
  info "Installing gist gem..."
  gem install gist
else
  success "gist gem already installed"
fi

# ── Antidote (zsh plugin manager) ────────────────────────────────────────────

step "Antidote"

# Plugins are declared in zsh/.zsh_plugins.txt (stowed to ~/.zsh_plugins.txt) and
# compiled into a static ~/.zsh_plugins.zsh by .zshrc on the first shell start.
ANTIDOTE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/antidote"

if [[ -d "$ANTIDOTE_DIR" ]]; then
  success "Antidote already installed at $ANTIDOTE_DIR"
else
  info "Installing Antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
  success "Antidote installed"
fi

# ── Neovim plugins ───────────────────────────────────────────────────────────

step "Neovim plugins"

# Plugins are managed by native vim.pack (Neovim 0.12+), configured inline in
# init.lua. There is no plugin-manager install step: plugins clone on the first
# `nvim` launch and the lockfile lives at ~/.config/nvim/nvim-pack-lock.json.
success "Managed by vim.pack — installs on first nvim launch (no action needed)"

# ── Stow dotfiles ─────────────────────────────────────────────────────────────

step "Stow dotfiles"

cd "$DOTFILES_DIR"

STOW_PACKAGES=(
  dircolors
  dprint
  editline
  fd
  fzf
  git
  ideavim
  kitty
  mysql
  nvim
  prettier
  readline
  starship
  stylua
  tmux
  zsh
  # weechat — skipped by default; may contain IRC credentials
)

warn "weechat config is skipped (may contain credentials). Stow it manually if needed: stow weechat"

for pkg in "${STOW_PACKAGES[@]}"; do
  [[ "$pkg" == \#* ]] && continue
  if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
    info "Stowing $pkg..."
    stow --restow "$pkg"
    success "$pkg symlinked"
  else
    warn "$pkg directory not found, skipping"
  fi
done

# ── Done ─────────────────────────────────────────────────────────────────────

printf "\n${GREEN}${BOLD}Bootstrap complete!${RESET}\n\n"
printf "Next steps:\n"
printf "  1. Restart your shell — antidote installs zsh plugins and builds the bundle on first start\n"
printf "  2. Launch nvim — vim.pack installs plugins and tree-sitter compiles parsers on first run\n"
printf "  3. If you use weechat, run: ${BOLD}cd ~/dotfiles && stow weechat${RESET}\n"
printf "  4. Set up any private tokens in ~/.tokens\n\n"
