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
[[ -d /usr/share/fonts/local ]] && xset +fp /usr/share/fonts/local
[[ -d ~/.fonts ]] && xset +fp ~/.fonts
xset fp rehash

# turn monitor off after 60min
xset s off
xset dpms 3600 3600 3600

# start daemons
dropboxd &
mpd
urxvtd -q -o -f

# enable numlock
numlockx
# start tmux session in background
tmux &
# set WM to a name with Java recognises
wmname LG3D

# start WM
exec ~/bin/dwm-start
