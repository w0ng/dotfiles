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
if [[ -d $HOME/Library/Python/3.7/bin ]]; then
  path=(
    $HOME/Library/Python/3.7/bin
    $path
  )
fi

if [[ -d /usr/local/share/android-sdk/platform-tools ]]; then
  path=(
    /usr/local/share/android-sdk/platform-tools
    $path
  )
fi

if [[ -d $HOME/bin ]]; then
  path=(
    $HOME/bin
    $path
  )
fi
