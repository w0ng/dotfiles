#
# Two-line prompt rendered by zsh itself, with the git segment queried
# asynchronously.
#
# A synchronous `git status` takes hundreds of milliseconds in a large
# repository, which is long enough to feel on every prompt. Here it runs in a
# background job, so the prompt draws immediately and the segment fills in when
# the answer arrives.
#
# The async mechanism is `zle -F`, built into zsh. It watches a file descriptor
# and runs a widget when it becomes readable. No plugin required.
#
# The status indicators need a Nerd Font.
#

setopt prompt_subst
autoload -Uz add-zsh-hook

typeset -g _prompt_git=''      # rendered git segment, filled asynchronously
typeset -g _prompt_git_fd=0    # read end of the in-flight query
typeset -g _prompt_git_pid=0   # the forked child, so it can be killed

# Cancel an in-flight query. Closing the descriptor alone leaves the child
# running, so moving quickly between directories would pile up orphaned
# `git status` processes in a repository large enough for them to be slow.
_prompt_git_cancel() {
  (( _prompt_git_fd )) || return 0
  zle -F $_prompt_git_fd 2>/dev/null
  exec {_prompt_git_fd}<&- 2>/dev/null
  (( _prompt_git_pid )) && kill -TERM $_prompt_git_pid 2>/dev/null
  _prompt_git_fd=0
  _prompt_git_pid=0
}

_prompt_git_reap() {
  local fd=$1 line
  IFS= read -r line <&$fd
  zle -F $fd
  exec {fd}<&-
  (( fd == _prompt_git_fd )) && { _prompt_git_fd=0; _prompt_git_pid=0 }
  _prompt_git=$line
  # Redrawing while a line is being edited disturbs ZLE, so only redraw when
  # the buffer is empty.
  zle && [[ -z $BUFFER ]] && zle reset-prompt
}

_prompt_git_start() {
  _prompt_git_cancel
  _prompt_git=''
  # coproc rather than <(...), because process substitution does not set $!, so
  # there would be no pid to kill when the next prompt cancels this query.
  #
  # A coproc is a job, so without no_monitor/no_notify zsh reports it starting
  # and finishing around every prompt.
  setopt local_options no_monitor no_notify
  coproc {
    local d sha head='' ab='' state='' pos='' ln xy
    local added='' modified='' deleted='' renamed='' unmerged='' untracked=''
    local stashed='' ahead='' behind=''
    local -a rp f

    # rev-parse reads refs, never the working tree, so both of these are O(1)
    # however large the repository is; asking for them together keeps it to one
    # process. With no commits yet --short HEAD fails, but the git dir is still
    # printed first, which is all the in-progress checks below need.
    rp=(${(f)"$(command git rev-parse --git-dir --short HEAD 2>/dev/null)"})
    d=${rp[1]:-}
    sha=${rp[2]:-}
    [[ -n $d ]] || exit 0

    # One status call carries the branch, its divergence from upstream, the
    # stash count and every file state, replacing what would otherwise be
    # separate symbolic-ref, rev-list, stash list and status invocations. It is
    # also the only command here that walks the working tree, so it is the only
    # one whose cost grows with the size of the repository.
    #
    # --no-optional-locks stops it refreshing the index on the way through, so
    # a prompt firing in the background cannot contend for the index lock with
    # a git command running in the foreground.
    while IFS= read -r ln; do
      case $ln in
        ('# branch.head '*) head=${ln#\# branch.head } ;;
        ('# branch.ab '*)   ab=${ln#\# branch.ab } ;;
        ('# stash '*)       stashed='%F{6}󰌨%f' ;;
        ('? '*)             untracked='%F{7}%f' ;;
        ('u '*)             unmerged='%F{3}󰇼%f' ;;
        ('1 '*|'2 '*)
          # Field 2 is the two-letter <staged><unstaged> code, and a "2" line
          # is a rename or copy.
          xy=${ln[3,4]}
          [[ $ln == '2 '* || $xy == *R* ]] && renamed='%F{5}󰁕%f'
          [[ ${xy[1]} == A ]]              && added='%F{2}󱇬%f'
          [[ $xy == *D* ]]                 && deleted='%F{1}󱎘%f'
          [[ $xy == *[MT]* ]]              && modified='%F{4}%f'
          ;;
      esac
    done < <(command git --no-optional-locks status \
               --porcelain=v2 --branch --show-stash 2>/dev/null)
    [[ -n $head ]] || exit 0

    if [[ $head == '(detached)' ]]; then
      head=" ${sha}"
      # Worth asking only when detached, and only names an exact tag.
      pos=$(command git describe --tags --exact-match HEAD 2>/dev/null) \
        && pos=" %F{3} ${pos}%f"
    else
      head=" ${head}"
    fi

    # branch.ab is "+<ahead> -<behind>", and is absent when there is no
    # upstream to compare against.
    if [[ -n $ab ]]; then
      [[ ${${ab%% *}#+} != 0 ]] && ahead='%F{3}󰁞%f'
      [[ ${${ab##* }#-} != 0 ]] && behind='%F{3}󰁆%f'
    fi

    # In-progress operations, read directly from .git rather than by running
    # git. These are the same files git's own git-prompt.sh reads, including
    # the rebase progress counters.
    if [[ -d $d/rebase-merge ]]; then
      state=REBASE
      [[ -f $d/rebase-merge/msgnum && -f $d/rebase-merge/end ]] \
        && state="REBASE $(<$d/rebase-merge/msgnum)/$(<$d/rebase-merge/end)"
    elif [[ -d $d/rebase-apply ]]; then
      state=REBASE
      [[ -f $d/rebase-apply/next && -f $d/rebase-apply/last ]] \
        && state="REBASE $(<$d/rebase-apply/next)/$(<$d/rebase-apply/last)"
    elif [[ -f $d/MERGE_HEAD ]];       then state=MERGE
    elif [[ -f $d/CHERRY_PICK_HEAD ]]; then state=CHERRY-PICK
    elif [[ -f $d/REVERT_HEAD ]];      then state=REVERT
    elif [[ -f $d/BISECT_LOG ]];       then state=BISECT
    fi
    [[ -n $state ]] && state=" %F{3} ${state}%f"

    # Working-tree state first, upstream last, so the two never interleave.
    # This is starship's ALL_STATUS_FORMAT order followed by ahead/behind.
    #
    # Space-separated for more than legibility: Ghostty shrinks a Nerd Font
    # glyph to fit one cell only when the neighbouring cell is occupied, so the
    # gap is what keeps each icon at full size.
    f=("$unmerged" "$stashed" "$deleted" "$renamed" "$modified"
       "$added" "$untracked" "$ahead" "$behind")
    f=(${(@)f:#})
    local flags="${(j: :)f}"
    [[ -n $flags ]] && flags=" ${flags}"
    print -r -- " ${head}${state}${pos}${flags} "
  }
  _prompt_git_pid=$!
  disown %+ 2>/dev/null
  exec {_prompt_git_fd}<&p
  zle -F $_prompt_git_fd _prompt_git_reap
}

_prompt_precmd() { _prompt_git_start }

add-zsh-hook precmd _prompt_precmd

# Vi mode indicator: zsh-vi-mode publishes the current mode in $ZVM_MODE.
# Red in normal mode, green in insert.
_prompt_char() {
  if [[ ${ZVM_MODE:-} == $ZVM_MODE_NORMAL ]]; then
    print -n '%F{red}'
  else
    print -n '%F{green}'
  fi
  print -n '%B $%b%f'
}

# Colours are given as 16-colour palette indices so they follow the terminal
# theme instead of hard-coding hex values: 15 is bright-white, 7 white, 8
# bright-black.
#
# Indices rather than names because zsh has no `bright-white` colour name, and
# an unrecognised name silently resolves to the default foreground rather than
# raising an error.
PS1='%K{black}%B%F{15} %n@%m %f%b%k%K{8}%B%F{15} %~ %f%b%k%K{black}%B%F{7}${_prompt_git}%f%b%k
$(_prompt_char) '

# When the prompt was drawn, so that scrollback from a session left open for
# days still says which day each command belongs to.
#
# zsh places RPROMPT on the last line of a multi-line prompt and handles both
# the right-alignment and the reflow on resize. transient_rprompt must stay
# unset, because it clears the right prompt once a command runs, which is
# precisely when the timestamp starts being useful.
RPROMPT='%F{8}%D{%d %b %H:%M}%f'
