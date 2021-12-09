#
# System environment variables
#
export EDITOR='/usr/local/bin/nvim'
export LESS='-i -R'
export PAGER='less'
export VISUAL='/usr/local/bin/nvim'

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

# Python
for dir (
  "/usr/local/share/android-sdk/platform-tools"
  "$HOME/Library/Python/3.7/bin"
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
