#
# fzf shell integration, sourced from .zshrc. The location is our choice.
# ~/.fzf.zsh was only ever a convention from fzf's own install script.
#

# Replaces sourcing completion.zsh and key-bindings.zsh by absolute path, so
# no Homebrew prefix is hardcoded. Binds Ctrl-T (files) and Alt-C (cd); its
# Ctrl-R binding is overridden later by atuin, which loads after this.
eval "$(fzf --zsh)"

# Gruvbox dark. fzf-tab reuses these through
# `zstyle ':fzf-tab:*' use-fzf-default-opts yes`.
export FZF_DEFAULT_OPTS='
  --color fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
  --color info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54
'

# -L follows symlinks. ~/.config is almost entirely stow symlinks into this
# repo, so without it fzf finds 3 files there, not 49.
export FZF_DEFAULT_COMMAND='fd --type file --hidden -L'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
