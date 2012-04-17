#
# ~/.zshenv
#

[[ -d /usr/bin/vendor_perl ]] && export PATH=$PATH:/usr/bin/vendor_perl
[[ -d $(ruby -rubygems -e "puts Gem.user_dir")/bin ]] && export PATH=$PATH:$(ruby -rubygems -e "puts Gem.user_dir")/bin
[[ -d ~/bin ]] && export PATH=$PATH:$HOME/bin

export BROWSER="firefox"
export EDITOR="vim"
export LESS="-R"
export MOZ_DISABLE_PANGO=1
export  WORKON_HOME="$HOME/.virtualenvs"
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'
