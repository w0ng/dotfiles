#
# Zinit: https://github.com/zdharma/zinit
#

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
# submods extension loads submodules in github repos
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust \
    zdharma-continuum/zinit-annex-submods

# Prezto config
zstyle ':prezto:*:*' case-sensitive 'yes'
zstyle ':prezto:*:*' color 'yes'
zstyle ':prezto:module:terminal' auto-title 'yes'
zstyle ':prezto:module:terminal:window-title' format '%n@%m: %s'
zstyle ':prezto:module:terminal:tab-title' format '%m: %s'
zstyle ':prezto:module:editor' key-bindings 'vi'

# Load plugins
zinit for \
  PZT::modules/environment/init.zsh \
  PZT::modules/helper/init.zsh \
  PZT::modules/terminal/init.zsh \
  PZT::modules/editor/init.zsh \
  PZT::modules/history/init.zsh \
  PZT::modules/directory/init.zsh \
  PZT::modules/utility \
  svn atload'unalias gls' https://github.com/w0ng/prezto/trunk/modules/git \
  svn silent submods'mafredri/zsh-async -> external/async' atload'prompt w0ng' https://github.com/w0ng/prezto/trunk/modules/prompt \
  svn wait lucid submods'zsh-users/zsh-completions -> external'  PZT::modules/completion \
  svn wait lucid submods'zsh-users/zsh-autosuggestions -> external' atload'_zsh_autosuggest_start' PZT::modules/autosuggestions \
  light-mode wait lucid zdharma-continuum/fast-syntax-highlighting \

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
alias ls='/usr/local/bin/gls --group-directories-first --color=auto --classify --human-readable'
alias n='/usr/bin/ssh nas'
alias luamake=$HOME/dev/lua-language-server/3rd/luamake/luamake
alias s="cd $HOME/dev/scratch"
#alias ssh='TERM=xterm-256color ssh'
alias ssh='kitty +kitten ssh'
alias tm="tmux attach-session -d -t 0"
alias vim="nvim"
alias vimdiff="nvim -d"

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
# Use GNU for ls on OSX. gdircolors is installed via `brew install coreutils`.
#

if (( $+commands[gdircolors] )); then
  if  [[ $COLORTERM =~ ^(truecolor|24bit) && -s "$HOME/.config/dircolors/dircolors-grubox-dark" ]]; then
    # `vivid generate gruvbox-dark > dircolors-gruvbox-dark`
    export LS_COLORS="$(cat "$HOME/.config/dircolors/dircolors-gruvbox-dark")"
  elif [[ -s "$HOME/.config/dircolors/dircolors-256color" ]]; then
    eval "$(gdircolors --sh "$HOME/.config/dircolors/dircolors-256color")"
  else
    eval "$(gdircolors --sh)"
  fi
fi

#
# Source applications
#
#
if [[ -s "$HOME/.devenv.zsh" ]]; then
  source "$HOME/.devenv.zsh"
fi

if [[ -s "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi

# Include command-line API tokens
if [[ -r "$HOME/.tokens" ]]; then
  source "$HOME/.tokens"
fi

# Nix
if [[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
  source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
