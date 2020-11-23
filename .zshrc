#
# Zinit: https://github.com/zdharma/zinit
#

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zstyle ':prezto:*:*' case-sensitive 'yes'
zstyle ':prezto:*:*' color 'yes'

zinit snippet PZT::modules/environment/init.zsh

zinit snippet PZT::modules/helper/init.zsh

zstyle ':prezto:module:terminal' auto-title 'yes'
zstyle ':prezto:module:terminal:window-title' format '%n@%m: %s'
zstyle ':prezto:module:terminal:tab-title' format '%m: %s'
zinit snippet PZT::modules/terminal/init.zsh

zstyle ':prezto:module:editor' key-bindings 'vi'
zinit snippet PZT::modules/editor/init.zsh

zinit snippet PZT::modules/history/init.zsh

zinit snippet PZT::modules/directory/init.zsh

zinit snippet PZT::modules/spectrum/init.zsh

zinit ice svn
zinit snippet PZT::modules/utility

zinit ice svn
zinit snippet PZT::modules/git
# gls is Used for GNU ls from coreutils brew package on OSX
unalias gls

zinit ice svn \
atclone'git clone https://github.com/zsh-users/zsh-completions external; for i in external/*.zsh; do zcompile $i; done;' \
atpull'cd ./external; git reset --hard HEAD; git pull; for i in ./*.zsh; do zcompile $i; done;' wait'0' lucid
zinit snippet PZT::modules/completion

zinit ice wait'0' lucid
zinit light zdharma/fast-syntax-highlighting

PURE_GIT_DOWN_ARROW="⬇"
PURE_GIT_UP_ARROW="⬆"
zstyle :prompt:pure:git:stash show yes
zstyle :prompt:pure:path color yellow
zstyle :prompt:pure:git:branch color magenta
zstyle :prompt:pure:git:arrow color 218
zstyle :prompt:pure:git:stash color 218
zstyle :prompt:pure:git:action color 218
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

#
# Aliases
#

alias cdd="cd $HOME/dev"
alias cdr="cd $HOME/dev/phoenix/renderer"
alias cdw="cd $HOME/dev/canva/web"
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
