#!/usr/bin/env bash

# =============================================================================

echo "--- Installing NodeJS, Python3 and Ruby ---"

curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -

apt-get install -y \
    nodejs \
    python3 \
    ruby

# =============================================================================

echo "--- Installing tmux ---"

apt-get install -y tmux

cat <<'EOF' > /home/vagrant/.tmux.conf
#
# ~/.tmux.conf
#

# split windows like vim
# vim's definition of a horizontal/vertical split is reversed from tmux's
bind s split-window -v
bind v split-window -h

# move around panes with hjkl, as one would in vim after pressing ctrl-w
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# resize panes like vim
# feel free to change the "1" to however many lines you want to resize by, only
# one at a time can be slow
bind < resize-pane -L 1
bind > resize-pane -R 1
bind - resize-pane -D 1
bind + resize-pane -U 1

# bind : to command-prompt like vim
# this is the default in tmux already
bind : command-prompt

# vi-style controls for copy mode
set-window-option -g mode-keys vi

# change prefix key
unbind C-b
set-option -g prefix C-a

# status bar
set-option -g status-bg black
set-option -g status-fg white
set-option -g status-left ""
set-option -g status-right "#[bg=colour8]#[fg=brightwhite] #(cut -d ' ' -f 1-3 /proc/loadavg) #[bg=brightwhite]#[fg=black] #(whoami)@#H "
set-option -g status-right-length 60
set-window-option -g window-status-bell-fg black
set-window-option -g window-status-bell-bg brightred
set-window-option -g window-status-current-fg brightyellow

# dynamic window title
set-option -g set-titles on

# set first window to 1 instead of 0
set-option -g base-index 1

# correct term for 256 colours
set-option -g default-terminal "screen-256color"
EOF

chown vagrant:vagrant /home/vagrant/.tmux.conf
echo 'alias tm="tmux attach-session -d -t 0"' >> /home/vagrant/.bashrc
echo "tmux installed"

# =============================================================================

echo "--- Installing vim ---"

apt-get install -y vim

cat <<'EOF' > /home/vagrant/.vimrc
"
" ~/.vimrc
"
" Compatability
set nocompatible         " use vim defaults instead of vi
set encoding=utf-8       " always encode in utf
filetype plugin indent on
syntax on
" General
set backspace=2           " enable <BS> for everything
"set colorcolumn=80       " visual indicator of column
set completeopt-=preview  " dont show preview window
"set cursorline            " visual indicator of current line
set hidden                " hide when switching buffers, don't unload
set laststatus=2          " always show status line
set lazyredraw            " don't update screen when executing macros
"set mouse=a               " enable mouse in all modes
set showmode              " show mode in status line
set nowrap                " disable word wrap
set number                " show line numbers
set showcmd               " show command on last line of screen
set showmatch             " show bracket matches
set spelllang=en_au       " spell check with Australian English
set textwidth=0           " don't break lines after some maximum width
set ttyfast               " increase chars sent to screen for redrawing
"set ttyscroll=3           " limit lines to scroll to speed up display
set title                 " use filename in window title
set wildmenu              " enhanced cmd line completion
" Folding
set foldignore=           " don't ignore anything when folding
set foldlevelstart=99     " no folds closed on open
set foldmethod=indent     " collapse code using indent levels
set foldnestmax=20        " limit max folds for indent and syntax methods
" Tabs
set autoindent            " copy indent from previous line
set expandtab             " replace tabs with spaces
set shiftwidth=4          " spaces for autoindenting
set smarttab              " <BS> removes shiftwidth worth of spaces
set softtabstop=4         " spaces for editing, e.g. <Tab> or <BS>
set tabstop=4             " spaces for <Tab>
" Searches
set hlsearch              " highlight search results
set incsearch             " search whilst typing
set ignorecase            " case insensitive searching
set smartcase             " override ignorecase if upper case typed
" Colours
set t_Co=256
set background=dark
" Copy to OSX CLIPBOARD
"vnoremap ,y "*y
" Vimdiff display
if &diff
    set diffopt=filler,foldcolumn:0
endif
EOF

chown vagrant:vagrant /home/vagrant/.vimrc
echo "Vim installed."

# =============================================================================

echo "--- Finalising installation ---"
updatedb && echo "mlocate DB updated."

# =============================================================================

echo "--- FINISHED ---"
SERVER_NAME="$1"
echo "View the dev site via http://${SERVER_NAME}"
