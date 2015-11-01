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
set colorcolumn=80         " Show right column in a highlighted colour.
set completeopt-=preview   " Do not show preview window for ins-completion.
set diffopt+=foldcolumn:0  " Do not show fold indicator column in diff mode.
set laststatus=2           " Always show status line.
set linespace=6            " Increase line height spacing by pixels.
set noshowmode             " Do not show current mode on the last line.
set number                 " Precede each line with its line number.
set showcmd                " Show command on last line of screen.
set showmatch              " Show matching brackets.
set title                  " Set window title to 'filename [+=-] (path) - VIM'.
set t_Co=256               " Set the number of supported colours.
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

let g:tex_flavor = 'latex' " Treat *.tex file extensions as LaTeX files.

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
" Options - Formatting {{{
" -----------------------------------------------------------------------------

" Requires https://github.com/beautify-web/js-beautify
if executable('js-beautify')
  autocmd FileType css setlocal equalprg=js-beautify\ --type=css\ -a\ -s\ 2\ -f\ -
  autocmd FileType html setlocal equalprg=js-beautify\ --type=html\ -a\ -f\ -
  autocmd FileType javascript setlocal equalprg=js-beautify\ -a\ -f\ -
  autocmd FileType json setlocal equalprg=js-beautify\ -a\ -s\ 2\ -f\ -
endif

" Requires https://github.com/phpfmt/php.tools
" if executable('fmt.phar')
"    autocmd FileType php setlocal equalprg=fmt.phar\ --psr\ --enable_auto_align\ -o=-\ -
" endif

" Requires https://github.com/FriendsOfPHP/PHP-CS-Fixer
" if executable('php-cs-fixer')
"   autocmd FileType php setlocal equalprg=php-cs-fixer\ fix\ -
" endif

" Requires https://github.com/hhatto/autopep8
if executable('autopep8')
  autocmd FileType python setlocal equalprg=autopep8\ -aa\ -
endif

" Requires https://github.com/andialbrecht/sqlparse
if executable('sqlformat')
  autocmd FileType sql setlocal equalprg=sqlformat\ -r\ -k\ upper\ -i\ lower\ -
endif

"}}}
" Options - GUI {{{
" -----------------------------------------------------------------------------

if has('gui_running')
  set guifont=Inconsolata:h18     " Set the font to use.
  set guioptions=                 " Remove all GUI components and options.
  set guicursor+=a:block-blinkon0 " Use non-blinking block cursor.

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
set shiftwidth=4           " Spaces for each (auto)indent.
set smarttab               " Insert and delete sw blanks in the front of a line.
set softtabstop=4          " Spaces for tabs when inserting <Tab> or <BS>.
set tabstop=4              " Spaces that a <Tab> in file counts for.

" Indent and tab options for specific file types.
autocmd FileType c,make setlocal noexpandtab shiftwidth=8 softtabstop=8 tabstop=8
autocmd FileType bash,json,less,sass,scss,sql,vim,zsh setlocal shiftwidth=2 softtabstop=2 tabstop=2

"}}}
" Options - Searching {{{
" -----------------------------------------------------------------------------

set hlsearch               " Highlight search pattern results.
set ignorecase             " Ignore case of normal letters in a pattern.
set incsearch              " Highlight search pattern as it is typed.
set smartcase              " Override ignorecase if pattern contains upper case.

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

" Search for trailing spaces and tabs.
nnoremap g/s /\s\+$<CR>
nnoremap g/t /\t<CR>

" Write current file as superuser.
cnoremap w!! w !sudo tee > /dev/null %

"}}}
" Mappings - Frequent Settings {{{
" -----------------------------------------------------------------------------

" Reformat current file.
nnoremap c=c :set ft=css<CR>gg=G
nnoremap c=h :set ft=html<CR>gg=G
nnoremap c=j :set ft=javascript<CR>gg=G
nnoremap c=o :set ft=json<CR>gg=G
nnoremap c=p :set ft=php<CR>gg=G
nnoremap c=s :set ft=sql<CR>gg=G

" Toggle options.
nnoremap cob :buffer#<CR>
nnoremap com :set mouse=<C-R>=&mouse == 'a' ? '' : 'a'<CR><CR>
nnoremap con :set number!<CR>
nnoremap cop :set paste!<CR>
nnoremap cos :set spell!<CR>
nnoremap cow :set wrap!<CR>

"}}}
" Mappings - Clipboard {{{
" -----------------------------------------------------------------------------

" Delete (cut) to clipboard.
vnoremap <Leader>x "*x
nnoremap <Leader>x "*x

" Yank (copy) to clipboard.
vnoremap <Leader>c "*y
nnoremap <Leader>c "*y

" Put (paste) from clipboard.
nnoremap <Leader>v "*p
vnoremap <Leader>v "*p

""}}}
" Plugins Install {{{
" -----------------------------------------------------------------------------

" Requires https://github.com/junegunn/vim-plug
call plug#begin('~/.vim/plugged/')

Plug 'LaTeX-Box-Team/LaTeX-Box'     " Set of LaTeX editing tools.
Plug 'Shougo/context_filetype.vim'  " Get current context for autocompletion.
Plug 'benekastah/neomake'           " Asynchronous syntax checking with make.
Plug 'bling/vim-airline'            " Pretty statusline.
Plug 'tpope/vim-commentary'         " Commenting made simple.
Plug 'tpope/vim-fugitive'           " Git wrapper.
Plug 'tpope/vim-repeat'             " Enable repeat for tpope's plugins.
Plug 'tpope/vim-surround'           " Quoting/parenthesizing made simple.
Plug 'w0ng/vim-hybrid'              " Dark colorscheme.
Plug 'godlygeek/tabular'            " Text filtering and alignment.
Plug 'hynek/vim-python-pep8-indent' " PEP8 compliant indentation.
Plug 'majutsushi/tagbar'            " Display tags in a split window.
Plug 'scrooloose/nerdtree'          " File explorer window.

" Plugins to enable only for Neovim.
if has('nvim')
  Plug 'Shougo/deoplete.nvim'       " Asynchronous auto completion.
endif

" Plugins to enable only for Vim and GUI Vim.
if !has('nvim')
  Plug 'Shougo/neocomplete.vim'     " Synchronous auto completion.
endif

" Plugins to enable only for terminal Vim and Neovim.
if !has('gui_running')
  Plug 'junegunn/fzf',              " Command-line fuzzy finder.
        \ { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'           " Set of mappsings and commands for fzf.
endif

call plug#end()

"}}}
" Plugin Settings - airline {{{
" -----------------------------------------------------------------------------

let g:airline_left_sep = ''        " Remove arrow symbols.
let g:airline_left_alt_sep = ''    " Remove arrow symbols.
let g:airline_right_sep = ''       " Remove arrow symbols.
let g:airline_right_alt_sep = ''   " Remove arrow symbols.
let g:airline_theme = 'hybridline' " Use hybrid theme.

"}}}
" Plugin Settings - deoplete {{{
" -----------------------------------------------------------------------------

if exists('plugs') && has_key(plugs, 'deoplete.nvim')
  let g:deoplete#enable_at_startup = 1 " Enable deoplete on startup.
  let g:deoplete#enable_smart_case = 1 " Enable smart case.

  " Tab completion.
  inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

  " On backspace, delete previous completion and regenerate popup.
  inoremap <expr><C-H> deoplete#mappings#smart_close_popup()."\<C-H>"
  inoremap <expr><BS> deoplete#mappings#smart_close_popup()."\<C-H>"
endif

"}}}
" Plugin Settings - fugitive {{{
" -----------------------------------------------------------------------------

" Toggle git-blame window
nnoremap <Leader>g :Gblame!<CR>

"}}}
" Plugin Settings - fzf {{{
" -----------------------------------------------------------------------------
let g:fzf_layout = { 'up': '12' } " Position the default fzf window layout.
let g:fzf_command_prefix = 'Fzf'  " Prefix fzf commands e.g. :FzfFiles.

if exists('plugs') && has_key(plugs, 'fzf.vim')
  " Open fzf window to search for files, tags and buffer.
  nnoremap <Leader>e :FzfBuffers<CR>
  nnoremap <Leader>o :FzfFiles<CR>
  nnoremap <Leader><S-O> :FzfTags<CR>
  nnoremap <Leader>r :FzfBTags<CR>
  nnoremap <Leader>f :FzfAg<CR>
endif

"}}}
" Plugin Settings - hybrid {{{
" -----------------------------------------------------------------------------

let g:hybrid_use_Xresources = 1   " Use iTerm2 colour palette.
"let $NVIM_TUI_ENABLE_TRUE_COLOR=1 " Use 24-bit color, supported in iTerm2 2.9.

try
  colorscheme hybrid
catch /:E185:/
  " Silently ignore if colorscheme not found.
endtry

"}}}
" Plugin Settings - latex-box {{{
" -----------------------------------------------------------------------------

let g:LatexBox_latexmk_async = 1 " Enable asynchronous Latex compilation.

""}}}
" Plugin Settings - neocomplete {{{
" -----------------------------------------------------------------------------

if exists('plugs') && has_key(plugs, 'neocomplete.vim')
  let g:neocomplete#enable_at_startup = 1 " Enable neocomplete on startup.
  let g:neocomplete#enable_smart_case = 1 " Enable smart case.

  " Tab completion.
  inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

  " On backspace, delete previous completion and regenerate popup.
  inoremap <expr><C-H> neocomplete#smart_close_popup()."\<C-H>"
  inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-H>"
endif

"}}}
" Plugin Settings - neomake {{{
" -----------------------------------------------------------------------------

if exists('plugs') && has_key(plugs, 'neomake')
  if has('nvim')
    " Execute syntax checkers on file save.
    autocmd! BufWritePost * Neomake
  endif
endif

"}}}
" Plugin Settings - nerdtree {{{
" -----------------------------------------------------------------------------

" Toggle NERD tree window.
nnoremap <Leader>1 :NERDTreeToggle<CR>

""}}}
" Plugin Settings - plug {{{
" -----------------------------------------------------------------------------

let g:plug_window = 'topleft new' " Open plug window in a horizontal split.

"}}}
" Plugin Settings - tabular {{{
" -----------------------------------------------------------------------------

" Format lines with Tabular.
nnoremap c=t :Tabular /
vnoremap c=t :Tabular /

"}}}
" Plugin Settings - tagbar {{{
" -----------------------------------------------------------------------------

let g:tagbar_left = 1 " Open the Tagbar window on the left side.

" Toggle Tagbar window.
nnoremap <Leader>2 :TagbarToggle<CR>

"}}}
