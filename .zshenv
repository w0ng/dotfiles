#
# ~/.zshenv
#

[[ -d $HOME/bin ]] && export PATH=$PATH:$HOME/bin
[[ -d $HOME/.rbenv/bin ]] && export PATH=$PATH:$HOME/.rbenv/bin
[[ -d $HOME/.rbenv/shims ]] && PATH=$HOME/.rbenv/shims:$PATH
[[ -d $(ruby -rubygems -e "puts Gem.user_dir")/bin ]] && export PATH=$PATH:$(ruby -rubygems -e "puts Gem.user_dir")/bin
[[ -d /usr/bin/vendor_perl ]] && export PATH=$PATH:/usr/bin/vendor_perl

export BROWSER="firefox"
export EDITOR="vim"
export LESS="-R"
export MOZ_DISABLE_PANGO=1
export PYTHONDOCS=/usr/share/doc/python/html
export PROJECT_HOME="$HOME/code/python"
export TERMCMD="urxvtc"
export WORKON_HOME="$HOME/.virtualenvs"
