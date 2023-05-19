#
# System environment variables
#
export EDITOR='/opt/homebrew/bin/nvim'
export LESS='-i -R'
export PAGER='less'
export VISUAL='/opt/homebrew/bin/nvim'

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

if [[ -z "$LANG" ]]; then
  export LANG='en_AU.UTF-8'
fi

if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

#
# Paths
#
typeset -gU cdpath fpath mailpath path

for dir (
  "$HOME/.cargo/bin"
  "$HOME/bin"
); do
  if [[ -d "$dir" ]]; then
    path=(
      "$dir"
      $path
    )
  fi
done

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
# Nix
export CANVA_NIXPKGS_SYSTEM=aarch64-darwin
export FORCE_NO_BAZEL_REMOTE_CACHE=true

eval "$(/opt/homebrew/bin/brew shellenv)"
