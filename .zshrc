#
# Zinit: https://github.com/zdharma/zinit
#

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Extension to load submodules in github repos
zinit light zinit-zsh/z-a-submods

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
  svn atload'unalias gls' PZT::modules/git \
  svn silent submods'mafredri/zsh-async -> external/async' atload'prompt w0ng' https://github.com/w0ng/prezto/trunk/modules/prompt \
  svn wait lucid submods'zsh-users/zsh-completions -> external'  PZT::modules/completion \
  svn wait lucid submods'zsh-users/zsh-autosuggestions -> external' atload'_zsh_autosuggest_start' PZT::modules/autosuggestions \
  light-mode wait lucid zdharma/fast-syntax-highlighting \

#
# Aliases
#

alias cdd="cd $HOME/dev"
alias cdr="cd $HOME/dev/phoenix/renderer"
alias cdw="cd $HOME/dev/canva/web"
alias cdm="cd $HOME/dev/canva/web/src/pages/marketplace"
alias dc="docker-compose"
alias gcM='git commit --amend --message'
alias gist="gist -p"
alias ls='/usr/local/bin/gls --group-directories-first --color=auto --classify --human-readable'
alias ssh='TERM=xterm-256color ssh'
alias tm="tmux attach-session -d -t 0"
alias vim="nvim"
alias vimdiff="nvim -d"

#
# Additional vi keybindings
#

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
  if  [[ -s "$HOME/.dir_colors" ]]; then
    eval "$(gdircolors --sh "$HOME/.dir_colors")"
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
