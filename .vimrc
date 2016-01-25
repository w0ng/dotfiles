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
set history=10000          " Number of commands and search patterns to remember.
set laststatus=2           " Always show status line.
set linespace=8            " Increase line height spacing by pixels.
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
" Options - GUI {{{
" -----------------------------------------------------------------------------

if has('gui_running')
  set guifont=InconsolataGo:h18   " Set the font to use.
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
autocmd FileType json,less,ruby,sass,scss,sql,vim,zsh setlocal shiftwidth=2 softtabstop=2 tabstop=2

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

" Delete (cut) to clipboard.
vnoremap <Leader>x "*x
nnoremap <Leader>x "*x

" Yank (copy) to clipboard.
vnoremap <Leader>y "*y
nnoremap <Leader>y "*y

" Put (paste) from clipboard.
nnoremap <Leader>p "*p
vnoremap <Leader>p "*p
nnoremap <Leader><S-P> "*P
vnoremap <Leader><S-P> "*P

""}}}
" Plugins Install {{{
" -----------------------------------------------------------------------------

" Requires https://github.com/junegunn/vim-plug
call plug#begin('~/.vim/plugged/')

Plug 'Chiel92/vim-autoformat'       " Integrate external code formatters.
Plug 'LaTeX-Box-Team/LaTeX-Box'     " Set of LaTeX editing tools.
Plug 'Shougo/context_filetype.vim'  " Get current context for autocompletion.
Plug 'benekastah/neomake'           " Asynchronous syntax checking with make.
Plug 'bling/vim-airline'            " Pretty statusline.
Plug 'cakebaker/scss-syntax.vim'    " Improved SCSS syntax.
Plug 'hail2u/vim-css3-syntax'       " Syntax for CSS3.
Plug 'hynek/vim-python-pep8-indent' " PEP8 compliant indentation.
Plug 'jelera/vim-javascript-syntax' " Improved JavaScript syntax.
Plug 'junegunn/vim-easy-align'      " Text alignment by characters.
Plug 'majutsushi/tagbar'            " Display tags in a split window.
Plug 'milkypostman/vim-togglelist'  " Toggle Location List and Quickfix windows.
Plug 'othree/html5.vim'             " Improved HTML5 syntax and omni completion.
Plug 'othree/javascript-libraries-syntax.vim' " Syntax for JS libraries.
Plug 'plasticboy/vim-markdown'      " Markdown Vim Mode.
Plug 'scrooloose/nerdtree'          " File explorer window.
Plug 'shawncplus/phpcomplete.vim'   " Improved PHP omni completion.
Plug 'ternjs/tern_for_vim', { 'do': 'npm install' } " Improved JavaScript omni completion.
Plug 'tpope/vim-commentary'         " Commenting made simple.
Plug 'tpope/vim-fugitive'           " Git wrapper.
Plug 'tpope/vim-repeat'             " Enable repeat for tpope's plugins.
Plug 'tpope/vim-surround'           " Quoting/parenthesizing made simple.
Plug 'w0ng/vim-hybrid'              " Dark colorscheme.

" Plugins to enable only for Neovim.
if has('nvim')
  Plug 'Shougo/deoplete.nvim'     " Asynchronous auto completion.
endif

" Plugins to enable only for Vim.
if !has('nvim')
  Plug 'Shougo/neocomplete.vim'   " Synchronous auto completion.
endif

" Plugins to enable only on the command line.
if !has('gui_running')
  " Command-line fuzzy finder.
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
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
" Plugin Settings - autoformat {{{
" -----------------------------------------------------------------------------

" CSS Formatter - Requires https://github.com/beautify-web/js-beautify
let g:formatdef_cssbeautify = '"css-beautify -f -"'
let g:formatters_css = ['cssbeautify']

" HTML Formatter - Requires https://github.com/beautify-web/js-beautify
let g:formatdef_htmlbeautify = '"html-beautify -f -"'
let g:formatters_html = [ 'htmlbeautify']

" JavaScript Formatter - Requires https://github.com/beautify-web/js-beautify
let g:formatdef_jsbeautify_js = '"js-beautify -a -f -"'
let g:formatters_javascript = [ 'jsbeautify_js']

" JSON Formatter - Requires https://github.com/beautify-web/js-beautify
let g:formatdef_jsbeautify_json = '"js-beautify -a -s 2 -f -"'
let g:formatters_json = [ 'jsbeautify_json']

" PHP Formatter - Requires https://github.com/phpfmt/php.tools
let g:formatdef_fmtphar = '"fmt.phar --psr -o=- -"'
let g:formatters_php = ['fmtphar']

" Python Formatter - Requires https://github.com/hhatto/autopep8
let g:formatdef_autopep8 = '"autopep8 -aa -"'
let g:formatters_python = ['autopep8']

" Ruby Formatter - Requires https://github.com/erniebrodeur/ruby-beautify
let g:formatdef_rubybeautify = '"rubybeautify -s -c 2"'
let g:formatters_ruby = ['rubybeautify']

" SCSS Formatter - Requires https://github.com/sass/sass
let g:formatdef_sassconvert = '"sass-convert -F scss -T scss"'
let g:formatters_scss = ['sassconvert']

" SQL Formatter - Requires https://github.com/andialbrecht/sqlparse
" let g:formatdef_sqlformat = '"sqlformat -r -k upper -"'
" SQL Formatter - Requires https://github.com/jdorn/sql-formatter/
let g:formatdef_sqlformatter = '"sql-formatter"'
let g:formatters_sql = ['sqlformatter']

" Run autoformat in current file format.
nnoremap <Leader>af :Autoformat<CR>

" Run autoformat with a different formatter.
nnoremap <Leader>ac :set ft=css<CR>:Autoformat<CR>
nnoremap <Leader>ah :set ft=html<CR>:Autoformat<CR>
nnoremap <Leader>aj :set ft=javascript<CR>:Autoformat<CR>
nnoremap <Leader>ao :set ft=json<CR>:Autoformat<CR>
nnoremap <Leader>ap :set ft=php<CR>:Autoformat<CR>
nnoremap <Leader>as :set ft=sql<CR>:Autoformat<CR>

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
" Plugin Settings - easy-align {{{
" -----------------------------------------------------------------------------

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

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
  " Find buffers.
  nnoremap <Leader>e :FzfBuffers<CR>

  " Find files.
  nnoremap <Leader>o :FzfFiles<CR>

  " Find project tags (ctags -R).
  nnoremap <Leader><S-O> :FzfTags<CR>

  " Find tags in current buffer.
  nnoremap <Leader>r :FzfBTags<CR>

  " Find pattern in files with ag.
  nnoremap <Leader>f :FzfAg<CR>
endif

"}}}
" Plugin Settings - hybrid {{{
" -----------------------------------------------------------------------------

let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1
"let $NVIM_TUI_ENABLE_TRUE_COLOR=1 " Use 24-bit color, supported in iTerm2 2.9.

try
  colorscheme hybrid
catch /:E185:/
  " Silently ignore if colorscheme not found.
endtry

" Additional syntax highlighting
let php_special_functions = 0
hi! Cursor guibg=#00ffff

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

" Use custom configuration file with ESLint:
" https://github.com/w0ng/dotfiles/blob/master/.eslintrc
let g:neomake_javascript_eslint_maker = {
      \ 'args': ['-c', '~/.eslintrc', '-f', 'compact'],
      \ 'errorformat': '%E%f: line %l\, col %c\, Error - %m,' .
      \ '%W%f: line %l\, col %c\, Warning - %m'
      \ }

" Use PSR2 standard with PHP CodeSniffer.
let g:neomake_php_phpcs_args_standard = 'PSR2'

" Use custom rule set with PHP Mess Detector:
" https://github.com/w0ng/dotfiles/blob/master/.phpmd.xml
let g:neomake_php_phpmd_maker = {
      \ 'args': ['%:p', 'text', '~/.phpmd.xml'],
      \ 'errorformat': '%E%f:%l%\s%m'
      \ }

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

"}}}
" Plugin Settings - plug {{{
" -----------------------------------------------------------------------------

let g:plug_window = 'topleft new' " Open plug window in a horizontal split.

"}}}
" Plugin Settings - tagbar {{{
" -----------------------------------------------------------------------------

let g:tagbar_left = 1 " Open the Tagbar window on the left side.

" Toggle Tagbar window.
nnoremap <Leader>2 :TagbarToggle<CR>

"}}}
" Plugin Settings - togglelist {{{
" -----------------------------------------------------------------------------

let g:toggle_list_no_mappings = 1 " Disable default mappings.

" Toggle Quickfix and Location List windows.
nnoremap <Leader>l :call ToggleLocationList()<CR>
nnoremap <Leader>q :call ToggleQuickfixList()<CR>

"}}}
