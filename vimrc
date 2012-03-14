"
" ~/.vimrc
"

" enable file detection
filetype plugin indent on
syntax on
" turn off modelines to prevent security vulnerability
set nomodeline
" allow backspacing over indent,eol,start
set backspace=2
" number of spaces that <Tab> counts for
set tabstop=2
" number of spaces for (auto)indent
set shiftwidth=2
" spaces replace tabs
set expandtab
" backspace deletes shiftwidth worth of spaces
set smarttab
" show command in the last line of the screen
set showcmd
" show line numbers
set number
" show matching brackets
set showmatch
" higlight all search matches
set hlsearch
" search for pattern whilst typing
set incsearch
" ignore case in search patterns
set ignorecase
" ovreride ignorecase if search patterns contains an upper case char
set smartcase
" copy indent from previous line
set autoindent
" enable use of mouse
set mouse=a
" set filename to window title
set title
" comma separated list of screen columns
set colorcolumn=80
" higlight current line
set cursorline
" always show status line
set statusline=%F\ %y%r%m%=\ %c\ %l/%L\ %P
set laststatus=2
" toggle auto-indenting when pasting
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
" colors
colorscheme jellybeans
" set gvim font
if has('gui_running')
  set guifont=Terminus\ 9
  set guioptions-=m
  set guioptions-=T
endif
