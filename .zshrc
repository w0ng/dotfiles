#
# Zplugin
#

source "$HOME/.zplugin/bin/zplugin.zsh"
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin

zstyle ':prezto:*:*' case-sensitive 'yes'
zstyle ':prezto:*:*' color 'yes'

zplugin snippet PZT::modules/environment/init.zsh

zplugin snippet PZT::modules/helper/init.zsh

zstyle ':prezto:module:terminal' auto-title 'yes'
zstyle ':prezto:module:terminal:window-title' format '%n@%m: %s'
zstyle ':prezto:module:terminal:tab-title' format '%m: %s'
zplugin snippet PZT::modules/terminal/init.zsh

zstyle ':prezto:module:editor' key-bindings 'vi'
zplugin snippet PZT::modules/editor/init.zsh

zplugin snippet PZT::modules/history/init.zsh

zplugin snippet PZT::modules/directory/init.zsh

zplugin snippet PZT::modules/spectrum/init.zsh

zplugin ice svn
zplugin snippet PZT::modules/utility

zplugin ice svn
zplugin snippet PZT::modules/git
# gls is Used for GNU ls from coreutils brew package on OSX
unalias gls

zplugin ice svn \
atclone'git clone https://github.com/zsh-users/zsh-completions; for i in external/*.zsh; do zcompile $i; done;' \
atpull'cd ./external; git reset --hard HEAD; git pull; for i in ./*.zsh; do zcompile $i; done;' wait'0' lucid
zplugin snippet PZT::modules/completion

zplugin ice wait'0' lucid
zplugin light zdharma/fast-syntax-highlighting

if [[ -f $HOME/.zsh_prompt/prompt_w0ng_setup ]]; then
  fpath=($HOME/.zsh_prompt $fpath)
  autoload -Uz $HOME/.zsh_prompt/prompt_w0ng_setup
  autoload -Uz promptinit && promptinit
  prompt w0ng
fi

#
# Aliases
#

alias cdd="cd $HOME/dev"
alias dc="docker-compose"
alias gcM='git commit --amend --message'
alias gist="gist -p"
#alias ls='/usr/local/bin/gls --group-directories-first --color=auto --classify --human-readable'
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

if [[ -s "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi


# Manually set node version path to reduce load time:
# https://github.com/creationix/nvm/issues/860
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  path=(
    $HOME/.nvm/versions/node/v12.14.0/bin
    $path
  )
  source "$HOME/.nvm/nvm.sh" --no-use
fi
