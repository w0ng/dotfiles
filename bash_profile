#
# ~/.bash_profile
#

[[ -d ~/.gem/ruby/1.9.1/bin ]] && export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin
[[ -d ~/scripts ]] && export PATH=$PATH:$HOME/scripts
[[ -f ~/.bashrc ]] && . ~/.bashrc
export EDITOR="vim"
eval $(keychain --eval --agents ssh -Q --quiet id_rsa)
