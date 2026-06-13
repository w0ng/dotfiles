#
# ~/.zshrc — interactive zsh configuration
#
# Plugin stack (2026): antidote (manager) + starship (prompt) + atuin (history).
# Replaces the previous prezto-via-zinit hybrid. Plugins are declared in
# ~/.zsh_plugins.txt.
#

#
# Plugin config that must be set BEFORE plugins load
#
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

#
# Antidote — plugin manager (https://antidote.sh), static-bundle pattern.
#
# Plugins are declared in ~/.zsh_plugins.txt and compiled into a static
# ~/.zsh_plugins.zsh that we source directly for fast startup; it's only
# regenerated when the .txt changes. The GIT_CONFIG_* override disables git's
# fsmonitor during regeneration so a file watcher's "Adding ... to watch list"
# output (some environments enable fsmonitor globally) can't leak into the
# bundle and corrupt it. Guarded so the shell still works before antidote is
# installed.
#
ANTIDOTE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/antidote"
if [[ -e "$ANTIDOTE_DIR/antidote.zsh" ]]; then
  source "$ANTIDOTE_DIR/antidote.zsh"
  zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins"
  if [[ ! "${zsh_plugins}.zsh" -nt "${zsh_plugins}.txt" ]]; then
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor GIT_CONFIG_VALUE_0=false \
      antidote bundle <"${zsh_plugins}.txt" >|"${zsh_plugins}.zsh"
  fi
  source "${zsh_plugins}.zsh"
  unset zsh_plugins
fi

#
# Shell options (replaces prezto environment/directory/history modules)
#

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY        # record timestamp for each command
setopt INC_APPEND_HISTORY      # write commands as they're entered
setopt SHARE_HISTORY           # share history across sessions
setopt HIST_IGNORE_DUPS        # don't record an immediately-repeated command
setopt HIST_IGNORE_ALL_DUPS    # remove older duplicate of a re-entered command
setopt HIST_IGNORE_SPACE       # don't record lines starting with a space
setopt HIST_REDUCE_BLANKS      # trim superfluous blanks
setopt HIST_VERIFY             # don't auto-run a history expansion; edit it first

# Directories
setopt AUTO_CD                 # `foo/` is treated as `cd foo/`
setopt AUTO_PUSHD              # cd pushes onto the directory stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# General
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS    # allow `# comments` at an interactive prompt
setopt LONG_LIST_JOBS
setopt COMBINING_CHARS
setopt RC_QUOTES               # '' is a literal single quote inside '...'
unsetopt FLOW_CONTROL          # free up ^Q / ^S

#
# Vi mode (replaces prezto editor module)
#
bindkey -v
export KEYTIMEOUT=1            # 10ms; snappy insert<->command switching

# Cursor shape: beam in insert mode, block in command mode
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      print -n '\e[1 q' ;;   # block
    viins|main) print -n '\e[5 q' ;;   # beam
  esac
}
zle -N zle-keymap-select
function zle-line-init { print -n '\e[5 q' }
zle -N zle-line-init

#
# Completion styling (consumed by fzf-tab; compinit is handled by ez-compinit)
#
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu no                              # fzf-tab owns the menu
zstyle ':fzf-tab:*' use-fzf-default-opts yes                # reuse gruvbox FZF_DEFAULT_OPTS
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --color=always $realpath'
# (completion list-colors is set after LS_COLORS, further down)

#
# Aliases
#
alias icat="kitty +kitten icat"
alias cf='cd $(fd --type directory | fzf)'
alias d="cd $HOME/dev"
alias dc="docker-compose"
alias gcM='git commit --amend --message'
alias gist="gist -p"
alias g='git add . && git commit -m "WIP: $(date)"'
alias ls='lsd --group-directories-first --color=auto --classify --human-readable'
alias s="cd $HOME/dev/scratch"
alias ssh='kitty +kitten ssh'
alias tm="tmux attach-session -d -t 0"
alias vim="nvim"
alias vimdiff="nvim -d"

#
# Git aliases (ported from the prezto git module)
#
# `gws` originally interpolated prezto's $_git_status_ignore_submodules; its
# default was 'none', baked in below so it behaves identically without prezto.
alias gb='git branch'
alias gco='git checkout'
alias gcs='git show'
alias gd='git ls-files'
alias gfm='git pull'
alias gia='git add'
alias gwd='git diff --no-ext-diff'
alias gws='git status --ignore-submodules=none --short'

#
# Terminal / tab title (replaces prezto terminal module auto-title)
#
autoload -Uz add-zsh-hook
function _term_title_precmd { print -Pn '\e]0;%n@%m: %~\a' }
function _term_title_preexec { print -n "\e]0;$1\a" }
add-zsh-hook precmd _term_title_precmd
add-zsh-hook preexec _term_title_preexec

#
# Additional vi keybindings
#

bindkey -M viins '^A' beginning-of-line

autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey -M viins '^P' up-line-or-beginning-search

autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^N' down-line-or-beginning-search

bindkey -M viins 'jj' vi-cmd-mode

#
# dircolors (GNU coreutils — `brew install coreutils` provides gdircolors on macOS)
#

if (( $+commands[gdircolors] )); then
  if [[ $COLORTERM =~ ^(truecolor|24bit) && -s "$HOME/.config/dircolors/dircolors-gruvbox-dark" ]]; then
    # `vivid generate gruvbox-dark > dircolors-gruvbox-dark`
    export LS_COLORS="$(cat "$HOME/.config/dircolors/dircolors-gruvbox-dark")"
  elif [[ -s "$HOME/.config/dircolors/dircolors-256color" ]]; then
    eval "$(gdircolors --sh "$HOME/.config/dircolors/dircolors-256color")"
  else
    eval "$(gdircolors --sh)"
  fi
fi
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"   # colorize completion menus

#
# Source applications
#

if [[ -s "$HOME/.devenv.zsh" ]]; then
  source "$HOME/.devenv.zsh"
fi

if [[ -s "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi

# Nix
if [[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
  source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

if (( $+commands[zoxide] )); then
  unalias cd 2>/dev/null || true
  unalias zi 2>/dev/null || true
  eval "$(zoxide init --cmd cd zsh)"
fi

#
# Prompt — starship (replaces the prezto w0ng prompt + zsh-async)
#
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

#
# Shell history — atuin (local-only). Loaded LAST so it owns Ctrl-R.
# --disable-up-arrow keeps the Up arrow and ^P/^N prefix-search untouched.
#
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# pnpm
export PNPM_HOME="/Users/andrew.w/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
