#
# ~/.zprofile
#

# maintain single ssh-agent process on startup
eval $(keychain --eval --agents ssh -Q --quiet id_rsa)
