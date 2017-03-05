"
" ~/.vimrc
" vim: fdm=marker

" Options - Compatibility {{{
" -----------------------------------------------------------------------------

set nocompatible           " Prefer Vim defaults over Vi-compatible defaults.
set encoding=utf-8         " Set the character encoding to UTF-8.
filetype plugin indent on  " Enable file type detection.
syntax on                  " Enable syntax highlighting.

"}}}
" Options - Appearance {{{
" -----------------------------------------------------------------------------

set background=dark        " Use colours that look good on a dark background.
set colorcolumn=100        " Show right column in a highlighted colour.
set completeopt-=preview   " Do not show preview window for ins-completion.
set diffopt+=foldcolumn:0  " Do not show fold indicator column in diff mode.
set history=10000          " Number of commands and search patterns to remember.
set laststatus=2           " Always show status line.
set linespace=9            " Increase line height spacing by pixels.
set noshowmode             " Do not show current mode on the last line.
set number                 " Precede each line with its line number.
set showcmd                " Show command on last line of screen.
set showmatch              " Show matching brackets.
set t_Co=256               " Set the number of supported colours.
set title                  " Set window title to 'filename [+=-] (path) - VIM'.
set ttyfast                " Indicate fast terminal more smoother redrawing.

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
  set guifont=Operator\ Mono\ Book:h17 " Set the font to use.
  set guioptions=                      " Remove all GUI components and options.
  set guicursor+=a:block-blinkon0      " Use non-blinking block cursor.

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

" Use Ag over Grep
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
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
" Plugin Settings - airline {{{
" -----------------------------------------------------------------------------

" Remove powerline separators.
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''

 " Use hybrid theme.
let g:airline_theme = 'hybridline'

"}}}
" Plugins - Install {{{
" -----------------------------------------------------------------------------

call plug#begin('~/.vim/plugged')

Plug 'Chiel92/vim-autoformat'         " Integrate external file formatters.
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --tern-completer' } " Code-completion maanger.
Plug 'benekastah/neomake'             " Asynchronous syntax checking with make.
Plug 'cakebaker/scss-syntax.vim'      " Improved SCSS syntax.
Plug 'ctrlpvim/ctrlp.vim'             " Fuzzy file, buffer, mru, tag finder.
Plug 'hail2u/vim-css3-syntax'         " Syntax for CSS3.
Plug 'jiangmiao/auto-pairs'           " Insert or delete brackets, parens, quotes in pair.
Plug 'junegunn/vim-easy-align'        " Text alignment by characters.
Plug 'mxw/vim-jsx'                    " React JSX syntax and indent.
Plug 'mattn/emmet-vim'                " HTML abbreviations.
Plug 'othree/html5.vim'               " Improved HTML5 syntax and omni completion.
Plug 'pangloss/vim-javascript'        " Improved JavaScript syntax and indents.
Plug 'plasticboy/vim-markdown'        " Markdown Vim Mode.
Plug 'scrooloose/nerdtree'            " File explorer window.
Plug 'ternjs/tern_for_vim', { 'do': 'npm install' } " Improved JavaScript omni completion.
Plug 'tpope/vim-commentary'           " Commenting made simple.
Plug 'tpope/vim-fugitive'             " Git wrapper.
Plug 'tpope/vim-repeat'               " Enable repeat for tpope's plugins.
Plug 'tpope/vim-surround'             " Quoting/parenthesizing made simple.
Plug 'vim-airline/vim-airline'        " Pretty statusline.
Plug 'vim-airline/vim-airline-themes' " Pretty statusline.
Plug 'w0ng/vim-hybrid'                " Dark colorscheme.

call plug#end()

"}}}
" Plugin Settings - autoformat {{{
" -----------------------------------------------------------------------------

" Set format programs:
" - https://github.com/beautify-web/js-beautify
" - https://github.com/jdorn/sql-formatter
" - https://github.com/phpfmt/php.tools
" - https://github.com/sass/sass
let g:formatdef_cssbeautify = '"css-beautify -s 2 -"'
let g:formatdef_fmtphar = '"fmt.phar --psr -o=- -"'
let g:formatdef_htmlbeautify = '"html-beautify -s 2 -"'
let g:formatdef_jsbeautify_js = '"js-beautify -a -s 2 -"'
let g:formatdef_jsbeautify_json = '"js-beautify -a -s 2 -b expand -"'
let g:formatdef_sassconvert = '"sass-convert -F scss -T scss"'
let g:formatdef_sqlformatter = '"sql-formatter"'
let g:formatters_css = ['cssbeautify']
let g:formatters_html = [ 'htmlbeautify']
let g:formatters_javascript = [ 'jsbeautify_js']
let g:formatters_json = [ 'jsbeautify_json']
let g:formatters_php = ['fmtphar']
let g:formatters_scss = ['sassconvert']
let g:formatters_sql = ['sqlformatter']

" Set file type and format file.
nnoremap <Leader>af :Autoformat<CR>
nnoremap <Leader>ac :set ft=css<CR>:Autoformat<CR>
nnoremap <Leader>ah :set ft=html<CR>:Autoformat<CR>
nnoremap <Leader>aj :set ft=javascript<CR>:Autoformat<CR>
nnoremap <Leader>ao :set ft=json<CR>:Autoformat<CR>
nnoremap <Leader>ap :set ft=php<CR>:Autoformat<CR>
nnoremap <Leader>as :set ft=sql<CR>:Autoformat<CR>

"}}}
" Plugin Settings - ctrlp {{{
" -----------------------------------------------------------------------------

" Use Ag over Grep
if executable('ag')
  let g:ctrlp_use_caching = 0
  let g:ctrlp_user_command = 'ag %s --follow --nocolor --nogroup -g ""'
  " let g:ctrlp_user_command_async = 1
endif

  let g:ctrlp_prompt_mappings = {
    \ 'PrtSelectMove("j")':   ['<c-n>'],
    \ 'PrtSelectMove("k")':   ['<c-p>'],
    \ 'PrtHistory(-1)':       ['<c-j>'],
    \ 'PrtHistory(1)':        ['<c-k>']
    \ }

let g:ctrlp_map  = '<Leader>p'
nnoremap <Leader>e :CtrlPBuffer<CR>

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
" Plugin Settings - hybrid {{{
" -----------------------------------------------------------------------------

let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1
try
  colorscheme hybrid
catch /:E185:/
  " Silently fail if hybrid theme is not installed.
endtry

" Custom gui highlights when using Operator Mono font
highlight Cursor guibg=#00ffff
highlight Comment gui=italic
highlight Type gui=italic

"}}}
" Plugin Settings - neomake {{{
" -----------------------------------------------------------------------------

" Use PSR2 standard with PHP CodeSniffer.
let g:neomake_php_phpcs_args_standard = 'PSR2'

" Use custom rule set with PHP Mess Detector:
" https://github.com/w0ng/dotfiles/blob/master/.phpmd.xml
let g:neomake_php_phpmd_maker = {
      \ 'args': ['%:p', 'text', '~/.phpmd.xml'],
      \ 'errorformat': '%E%f:%l%\s%m'
      \ }

" Execute syntax checkers on file save.
autocmd! BufWritePost * Neomake

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
