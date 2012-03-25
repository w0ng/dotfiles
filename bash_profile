#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -d /usr/bin/vendor_perl ]] && export PATH=$PATH:/usr/bin/vendor_perl
[[ -d ~/.gem/ruby/1.9.1/bin ]] && export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin
[[ -d ~/bin ]] && export PATH=$PATH:$HOME/bin

export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'
export BROWSER="firefox"
export EDITOR="vim"
# ignore space and dups in bash history
export HISTCONTROL="ignoreboth"


eval $(keychain --eval --agents ssh -Q --quiet id_rsa)
