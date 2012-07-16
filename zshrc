# 
# ~/.zshrc
#

# disable xon/xoff (ctrl+s/q)
stty -ixon

# functions
autoload -U compinit && compinit
autoload -U colors && colors

# options
setopt correct
setopt extended_glob
setopt extended_history share_history
setopt hist_find_no_dups hist_ignore_dups hist_verify
setopt prompt_subst

# completion files
source $HOME/.config/git-completion.bash
source /usr/bin/virtualenvwrapper.sh

# ls colours
eval $(dircolors -b $HOME/.dir_colours)

# tab completion
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# autocorrect
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:match:*' original only
# increase max-errors based on length of word
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'
# kill
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#) ([0-9a-z-]#)*=$color[green]=0=$color[black]"
zstyle ':completion:*:*:kill:*' force-list always

# change cursor colour depending on vi mode
# TODO: make this work for tmux
zle-keymap-select () {
  if [ "$TERM" = "rxvt-unicode-256color" ]; then
    if [ $KEYMAP = vicmd ]; then
      echo -ne "\033]12;red\007"
    else
      echo -ne "\033]12;grey\007"
    fi
  fi
}; zle -N zle-keymap-select
zle-line-init () {
  zle -K viins
  echo -ne "\033]12;grey\007"
}; zle -N zle-line-init

# keybindings
bindkey "\e[1~" beginning-of-line # Home (tmux)
bindkey "\e[2~" quoted-insert # Ins
bindkey "\e[3~" delete-char # Del
bindkey "\e[4~" end-of-line # End (tmux)
bindkey "\e[5~" beginning-of-history # PgUp
bindkey "\e[6~" end-of-history # PgDn
bindkey "\e[7~" beginning-of-line # Home (rxvt)
bindkey "\e[8~" end-of-line # End (rxvt)
bindkey "\e[Z" reverse-menu-complete # Shift+Tab
bindkey "^[[A" up-line-or-search # Up
bindkey "^[[B" down-line-or-search # Down
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey ' ' magic-space
bindkey "^?" backward-delete-char
bindkey -M viins "^N" down-line-or-search
bindkey -M viins "^P" up-line-or-search
bindkey -M viins "jj" vi-cmd-mode
bindkey -M vicmd "/" history-incremental-search-backward
bindkey -M vicmd "?" history-incremental-search-forward

# history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=$HOME/.logs/zhistory

# prompt
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto"
PROMPT='%{$fg[black]%}┌─[%{$fg[yellow]%}%~%{$fg[black]%}]$(__git_ps1 "\e[0;30m[\e[0;31m%s\e[0;30m]")
└─╼%{$reset_color%} '
#RPROMPT='%{$fg[black]%}[%{$fg[red]%}%?%{$fg[black]%}]%{$reset_color%}'
SPROMPT="Correct $fg[red]%R$reset_color to $fg[green]%r?$reset_color (Yes, No, Abort, Edit) "

# aliases
alias ls="ls -hF --color=always --group-directories-first --time-style=+'$fg_bold[white]%d-%m-%y %H:%M$reset_color'"
alias ll="ls++"
alias grep="grep --color=auto"
alias pacman="pacman-color"
alias sprunge="curl -F 'sprunge=<-' http://sprunge.us"
alias tm="tmux attach-session -d -t 0"
alias usbmount="sudo ntfs-3g -o gid=100,fmask=113,dmask=002 /dev/sde1 /mnt/usb"
alias usbumount="sudo umount /mnt/usb"

# dynamic window title
case $TERM in
  xterm*|rxvt*)
    precmd () { print -Pn "\e]0;%n@%M:%~\a" }
    preexec () { print -Pn "\e]0;%n@%M:%~ ($1)\a" }
    ;;
  screen*)
    precmd () {
      print -Pn "\e]83;title - \"$1\"\a"
      print -Pn "\e]0;%n@%M:%~\a"
    }
    preexec () {
      print -Pn "\e]83;title - \"$1\"\a"
      print -Pn "\e]0;%n@%M:%~ ($1)\a"
    }
    ;;
esac

# extract (https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/extract)
function extract() {
  local remove_archive
  local success
  local file_name
  local extract_dir

  if (( $# == 0 )); then
    echo "Usage: extract [-option] [file ...]"
    echo
    echo Options:
    echo " -r, --remove Remove archive."
    echo
    echo "Report bugs to <sorin.ionescu@gmail.com>."
  fi

  remove_archive=1
  if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi

  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" 1>&2
      shift
      continue
    fi

    success=0
    file_name="$( basename "$1" )"
    extract_dir="$( echo "$file_name" | sed "s/\.${1##*.}//g" )"
    case "$1" in
      (*.tar.gz|*.tgz) tar xvzf "$1" ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
      (*.tar.xz|*.txz) tar --xz --help &> /dev/null \
        && tar --xz -xvf "$1" \
        || xzcat "$1" | tar xvf - ;;
      (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null \
        && tar --lzma -xvf "$1" \
        || lzcat "$1" | tar xvf - ;;
      (*.tar) tar xvf "$1" ;;
      (*.gz) gunzip "$1" ;;
      (*.bz2) bunzip2 "$1" ;;
      (*.xz) unxz "$1" ;;
      (*.lzma) unlzma "$1" ;;
      (*.Z) uncompress "$1" ;;
      (*.zip) unzip "$1" -d $extract_dir ;;
      (*.rar) unrar e -ad "$1" ;;
      (*.7z) 7za x "$1" ;;
      (*.deb)
        mkdir -p "$extract_dir/control"
        mkdir -p "$extract_dir/data"
        cd "$extract_dir"; ar vx "../${1}" > /dev/null
        cd control; tar xzvf ../control.tar.gz
        cd ../data; tar xzvf ../data.tar.gz
        cd ..; rm *.tar.gz debian-binary
        cd ..
        ;;
      (*)
        echo "extract: '$1' cannot be extracted" 1>&2
        success=1
        ;;
    esac

    (( success = $success > 0 ? $success : $? ))
    (( $success == 0 )) && (( $remove_archive == 0 )) && rm "$1"
    shift
  done
}
