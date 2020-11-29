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

# Pure prompt config
export PURE_CMD_MAX_EXEC_TIME=0
export PURE_GIT_DELAY_DIRTY_CHECK=0
export PURE_GIT_COMBINED_DIRTY=0
export PURE_GIT_DOWN_ARROW="⬇"
export PURE_GIT_UP_ARROW="⬆"
export PURE_GIT_STASH_SYMBOL="✭"
export PURE_GIT_ADDED_SYMBOL="✚"
export PURE_GIT_DELETED_SYMBOL="✖"
export PURE_GIT_MODIFIED_SYMBOL="✱"
export PURE_GIT_RENAMED_SYMBOL="➜"
export PURE_GIT_UNMERGED_SYMBOL="═"
export PURE_GIT_UNTRACKED_SYMBOL="◼"
zstyle :prompt:pure:git:stash show yes
zstyle :prompt:pure:path color yellow
zstyle :prompt:pure:git:branch color magenta
zstyle :prompt:pure:git:action color 218 # very bright magenta
zstyle :prompt:pure:git:arrow color 11 # bright yellow
zstyle :prompt:pure:git:stash color 14 # bright cyan
zstyle :prompt:pure:git:added color 10 # bright green
zstyle :prompt:pure:git:deleted color 9 # bright red
zstyle :prompt:pure:git:modified color 12 # bright blue
zstyle :prompt:pure:git:renamed color 13 # bright magenta
zstyle :prompt:pure:git:unmerged color 11 # bright yellow
zstyle :prompt:pure:git:untracked color 15 # white

# Load plugins
zinit for \
  PZT::modules/environment/init.zsh \
  PZT::modules/helper/init.zsh \
  PZT::modules/terminal/init.zsh \
  PZT::modules/editor/init.zsh \
  PZT::modules/history/init.zsh \
  PZT::modules/directory/init.zsh \
  PZT::modules/utility \
  wait lucid svn atload'unalias gls' PZT::modules/git \
  wait lucid svn submods'zsh-users/zsh-completions -> external' PZT::modules/completion \
  wait lucid svn submods'zsh-users/zsh-autosuggestions -> external' PZT::modules/autosuggestions \
  wait lucid light-mode zdharma/fast-syntax-highlighting \
  compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh' light-mode w0ng/pure

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
