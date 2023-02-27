# Setup fzf
# ---------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

# Gruvbox dark color scheme
export FZF_DEFAULT_OPTS='
  --color fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
  --color info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54
'

# Use ripgrep for file searches
# export FZF_DEFAULT_COMMAND='rg --files --hidden --smart-case --color="never"'
# Use fd for file searches
export FZF_DEFAULT_COMMAND='fd --type file --hidden -L'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
