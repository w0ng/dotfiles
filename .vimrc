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
set colorcolumn=100        " Show right column in a highlighted colour.
set completeopt-=preview   " Do not show preview window for ins-completion.
set diffopt+=foldcolumn:0  " Do not show fold indicator column in diff mode.
set fillchars+=vert:│      " Use full height bar char as vertical separator.
set history=10000          " Number of commands and search patterns to remember.
set laststatus=2           " Always show status line.
set noshowmode             " Do not show current mode on the last line.
set number                 " Show the line number.
" set relativenumber         " Show the line number relative to the cursorline.
set showcmd                " Show command on last line of screen.
set showmatch              " Show matching brackets.
let &t_8f="\<Esc>[38;2;%lu;%lu;%lum" " Enable italics in terminal vim.
let &t_8b="\<Esc>[48;2;%lu;%lu;%lum" " Enable italics in terminal vim.
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
  set guifont=FiraCodeNerdFontComplete-Regular:h16 " Set the font to use.
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
autocmd FileType css,markdown,python,php setlocal shiftwidth=4 softtabstop=4 tabstop=4

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

" Copy to clipboard.
vnoremap <Leader>c "*y
nnoremap <Leader>c :let @*=expand("%:p")<CR>

" Paste from clipboard.
nnoremap <Leader>v "*p
vnoremap <Leader>v "*p
nnoremap <Leader><S-V> "*P
vnoremap <Leader><S-V> "*P

""}}}
" Plugins - Install {{{
" -----------------------------------------------------------------------------

call plug#begin('~/.vim/plugged')

Plug 'MaxMEllon/vim-jsx-pretty'       " JSX and TSX syntax.
Plug '/usr/local/opt/fzf'             " CLI fuzzy finder.
Plug 'chr4/nginx.vim'                 " nginx vim syntax highlighting
Plug 'hashivim/vim-terraform'         " vim/terraform integration.
Plug 'jparise/vim-graphql'            " GraphQL ft, syntax, and indent
Plug 'junegunn/fzf.vim'               " CLI fuzzy finder.
Plug 'junegunn/vim-easy-align'        " Text alignment by characters.
Plug 'leafgarland/typescript-vim'     " Typescript syntax
Plug 'morhetz/gruvbox'                " Dark colorscheme.
Plug 'othree/html5.vim'               " Improved HTML5 syntax and omni completion.
Plug 'pangloss/vim-javascript'        " Improved JavaScript syntax and indents.
Plug 'plasticboy/vim-markdown'        " Markdown Vim Mode.
Plug 'scrooloose/nerdtree'            " File explorer window.
Plug 'tpope/vim-commentary'           " Commenting made simple.
Plug 'tpope/vim-fugitive'             " Git wrapper.
Plug 'tpope/vim-repeat'               " Enable repeat for tpope's plugins.
Plug 'tpope/vim-surround'             " Quoting/parenthesizing made simple.
Plug 'itchyny/lightline.vim'          " Pretty statusline.
Plug 'ryanoasis/vim-devicons'         "Adds dev icons to plugins 

" Async autocompletion.
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

"}}}
" Plugin Settings - coc {{{
" -----------------------------------------------------------------------------

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
" set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" " Mappings using CoCList:
" " Show all diagnostics.
" nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" " Manage extensions.
" nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" " Show commands.
" nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" " Find symbol of current document.
" nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" " Search workspace symbols.
" nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" " Do default action for next item.
" nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" " Do default action for previous item.
" nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" " Resume latest coc list.
" nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

" coc-extensions
let g:coc_global_extensions = [
      \ 'coc-diagnostic',
      \ 'coc-tsserver',
      \ 'coc-html',
      \ 'coc-css',
      \ 'coc-json',
      \ 'coc-cssmodules',
      \ 'coc-prettier',
      \ 'coc-eslint',
      \ 'coc-stylelint'
      \ ]

" Auto format file with prettier
command! -nargs=0 Prettier :CocCommand prettier.formatFile
vmap <leader>af  <Plug>(coc-format-selected)
nmap <leader>af  <Plug>(coc-format-selected)
nnoremap <leader>af :Prettier<CR>
nnoremap <Leader>ac :set ft=css<CR>:Prettier<CR>
nnoremap <Leader>ah :set ft=html<CR>:Prettier<CR>
nnoremap <Leader>aj :set ft=javascript<CR>:Prettier<CR>
nnoremap <Leader>ao :set ft=json<CR>:Prettier<CR>

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
nnoremap <Leader>g :Gblame<CR>

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

let g:gruvbox_italic = 0

try
  colorscheme gruvbox
  highlight! link SignColumn Normal
catch /:E185:/
  " Silently fail if gruvbox theme is not installed.
endtry

"}}}
" Plugin Settings - javascript {{{
" -----------------------------------------------------------------------------

let g:javascript_plugin_jsdoc = 1

" Plugin Settings - jsx-pretty {{{
" -----------------------------------------------------------------------------

autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx

hi! link jsxAttrib htmlArg
hi! link jsxComponentName jsxTagName

"}}}
" Plugin Settings - lightline {{{
" -----------------------------------------------------------------------------

let g:lightline = {}

let g:lightline.colorscheme = 'gruvbox'

function! CocCurrentFunction()
    return get(b:, 'coc_current_function', '')
endfunction

let g:lightline.component_function = {}
let g:lightline.component_function.coccurrentfunction = 'CocCurrentFunction'
let g:lightline.component_function.cocstatus = 'coc#status'

let g:lightline.component = {}
let g:lightline.component.lineinfo = '%3l:%-2v%<'

let g:lightline.active = {}
      " \ [ 'readonly', 'absolutepath', 'modified' ],
let g:lightline.active.left = [
      \ [ 'mode', 'paste' ],
      \ [ 'readonly', 'filename', 'modified' ],
      \ ]
let g:lightline.active.right = [
      \ [ 'lineinfo' ],
      \ [ 'filetype' ],
      \ [ 'cocstatus', 'coccurrentfunction' ],
      \ ]

let g:lightline.inactive = {}
      " \ [ 'readonly', 'absolutepath', 'modified' ],
let g:lightline.inactive.left = [
      \ [ 'readonly', 'filename', 'modified' ],
      \ ]
let g:lightline.inactive.right = [
      \ [ 'lineinfo' ],
      \ [ 'filetype' ],
      \ ]

let g:lightline.subseparator = {}
let g:lightline.subseparator.left = ''
let g:lightline.subseparator.right = ''

"}}}
" Plugin Settings - nerdtree {{{
" -----------------------------------------------------------------------------

" Toggle NERD tree window.
nnoremap <Leader>1 :NERDTreeToggle<CR>
nnoremap <Leader>2 :NERDTreeFind<CR>

"}}}
" Plugin Settings - plug {{{
" -----------------------------------------------------------------------------

let g:plug_window = 'topleft new' " Open plug window in a horizontal split.

"}}}
