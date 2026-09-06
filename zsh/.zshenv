#
# ZDOTDIR — the rest of the zsh config lives under ~/.config/zsh. This file
# cannot move there: zsh reads ~/.zshenv before it knows ZDOTDIR exists, so
# $ZDOTDIR/.zshenv is never sourced. .zprofile, .zshrc and .zsh_plugins.txt
# are read from ZDOTDIR once this is set.
#
export ZDOTDIR="$HOME/.config/zsh"

#
# Paths
#
# Set here rather than in .zprofile because every zsh needs them, login or not —
# multiplexer panes, and anything they launch such as nvim's language servers.
# `typeset -gU` keeps the arrays deduplicated across re-sourcing.
#
# Order in the list is priority order: the whole list is prepended in one go, so
# the first entry ends up first on PATH. Prepending one at a time in a loop
# would reverse it.
#
# On a login shell this order does NOT survive: /etc/zprofile runs
# path_helper after this file and rebuilds PATH with the system directories in
# front, which pushes all of these behind /usr/bin. .zprofile re-asserts the
# list for exactly that reason — see the matching block there.
#
typeset -gU cdpath fpath mailpath path

typeset -ga user_path_dirs=(
  "$HOME/.local/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.docker/bin"
)

#
# rustup's shims live in ~/.cargo/bin, but they only work once a toolchain is
# installed. A work machine has rustup provisioned with none, where every shim
# errors, so gate on the toolchain rather than on the directory.
#
rust_toolchains=("$HOME"/.rustup/toolchains/*(N))
if (( ${#rust_toolchains} )); then
  user_path_dirs+=("$HOME/.cargo/bin")
fi
unset rust_toolchains

# Only the ones that exist, so PATH holds no dead entries.
prepend_user_path() {
  local dir
  local -a found=()
  for dir in $user_path_dirs; do
    [[ -d "$dir" ]] && found+=("$dir")
  done
  (( ${#found} )) && path=($found $path)
}

#
# Machine-local environment, supplied by the private overlay. Read by every
# zsh, login or not, which is what decides a setting belongs here rather than in
# .zshrc.local — anything a language server or an agent has to inherit is set
# before any interactive shell exists.
#
# Sourced before PATH is assembled on purpose: appending to user_path_dirs here
# gets an entry the same existence check as the rest, and the same re-assert
# from .zprofile after path_helper would otherwise demote it.
#
if [[ -r "$ZDOTDIR/.zshenv.local" ]]; then
  source "$ZDOTDIR/.zshenv.local"
fi

prepend_user_path
