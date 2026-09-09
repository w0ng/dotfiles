#
# System environment variables
#
# Not an absolute path for EDITOR/VISUAL: the same value has to work under a
# Homebrew prefix on macOS and /usr/local on a Linux host.
#
export EDITOR='nvim'
export PAGER='less'
export VISUAL='nvim'

# -i case-insensitive search unless the pattern has uppercase; -R passes colour
# through; -F skips the pager entirely when the output fits one screen, so a
# short `--help` or `git branch` does not trap you in it. -F needed -X alongside
# on older less to stop it clearing the screen; not since 530, and this is 668.
export LESS='-i -R -F'

# Syntax-highlighted man pages. col -bx strips the overstrike backspaces groff
# emits for bold and underline, which would otherwise reach bat as literal text.
if (( $+commands[bat] )); then
  export MANPAGER="sh -c 'col -bx | bat --language man --plain'"
  export MANROFFOPT='-c'
fi

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

# Set unconditionally. The obvious `[[ -z "$LANG" ]]` guard is useless here,
# because /etc/zprofile runs first and already sets LANG=C.UTF-8 when it is
# empty, so the guard never passes and this locale never applied. C.UTF-8 sorts
# in byte order (caps before lowercase) and formats dates month-first.
export LANG='en_AU.UTF-8'

#
# Homebrew
#
# Sets PATH, MANPATH and the HOMEBREW_* variables. Apple Silicon only, so the
# prefix is hardcoded rather than probed. See CLAUDE.md. The -x test doubles as
# the platform guard, because a Linux host has no /opt/homebrew, so it skips.
#
# A managed Mac may already have done this from /etc/zprofile, which runs first.
# Harmless, because `typeset -U path` collapses the repeat, and this has to
# stay for any machine without that.
#
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

#
# Re-assert the user bin directories, after path_helper has had its say.
#
# /etc/zprofile runs `path_helper`, which rebuilds PATH with the system
# directories first and appends everything else, so on a login shell the
# entries .zshenv prepended end up behind /usr/bin. Anything placed in
# ~/.local/bin to shadow a system binary would silently lose.
#
# prepend_user_path and the list itself come from .zshenv, which zsh always
# sources before this file; the guard keeps .zprofile sourceable on its own.
# `typeset -U path` means re-prepending moves an entry to the front rather than
# duplicating it.
#
if (( $+functions[prepend_user_path] )); then
  prepend_user_path
fi

#
# JetBrains Toolbox
#
# Appended, not prepended, because these are generated launcher shims and
# should never shadow a real binary of the same name.
#
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
  path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")
fi
