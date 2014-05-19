"
" ~/.vimrc
"
" Comptability {{{
" -----------------------------------------------------------------------------
"
set nocompatible         " use vim defaults instead of vi
set encoding=utf-8       " always encode in utf

"}}}
" Install Plugins {{{
" -----------------------------------------------------------------------------

filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
" https://github.com/*
Bundle 'Lokaltog/vim-powerline'
Bundle 'Raimondi/delimitMate'
Bundle 'Shougo/neocomplete'
Bundle 'godlygeek/tabular'
Bundle 'hynek/vim-python-pep8-indent'
Bundle 'kien/ctrlp.vim'
Bundle 'mileszs/ack.vim.git'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-surround'
Bundle 'w0ng/vim-hybrid'

"}}}
" Settings {{{
" -----------------------------------------------------------------------------

" File detection
filetype plugin indent on
syntax on

" General
set backspace=2           " enable <BS> for everything
set colorcolumn=80        " visual indicator of column
set completeopt-=preview  " dont show preview window
set fcs=vert:│,fold:-     " solid instead of broken line for vert splits
set grepprg=grep\ -nH\ $* " always generate a filename, for vim-latexsuite
set hidden                " hide when switching buffers, don't unload
set laststatus=2          " always show status line
set lazyredraw            " don't update screen when executing macros
set mouse=a               " enable mouse in all modes
set noshowmode            " don't show mode, since I'm already using powerline
set nowrap                " disable word wrap
set number                " show line numbers
set showcmd               " show command on last line of screen
set showmatch             " show bracket matches
set spelllang=en_au       " spell check with Australian English
set spellfile=~/.vim/spell/en.utf-8.add
set textwidth=0           " don't break lines after some maximum width
set ttyfast               " increase chars sent to screen for redrawing
"set ttyscroll=3           " limit lines to scroll to speed up display
set title                 " use filename in window title
set wildmenu              " enhanced cmd line completion

" Folding
set foldignore=           " don't ignore anything when folding
set foldlevelstart=99     " no folds closed on open
set foldmethod=marker     " collapse code using markers
set foldnestmax=1         " limit max folds for indent and syntax methods

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
let g:hybrid_use_Xresources = 1
colorscheme hybrid

" gVim
if has('gui_running')
    set guifont=Inconsolata\-g\ 10.5
    set guioptions-=m               " remove menu
    set guioptions-=T               " remove toolbar
    set guioptions-=r               " remove right scrollbar
    set guioptions-=b               " remove bottom scrollbar
    set guioptions-=L               " remove left scrollbar
    set guicursor+=a:block-blinkon0 " always use block cursor, no cursor blinking
    " Paste from PRIMARY and CLIPBOARD
    inoremap <silent> <M-v> <Esc>"+p`]a
    inoremap <silent> <S-Insert> <Esc>"*p`]a
endif

" vimdiff
if &diff
    set diffopt=filler,foldcolumn:0
endif

"}}}
" Mappings {{{
" -----------------------------------------------------------------------------

" Map leader
let mapleader = ','

" Exit insert mode
inoremap jj <esc>

" Toggle fold
nnoremap <space> za

" Toggle spellcheck
nnoremap <leader>s :set spell!<CR>

" Toggle hlsearch for current results
nnoremap <leader><leader> :nohlsearch<CR>

" Search for trailing whitespace
nnoremap <leader>w /\s\+$<CR>

" Toggle last active buffer
nnoremap <leader><Tab> :b#<CR>

" Switch colon and semi-colon
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Split windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <SID>disable_imaps.vim_remapping_C-j <Plug>IMAP_JumpForward

" Paste mode for terminals
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>

" Toggle between light and dark colour schemes
nnoremap <F4> :call ToggleColours()<CR>

" Shortcut to ack plugin
nnoremap <leader>a :Ack<Space>

" View javadoc of element under cursor
nnoremap <leader>d :JavaDocPreview<CR>

" Insert timestamp
nnoremap <leader>t "=strftime("%F %R")<CR>p
nnoremap <leader>T "=strftime("%F %R")<CR>P

" Search and open buffer, files, recent
nnoremap <leader>b :CtrlPBuffer<CR>
nnoremap <leader>f :CtrlP<CR>
nnoremap <leader>r :CtrlPMRUFiles<CR>

"}}}
" Plugin Settings {{{
" -----------------------------------------------------------------------------
let g:ackprg = 'ag --nogroup --nocolor --column'
let g:ctrlp_custom_ignore = {
            \ 'dir':  '\.git$\|\.hg$\|\.svn$\|__pycache__$',
            \ 'file': '\.pyc$\|\.so$\|\.swp$',
            \ }
let delimitMate_expand_cr = 1
let g:tex_flavor='latex'
let g:Powerline_symbols = 'compatible'

" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
    \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplete#close_popup() . "\<CR>"
  " For no inserting <CR> key.
  "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"

" For cursor moving in insert mode(Not recommended)
"inoremap <expr><Left>  neocomplete#close_popup() . "\<Left>"
"inoremap <expr><Right> neocomplete#close_popup() . "\<Right>"
"inoremap <expr><Up>    neocomplete#close_popup() . "\<Up>"
"inoremap <expr><Down>  neocomplete#close_popup() . "\<Down>"
" Or set this.
"let g:neocomplete#enable_cursor_hold_i = 1
" Or set this.
"let g:neocomplete#enable_insert_char_pre = 1

" AutoComplPop like behavior.
"let g:neocomplete#enable_auto_select = 1

" Shell like behavior(not recommended).
"set completeopt+=longest
"let g:neocomplete#enable_auto_select = 1
"let g:neocomplete#disable_auto_complete = 1
"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif
"let g:neocomplete#sources#omni#input_patterns.php =
"\ '[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'
"let g:neocomplete#sources#omni#input_patterns.c =
"\ '[^.[:digit:] *\t]\%(\.\|->\)\%(\h\w*\)\?'
"let g:neocomplete#sources#omni#input_patterns.cpp =
"\ '[^.[:digit:] *\t]\%(\.\|->\)\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'

" For perlomni.vim setting.
" https://github.com/c9s/perlomni.vim
"let g:neocomplete#sources#omni#input_patterns.perl =
"\ '[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'

" For smart TAB completion.
"inoremap <expr><TAB>  pumvisible() ? "\<C-n>" :
"        \ <SID>check_back_space() ? "\<TAB>" :
"        \ neocomplete#start_manual_complete()
"  function! s:check_back_space() "{{{
"    let col = col('.') - 1
"    return !col || getline('.')[col - 1]  =~ '\s'
"  endfunction"}}}


"}}}
" Autocommands {{{
" -----------------------------------------------------------------------------

" Omnicompletion
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown,xhtml setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=python3complete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Indent rules
autocmd FileType c setlocal noet ts=8 sw=8 sts=8
autocmd FileType css,html,htmldjango,javascript,php,xhtml setlocal ts=2 sw=2 sts=2
autocmd FileType markdown setlocal tw=79

" Folding rules
autocmd FileType c,cpp,java setlocal foldmethod=syntax foldnestmax=5
autocmd FileType css,html,htmldjango,xhtml setlocal foldmethod=indent foldnestmax=20

" Set correct markdown extensions
autocmd BufNewFile,BufRead *.markdown,*.md,*.mdown,*.mkd,*.mkdn
            \ if &ft =~# '^\%(conf\|modula2\)$' |
            \   set ft=markdown |
            \ else |
            \   setf markdown |
            \ endif

"}}}
" Functions {{{
" -----------------------------------------------------------------------------

function! ToggleColours()
    if g:colors_name == 'hybrid'
        colorscheme hybrid-light
    else
        colorscheme hybrid
    endif
endfunction

"}}}
