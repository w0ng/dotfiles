#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -d ~/.gem/ruby/1.9.1/bin ]] && export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin
[[ -d ~/scripts ]] && export PATH=$PATH:$HOME/scripts
export EDITOR="vim"
