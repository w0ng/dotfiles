# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/andrew/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/andrew/.fzf/bin"
fi

# Man path
# --------
if [[ ! "$MANPATH" == */Users/andrew/.fzf/man* && -d "/Users/andrew/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/Users/andrew/.fzf/man"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/andrew/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/andrew/.fzf/shell/key-bindings.bash"

