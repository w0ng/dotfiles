#
# System environment variables
#
export EDITOR='/usr/local/bin/vim'
export LESS='-i -R'
export PAGER='less'
export VISUAL='/usr/local/bin/vim'

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

if [[ -d $HOME/code/bin ]]; then
  path=(
    $HOME/code/bin
    $path
  )
fi

if [[ -d $HOME/Library/Python/3.7/bin ]]; then
  path=(
    $HOME/Library/Python/3.7/bin
    $path
  )
fi
