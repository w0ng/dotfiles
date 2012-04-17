#!/bin/sh
#
# ~/.xinitrc
#

# source xinitc.d scripts
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

# load .Xresources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# add font paths
xset fp default
[[ -d /usr/share/fonts/local ]] && xset +fp /usr/share/fonts/local
[[ -d ~/.fonts ]] && xset +fp ~/.fonts
xset fp rehash

# turn monitor off after 60min
xset s off
xset dpms 3600 3600 3600

# enable numlock
numlockx

# set WM to a name with Java recognises
wmname LG3D

# start apps in background (only if not already running)
list=(dropbox eggdrop mpd tmux urxvtd)  
for app in "${list[@]}"; do
  check=$(ps -C "$app" -opid=)
  if [[ -z "$check" ]]; then
    case "$app" in
      dropbox) dropboxd & ;;
      eggdrop) cd ~/.eggdrop && eggdrop eggdrop.conf & ;;
      mpd) mpd ;;
      tmux) tmux & ;;
      urxvtd) urxvtd -q -o -f ;;
    esac
  fi
done

# start WM
exec ~/bin/dwm-start
