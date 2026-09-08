#
# $ZDOTDIR/.zshrc: interactive zsh configuration
#
# antidote manages the plugins (declared in $ZDOTDIR/.zsh_plugins.txt), atuin
# owns history search, and prompt.zsh in this directory renders the prompt.
#

#
# Plugin config that must be set BEFORE plugins load
#
# atuin prepends its own strategy when it initialises, so the effective value
# at runtime is `atuin history completion`, so atuin answers first and zsh's own
# history is the fallback.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# zsh-vi-mode: initialise at source time instead of on the first prompt, so the
# keybinding setup further down this file (fzf, atuin's ^R, the ^P/^N pair)
# lands on top of vi mode and survives. Together with loading the plugin before
# the ZLE-wrapping plugins, this also stops zsh-vi-mode from resetting
# zsh-autosuggestions / fast-syntax-highlighting.
ZVM_INIT_MODE=sourcing

#
# Antidote: plugin manager (https://antidote.sh), static-bundle pattern.
#
# .zsh_plugins.txt is compiled into a static .zsh_plugins.zsh that we source
# directly for fast startup, regenerated only when the .txt is newer. Guarded
# so the shell still works before antidote is installed.
#
# Cloning a missing bundle and printing the source lines share one stdout, so
# whatever git says while fetching lands in the file and the next shell tries
# to run it: an fsmonitor watcher announcing a new watch, a git wrapper
# announcing a request id. The first pass does the cloning with that output
# discarded, which leaves the second nothing to fetch and so nothing to say
# but the bundle itself. The GIT_CONFIG_* override then covers the writing
# pass, where a stray fsmonitor call would have no clone to hide behind.
#
# Probed rather than hardcoded, because antidote is a Homebrew formula on macOS
# but has no distro package on Linux, where it is a git clone under XDG data
# instead.
# The wrong path here is silent. Every plugin simply never loads.
#
ANTIDOTE_DIR=''
for _antidote_candidate in \
  /opt/homebrew/opt/antidote/share/antidote \
  /usr/local/opt/antidote/share/antidote \
  "${XDG_DATA_HOME:-$HOME/.local/share}/antidote"; do
  if [[ -e "$_antidote_candidate/antidote.zsh" ]]; then
    ANTIDOTE_DIR="$_antidote_candidate"
    break
  fi
done
unset _antidote_candidate

if [[ -n "$ANTIDOTE_DIR" ]]; then
  source "$ANTIDOTE_DIR/antidote.zsh"
  zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins"
  if [[ ! "${zsh_plugins}.zsh" -nt "${zsh_plugins}.txt" ]]; then
    antidote bundle <"${zsh_plugins}.txt" >/dev/null 2>&1
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor GIT_CONFIG_VALUE_0=false \
      antidote bundle <"${zsh_plugins}.txt" >|"${zsh_plugins}.zsh"
  fi
  source "${zsh_plugins}.zsh"
  unset zsh_plugins
fi

#
# Shell options
#

# History, kept in XDG state rather than $HOME. zsh does not create the
# directory itself and silently records nothing when it is missing, hence the
# mkdir.
# atuin keeps its own database; this file is what ^P/^N prefix search reads,
# and what SHARE_HISTORY passes between concurrent shells.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY        # record timestamp for each command
setopt INC_APPEND_HISTORY      # write commands as they're entered
setopt SHARE_HISTORY           # share history across sessions
setopt HIST_IGNORE_DUPS        # don't record an immediately-repeated command
setopt HIST_IGNORE_ALL_DUPS    # remove older duplicate of a re-entered command
setopt HIST_IGNORE_SPACE       # don't record lines starting with a space
setopt HIST_REDUCE_BLANKS      # trim superfluous blanks
setopt HIST_VERIFY             # don't auto-run a history expansion; edit it first

# Directories
setopt AUTO_CD                 # `foo/` is treated as `cd foo/`
setopt AUTO_PUSHD              # cd pushes onto the directory stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# General
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS    # allow `# comments` at an interactive prompt
setopt LONG_LIST_JOBS
setopt COMBINING_CHARS
setopt RC_QUOTES               # '' is a literal single quote inside '...'
unsetopt FLOW_CONTROL          # free up ^Q / ^S

#
# Vi mode comes from zsh-vi-mode, loaded via antidote and initialised at source
# time (see ZVM_INIT_MODE above). It owns the vi keymaps, the insert/normal
# cursor shapes and the key timeout, so this file sets none of them.
#

#
# LS_COLORS: gruvbox-dark via vivid, for eza, ls and the completion list.
# Cached, because `vivid generate` costs ~6ms a start and only changes when
# vivid does.
#
if (( $+commands[vivid] )); then
  _lscolors_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/lscolors"
  if [[ ! -s "$_lscolors_cache" || "$commands[vivid]" -nt "$_lscolors_cache" ]]; then
    [[ -d "${_lscolors_cache:h}" ]] || mkdir -p "${_lscolors_cache:h}"
    vivid generate gruvbox-dark >| "$_lscolors_cache"
  fi
  export LS_COLORS="$(<$_lscolors_cache)"
  unset _lscolors_cache
fi

#
# Completion styling. compinit itself is run by ez-compinit at the first prompt.
#
# Tab reaches fzf-tab indirectly. fzf.zsh, sourced further down, rebinds ^I to
# fzf-completion. But fzf-completion first saves whatever ^I was bound to into
# $fzf_default_completion and calls it whenever the line has no `**` trigger.
# That saved binding is fzf-tab-complete only because the plugin bundle is
# sourced before fzf.zsh, so the order of those two blocks is load-bearing.
#
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu no                              # fzf-tab owns the menu
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}       # colour candidates (the costly one)
zstyle ':fzf-tab:*' use-fzf-default-opts yes                # reuse gruvbox FZF_DEFAULT_OPTS
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

#
# Aliases
#
alias c='z'
alias ci='zi'
alias ga='git add'
alias gd='git diff'
alias gl="git log --graph --date=relative \
  --pretty=format:'%C(yellow)%h%C(auto)%d%C(reset) %s %C(dim brightcyan)%aN %C(dim brightblue)(%cd)%C(reset)'"
alias gll='git log'
alias gs='git status --short'
alias gsh='git show'
alias l="eza --group-directories-first --classify=auto --icons=auto"
alias ll="eza --group-directories-first --classify=auto --icons=auto -l"
alias lt="eza --group-directories-first --classify=auto --icons=auto --tree --level 3"
alias v="nvim"

#
# ^P/^N prefix search: type the start of a command, then step through only the
# history entries beginning with it, the middle gear between a bare Up arrow
# and atuin's ^R. Nothing else provides these, because zsh leaves ^P/^N at
# self-insert in viins, and neither zsh-vi-mode nor atuin binds them, so the
# autoload and `zle -N` are both needed to bring the widgets into existence.
#

autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey -M viins '^P' up-line-or-beginning-search

autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^N' down-line-or-beginning-search

#
# Source applications
#

# Sourced after the plugin bundle. See the completion note above.
if [[ -s "$HOME/.config/fzf/fzf.zsh" ]]; then
  source "$HOME/.config/fzf/fzf.zsh"
fi

#
# Shell integration for direnv, atuin and zoxide.
#
# Each publishes its integration by printing zsh source, so the obvious
# `eval "$(tool init zsh)"` forks and waits for a process before the first
# prompt can draw, three times over. What they print changes only when the
# binary does, so it is cached and re-read, the way LS_COLORS is above.
#
# Staleness is the binary's mtime, so a brew upgrade rebuilds the cache on the
# next shell. A tool that moves to a different prefix without getting a newer
# mtime would not, which `rm -rf ~/.cache/zsh` fixes.
#
_source_tool_init() {
  local name="$1"
  shift
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init-${name}.zsh"
  if [[ ! -s "$cache" || "$commands[$name]" -nt "$cache" ]]; then
    [[ -d "${cache:h}" ]] || mkdir -p "${cache:h}"
    "$@" >| "$cache"
  fi
  source "$cache"
}

if (( $+commands[direnv] )); then
  _source_tool_init direnv direnv hook zsh
fi

#
# Prompt: rendered by zsh, with the git segment queried asynchronously.
# See prompt.zsh for why it is not a prompt framework.
#
source "${ZDOTDIR:-$HOME}/prompt.zsh"

#
# History search: atuin (local-only), sourced after fzf so atuin's ^R wins over
# fzf's. --disable-up-arrow stops atuin claiming the Up arrow and vicmd `k`;
# ^P/^N it never binds either way.
#
if (( $+commands[atuin] )); then
  _source_tool_init atuin atuin init zsh --disable-up-arrow
fi

#
# zoxide jumps to frecently-visited directories. Left as `z`/`zi` rather than
# `--cmd cd`, which would replace cd with a function.
#
if (( $+commands[zoxide] )); then
  _source_tool_init zoxide zoxide init zsh
fi

unfunction _source_tool_init

#
# `y` runs yazi and leaves the shell in whatever directory yazi was browsing
# when it quit. yazi cannot do that itself, because it is a child process, so
# its own cd dies with it. Hence --cwd-file, which it writes on exit for the
# parent shell to read. Bound to `y` rather than `yazi` so the bare binary
# still behaves normally.
#
if (( $+commands[yazi] )); then
  y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    yazi "$@" --cwd-file="$tmp"
    # yazi writes the bare path, unterminated, and writes it even when the
    # directory never changed, so the comparison below is what detects "stay
    # put". Reading with `read -d ''` cannot, because with no NUL to find it
    # reports failure on every exit, which silently swallowed the cd.
    cwd="$(<"$tmp")"
    if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

#
# Machine-local zsh functions, one file per function, supplied by the private
# overlay. Autoloaded, so a file is read on first call rather than at every
# shell start, which makes this the right home for anything that has to run in
# the calling shell, such as a worktree picker that cd's. A script on PATH
# cannot, because it runs in a child process.
#
# compinit runs at the first prompt, after this, so the directory reaches fpath
# in time; it only claims files whose names start with `_`, so a plain function
# name cannot be taken for a completion. The (N) keeps an empty or absent
# directory from failing the glob and aborting the line.
#
user_functions="${ZDOTDIR:-$HOME}/functions"
if [[ -d "$user_functions" ]]; then
  fpath=("$user_functions" $fpath)
  autoload -Uz "$user_functions"/*(N:t)
fi
unset user_functions

#
# Machine-local interactive settings, supplied by the private overlay. The
# functions directory above covers anything that can be a function; this covers
# what cannot, such as an alias, an export or a tool's `eval` init.
#
# Sourced last, so what it sets wins over everything above, and kept as its own
# file rather than written inline, because .zshrc is a symlink into this repo,
# so an installer appending to it would commit employer settings to a public
# package. Reach is what chooses between this and .zshenv.local. Only shells
# that have a prompt read this one.
#
if [[ -r "${ZDOTDIR:-$HOME}/.zshrc.local" ]]; then
  source "${ZDOTDIR:-$HOME}/.zshrc.local"
fi
