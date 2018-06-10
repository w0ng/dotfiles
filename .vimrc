"
" ~/.vimrc
" vim: fdm=marker

" Options - Compatibility {{{
" -----------------------------------------------------------------------------

if !has('nvim')
  set nocompatible           " Prefer Vim defaults over Vi-compatible defaults.
endif
set encoding=utf-8         " Set the character encoding to UTF-8.
filetype plugin indent on  " Enable file type detection.
syntax on                  " Enable syntax highlighting.

"}}}
" Options - Appearance {{{
" -----------------------------------------------------------------------------

set background=dark        " Use colours that look good on a dark background.
set colorcolumn=80         " Show right column in a highlighted colour.
set completeopt-=preview   " Do not show preview window for ins-completion.
set diffopt+=foldcolumn:0  " Do not show fold indicator column in diff mode.
set history=10000          " Number of commands and search patterns to remember.
set laststatus=2           " Always show status line.
set noshowmode             " Do not show current mode on the last line.
set number                 " Show the line number.
set relativenumber         " Show the line number relative to the cursorline.
set showcmd                " Show command on last line of screen.
set showmatch              " Show matching brackets.
set termguicolors          " Use gui vim colors in terminal vim.
set title                  " Set window title to 'filename [+=-] (path) - VIM'.

"}}}
" Options - Behaviour {{{
" -----------------------------------------------------------------------------

set backspace=2            " Allow <BS> and <Del> over everything.
set hidden                 " Hide when switching buffers instead of unloading.
set mouse=a                " Enable use of the mouse in all modes.
set nowrap                 " Disable word wrap.
set spelllang=en_au        " Check spelling in Australian English
set textwidth=0            " Do not break lines after a maximum width.
set wildmenu               " Use enhanced command-line completion.

"}}}
" Options - Folding {{{
" -----------------------------------------------------------------------------

" Default folding options.
set foldignore=            " Do not ignore any characters for indent folding.
set foldlevelstart=99      " Always start editing with all folds open.
set foldmethod=indent      " Form folds by lines with equal indent.
set foldnestmax=10         " Limit fold levels for indent and syntax folding.

" Folding options for specific file types.
autocmd FileType python setlocal foldnestmax=5
autocmd FileType c,cpp,java setlocal foldmethod=syntax foldnestmax=5
autocmd FileType markdown setlocal foldmethod=marker

"}}}
" Options - GUI {{{
" -----------------------------------------------------------------------------

if has('gui_running')
  set guifont=Inconsolata\ Regular:h20 " Set the font to use.
  set guioptions=                      " Remove all GUI components and options.
  set guicursor+=a:block-blinkon0      " Use non-blinking block cursor.
  set linespace=8                      " Increase line height spacing by pixels.

  " Paste from PRIMARY
  inoremap <silent> <S-Insert> <Esc>"*p`]a
  " Paste from CLIPBOARD
  inoremap <silent> <M-v> <Esc>"+p`]a
endif

"}}}
" Options - Indents and Tabs {{{
" -----------------------------------------------------------------------------

" Default indent and tab options.
set autoindent             " Copy indent from previous line.
set expandtab              " Replace tabs with spaces in Insert mode.
set shiftwidth=2           " Spaces for each (auto)indent.
set smarttab               " Insert and delete sw blanks in the front of a line.
set softtabstop=2          " Spaces for tabs when inserting <Tab> or <BS>.
set tabstop=2              " Spaces that a <Tab> in file counts for.

" Indent and tab options for specific file types.
autocmd FileType c,make setlocal noexpandtab shiftwidth=8 softtabstop=8 tabstop=8
autocmd FileType markdown,python,php setlocal shiftwidth=4 softtabstop=4 tabstop=4

"}}}
" Options - Searching {{{
" -----------------------------------------------------------------------------

set hlsearch               " Highlight search pattern results.
set ignorecase             " Ignore case of normal letters in a pattern.
set incsearch              " Highlight search pattern as it is typed.
set smartcase              " Override ignorecase if pattern contains upper case.

" Use ripgrep over grep
if executable('rg')
  set grepprg=set grepprg=rg\ --no-heading\ --vimgrep
endif

"}}}
" Mappings - General {{{
" -----------------------------------------------------------------------------

" Define <Leader> key.
let mapleader = ','
let maplocalleader = ','

" Exit insert mode.
inoremap jj <esc>

" Switch colon with semi-colon.
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Search command history matching current input.
cnoremap <C-N> <Down>
cnoremap <C-P> <Up>

" Stop the highlighting for the current search results.
nnoremap <Space> :nohlsearch<CR>

" Navigate split windows.
nnoremap <C-H> <C-W>h
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l

" Navigate buffers.
nnoremap ]b :bnext<CR>
nnoremap [b :bprevious<CR>
nnoremap <leader><Tab> :b#<CR>

" Navigate location list.
nnoremap ]l :lnext<CR>
nnoremap [l :lprevious<CR>

" Search for trailing spaces and tabs (mnemonic: 'g/' = go search).
nnoremap g/s /\s\+$<CR>
nnoremap g/t /\t<CR>

" Write current file as superuser.
cnoremap w!! w !sudo tee > /dev/null %

"}}}
" Mappings - Toggle Options {{{
" -----------------------------------------------------------------------------

" (mnemonic: 'co' = change option).
nnoremap com :set mouse=<C-R>=&mouse == 'a' ? '' : 'a'<CR><CR>
nnoremap con :set number!<CR>
nnoremap cop :set paste!<CR>
nnoremap cos :set spell!<CR>
nnoremap cow :set wrap!<CR>

"}}}
" Mappings - Clipboard {{{
" -----------------------------------------------------------------------------

" Cut to clipboard.
vnoremap <Leader>x "*x
nnoremap <Leader>x "*x

" Copy to clipboard.
vnoremap <Leader>c "*y
nnoremap <Leader>c "*y

" Paste from clipboard.
nnoremap <Leader>v "*p
vnoremap <Leader>v "*p
nnoremap <Leader><S-V> "*P
vnoremap <Leader><S-V> "*P

""}}}
" Plugins - Install {{{
" -----------------------------------------------------------------------------

call plug#begin('~/.vim/plugged')

Plug 'hail2u/vim-css3-syntax'         " Syntax for CSS3.
Plug '/usr/local/opt/fzf'             " CLI fuzzy finder.
Plug 'junegunn/fzf.vim'               " CLI fuzzy finder.
Plug 'junegunn/vim-easy-align'        " Text alignment by characters.
Plug 'mxw/vim-jsx'                    " React JSX syntax and indent.
Plug 'mattn/emmet-vim'                " HTML abbreviations.
Plug 'morhetz/gruvbox'                " Dark colorscheme.
Plug 'othree/html5.vim'               " Improved HTML5 syntax and omni completion.
Plug 'pangloss/vim-javascript'        " Improved JavaScript syntax and indents.
Plug 'plasticboy/vim-markdown'        " Markdown Vim Mode.
Plug 'scrooloose/nerdtree'            " File explorer window.
Plug 'tpope/vim-commentary'           " Commenting made simple.
Plug 'tpope/vim-fugitive'             " Git wrapper.
Plug 'tpope/vim-repeat'               " Enable repeat for tpope's plugins.
Plug 'tpope/vim-surround'             " Quoting/parenthesizing made simple.
Plug 'vim-airline/vim-airline'        " Pretty statusline.
Plug 'w0rp/ale'                       " Asynchronous lint engine.

" Async autocompletion.
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

call plug#end()

"}}}
" Plugin Settings - airline {{{
" -----------------------------------------------------------------------------

" Remove powerline separators.
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''

"}}}
" Plugin Settings - ale {{{
" -----------------------------------------------------------------------------

let g:ale_sign_column_always = 1

let g:ale_linters = {
  \   'graphql': ['eslint'],
  \   'javascript': ['eslint'],
  \   'typescript': ['eslint'],
  \   'css': ['stylelint'],
  \   'scss': ['stylelint']
\}

let g:ale_fixers = {
  \   'css': ['prettier'],
  \   'graphql': ['prettier'],
  \   'javascript': ['prettier'],
  \   'json': ['prettier'],
  \   'markdown': ['prettier'],
  \   'scss': ['prettier'],
  \   'typescript': ['prettier']
\}

nnoremap <Leader>af :ALEFix<CR>
nnoremap <Leader>ac :set ft=css<CR>:ALEFix<CR>
nnoremap <Leader>ah :set ft=html<CR>:ALEFix<CR>
nnoremap <Leader>aj :set ft=javascript<CR>:ALEFix<CR>
nnoremap <Leader>ao :set ft=json<CR>:ALEFix<CR>
nnoremap <Leader>as :set ft=scss<CR>:ALEFix<CR>
nnoremap <Leader>l :ALEToggle<CR>

"}}}
" Plugin Settings - deoplete {{{
" -----------------------------------------------------------------------------

" Use deoplete.
let g:deoplete#enable_at_startup = 1

" Use smartcase.
call deoplete#custom#option('smart_case', v:true)

" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> deoplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS>  deoplete#smart_close_popup()."\<C-h>"

" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function() abort
  return deoplete#close_popup() . "\<CR>"
endfunction

"}}}
" Plugin Settings - easy-align {{{
" -----------------------------------------------------------------------------

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

"}}}
" Plugin Settings - emmet {{{
" -----------------------------------------------------------------------------

" Enable just for HTML, CSS, and JavaScript
let g:user_emmet_install_global = 0
autocmd FileType css,html,javascript,javascript.jsx EmmetInstall
let g:user_emmet_expandabbr_key = '<C-e>'


"}}}
" Plugin Settings - fugitive {{{
" -----------------------------------------------------------------------------

" Toggle git-blame window
nnoremap <Leader>g :Gblame!<CR>

"}}}
" Plugin Settings - fzf {{{
" -----------------------------------------------------------------------------

let g:fzf_layout = { 'down': '10' }

" Use ripgrep instead of ag:
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>f :Rg<CR>
nnoremap <Leader>p :Files<CR>

"}}}
" Plugin Settings - gruvbox {{{
" -----------------------------------------------------------------------------

try
  colorscheme gruvbox
  highlight! link SignColumn Normal
catch /:E185:/
  " Silently fail if gruvbox theme is not installed.
endtry

"}}}
" Plugin Settings - jsx {{{
" -----------------------------------------------------------------------------

let g:jsx_ext_required = 1

"}}}
" Plugin Settings - LanguageServer {{{
" -----------------------------------------------------------------------------

let g:LanguageClient_autoStart = 1
let g:LanguageClient_serverCommands = {}

if executable('css-languageserver')
  let g:LanguageClient_serverCommands.css = ['css-languageserver', '--stdio']
  autocmd FileType css setlocal omnifunc=LanguageClient#complete
endif

if executable('html-languageserver')
  let g:LanguageClient_serverCommands.html = ['html-languageserver', '--stdio']
  autocmd FileType html setlocal omnifunc=LanguageClient#complete
endif

if executable('javascript-typescript-stdio')
  let g:LanguageClient_serverCommands.javascript = ['javascript-typescript-stdio']
  autocmd FileType javascript setlocal omnifunc=LanguageClient#complete
endif

"}}}
" Plugin Settings - nerdtree {{{
" -----------------------------------------------------------------------------

" Toggle NERD tree window.
nnoremap <Leader>1 :NERDTreeToggle<CR>

"}}}
" Plugin Settings - plug {{{
" -----------------------------------------------------------------------------

let g:plug_window = 'topleft new' " Open plug window in a horizontal split.

"}}}
