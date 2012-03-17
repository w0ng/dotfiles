#
# ~/.bash_profile
#

[[ -d /usr/bin/vendor_perl ]] && export PATH=$PATH:/usr/bin/vendor_perl
[[ -d ~/.gem/ruby/1.9.1/bin ]] && export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin
[[ -d ~/scripts ]] && export PATH=$PATH:$HOME/scripts
[[ -f ~/.bashrc ]] && . ~/.bashrc
export EDITOR="vim"
eval $(keychain --eval --agents ssh -Q --quiet id_rsa)
