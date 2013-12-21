#
# ~/.zshrc
#

# Options {{{
# -----------------------------------------------------------------------------
#

stty -ixon
[[ -e "$HOME/.config/dir_colours" ]] && eval $(dircolors -b "$HOME/.config/dir_colours")

autoload -U compinit && compinit
autoload -U colors && colors
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search

setopt correct
setopt extended_glob
setopt extended_history share_history
setopt hist_find_no_dups hist_ignore_dups hist_verify
setopt prompt_subst

# }}}
# History {{{
# -----------------------------------------------------------------------------

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.logs/zhistory"

# }}}
# Completion {{{
# -----------------------------------------------------------------------------

[[ -n "$WORKON_HOME" ]] && (( $+commands[virtualenvwrapper.sh] )) && source "$commands[virtualenvwrapper.sh]"
[[ -f "/usr/share/git/git-prompt.sh" ]] && source "/usr/share/git/git-prompt.sh"
[[ -f "$HOME/.rbenv/completions/rbenv.zsh" ]] && source "$HOME/.rbenv/completions/rbenv.zsh"

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

# }}}
# Prompt {{{
# -----------------------------------------------------------------------------

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto"
PROMPT='%{$fg[black]%}┌─[%{$fg_bold[yellow]%}%~%{$reset_color$fg[black]%}]\
$(__git_ps1 "[$fg_bold[red]%s$reset_color$fg[black]]")
└─╼%{$reset_color%} '
SPROMPT="Correct $fg_bold[red]%R$reset_color to $fg_bold[green]%r$reset_color [nyae]? "


# }}}
# Title {{{
# -----------------------------------------------------------------------------

case "$TERM" in
  (x|a|ml|dt|E)term*|(u|)rxvt*)
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

# }}}
# Keybindings {{{
# -----------------------------------------------------------------------------

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${terminfo[kich1]}" ]] && bindkey "${terminfo[kich1]}" quoted-insert # Ins
[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char # Del
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line # Home
[[ -n "${terminfo[kend]}" ]] && bindkey "${terminfo[kend]}" end-of-line # End
[[ -n "${terminfo[kpp]}" ]] && bindkey "${terminfo[kpp]}" beginning-of-history # PgUp
[[ -n "${terminfo[knp]}" ]] && bindkey "${terminfo[knp]}" end-of-history # PgDn
[[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search # Up
[[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search # Down
[[ -n "${terminfo[kcub1]}" ]] && bindkey "${terminfo[kcub1]}" backward-char # Left
[[ -n "${terminfo[kcuf1]}" ]] && bindkey "${terminfo[kcuf1]}" forward-char # Right
[[ -n "${terminfo[kcbt]}" ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete # S-Tab

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey ' ' magic-space
bindkey '^?' backward-delete-char
bindkey -M viins '^N' down-line-or-beginning-search
bindkey -M viins '^P' up-line-or-beginning-search
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M vicmd '^R' redo
bindkey -M vicmd 'u' undo
bindkey -M vicmd '/' history-incremental-search-forward
bindkey -M vicmd '?' history-incremental-search-backward

# }}}
# Aliases {{{
# -----------------------------------------------------------------------------

alias cower="cower -c -v"
alias grep="grep --color=auto"
alias ix="curl -n -F 'f:1=<-' http://ix.io"
alias ls="ls -hF --color=auto --group-directories-first"
alias lsp="ls++"
alias luksmount="sudo cryptsetup luksOpen /dev/sde1 luksusb && sudo mount -o gid=100,fmask=113,dmask=002 /dev/mapper/luksusb /mnt/usb"
alias luksumount="sudo umount /mnt/usb && sudo cryptsetup luksClose /dev/mapper/luksusb"
alias ntfsmount="sudo ntfs-3g -o gid=100,fmask=113,dmask=002 /dev/sde1 /mnt/usb"
alias range="urxvtc -name ranger -e ranger"
alias sprunge="curl -F 'sprunge=<-' http://sprunge.us"
alias ts="scrot -cd 3 ~/pictures/tmp.png && imgurbash ~/pictures/tmp.png"
alias tm="urxvtc -name chatmail -e tmux attach-session -d -t 0"
alias usbmount="sudo mount -o gid=100,fmask=113,dmask=002 /dev/sde1 /mnt/usb"
alias usbumount="sudo umount /mnt/usb"

# }}}
# Extract {{{
# https://github.com/sorin-ionescu/prezto/blob/master/modules/archive/functions/extract
# -----------------------------------------------------------------------------

function extract() {
  local remove_archive
  local success
  local file_name
  local extract_dir

  if (( $# == 0 )); then
    cat >&2 <<EOF
usage: $0 [-option] [file ...]

options:
-r, --remove    remove archive
EOF
  fi

  remove_archive=1
  if [[ "$1" == "-r" || "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi

  while (( $# > 0 )); do
    if [[ ! -s "$1" ]]; then
      print "$0: file not valid: $1" >&2
      shift
      continue
    fi

    success=0
    file_name="${1:t}"
    extract_dir="${file_name:r}"
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
        print "$0: cannot extract: $1" >&2
        success=1
      ;;
    esac

    (( success = $success > 0 ? $success : $? ))
    (( $success == 0 )) && (( $remove_archive == 0 )) && rm "$1"
    shift
  done
}

# }}}
