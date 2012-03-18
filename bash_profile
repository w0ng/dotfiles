#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -d /usr/bin/vendor_perl ]] && export PATH=$PATH:/usr/bin/vendor_perl
[[ -d ~/.gem/ruby/1.9.1/bin ]] && export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin
[[ -d ~/scripts ]] && export PATH=$PATH:$HOME/scripts

export EDITOR="vim"
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'

eval $(keychain --eval --agents ssh -Q --quiet id_rsa)
