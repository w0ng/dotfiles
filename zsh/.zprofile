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
  "/opt/homebrew/opt/node@16/bin"
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

eval "$(/opt/homebrew/bin/brew shellenv)"

if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi
