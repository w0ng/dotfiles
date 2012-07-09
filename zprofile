#
# ~/.zprofile
#

if [[ -z $DISPLAY ]] && ! [[ -e /tmp/.X11-unix/X0 ]] && (( EUID )); then
  eval $(keychain --eval --agents ssh -Q --quiet id_rsa) && exec startx
fi
