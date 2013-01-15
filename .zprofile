#
# ~/.zprofile
#

# maintain single ssh-agent process on startup
eval $(keychain --eval --agents ssh -Q --quiet id_rsa)

# enable shims and autocompletion for rbenv
eval "$(rbenv init -)"
