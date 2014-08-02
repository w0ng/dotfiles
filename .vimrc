"
" ~/.vimrc
"
" Comptability {{{
" -----------------------------------------------------------------------------
"
set nocompatible         " use vim defaults instead of vi
set encoding=utf-8       " always encode in utf

"}}}
" Vim Plugins {{{
" -----------------------------------------------------------------------------

set runtimepath+=/home/w0ng/.vim/bundle/neobundle.vim
call neobundle#begin(expand('/home/w0ng/.vim/bundle'))
NeoBundleFetch 'Shougo/neobundle.vim'
" Plugins from https://github.com/*
NeoBundle 'Raimondi/delimitMate'
NeoBundle 'Shougo/neocomplete'
NeoBundle 'Shougo/vimproc.vim', {
            \ 'build' : {
            \     'windows' : 'tools\\update-dll-mingw',
            \     'cygwin' : 'make -f make_cygwin.mak',
            \     'mac' : 'make -f make_mac.mak',
            \     'unix' : 'make -f make_unix.mak',
            \    },
            \ }
NeoBundle 'Shougo/unite.vim'
NeoBundle 'godlygeek/tabular'
NeoBundle 'hynek/vim-python-pep8-indent'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'tpope/vim-surround'
NeoBundle 'w0ng/vim-airline'
NeoBundle 'w0ng/vim-hybrid'
call neobundle#end()

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
set noshowmode            " don't show mode, since I'm already using airline
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
set shiftwidth=2          " spaces for autoindenting
set smarttab              " <BS> removes shiftwidth worth of spaces
set softtabstop=2         " spaces for editing, e.g. <Tab> or <BS>
set tabstop=2             " spaces for <Tab>

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
    set guifont=Inconsolata\ for\ Powerline\ 12
    set guioptions-=m               " remove menu
    set guioptions-=T               " remove toolbar
    set guioptions-=r               " remove right scrollbar
    set guioptions-=b               " remove bottom scrollbar
    set guioptions-=L               " remove left scrollbar
    set guicursor+=a:block-blinkon0 " use solid block cursor
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

" Search command history based on current input
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

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

" View javadoc of element under cursor
nnoremap <leader>d :JavaDocPreview<CR>

" Insert timestamp
nnoremap <leader>t "=strftime("%F %R")<CR>p
nnoremap <leader>T "=strftime("%F %R")<CR>P

" Search for files/buffers
nnoremap <leader>b :<C-u>Unite buffer<CR>
nnoremap <leader>f :<C-u>Unite file_rec/async:!<CR>
nnoremap <leader>g :<C-u>Unite grep:.<CR>

"}}}
" Plugin Settings {{{
" -----------------------------------------------------------------------------
let delimitMate_expand_cr = 1
let g:airline_inactive_collapse = 0
let g:airline_powerline_fonts = 1
let g:airline_theme = 'hybridline'
let g:tex_flavor = 'latex'

call unite#custom#profile('default', 'context', {
\   'start_insert': 1,
\   'winheight': 10,
\ })
if executable('ag')
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts =
                \ '-i --line-numbers --nocolor --nogroup --hidden'
    let g:unite_source_grep_recursive_opt = ''
    let g:unite_source_rec_async_command =
                \ 'ag --follow --nocolor --nogroup --hidden -g ""'
endif
call unite#filters#matcher_default#use(['matcher_fuzzy'])

let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
    \ }

if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()
imap <expr><CR> pumvisible() ? neocomplete#smart_close_popup() . "\<CR>"
            \ : "<Plug>delimitMateCR"
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr> <BS>  pumvisible() ? neocomplete#smart_close_popup()."\<BS>"
            \ : delimitMate#BS()
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()

if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

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
autocmd FileType cpp,java,markdown,php,python setlocal ts=4 sw=4 sts=4
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
