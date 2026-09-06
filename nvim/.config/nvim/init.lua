-- ============================================================================
-- OPTIONS
-- ============================================================================

-- General
vim.opt.colorcolumn = { 100 }
vim.opt.diffopt:append('foldcolumn:0')
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.laststatus = 3
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false
vim.opt.title = true
vim.opt.wrap = false
vim.opt.termguicolors = true

-- Indent
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

if vim.fn.executable('rg') == 1 then
    vim.opt.grepprg = 'rg --no-heading --vimgrep'
end

-- Flash on yank
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.hl.on_yank()
    end,
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local function noremap(mode, lhs, rhs)
    vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true })
end

-- Stop highlighting current 'hlsearch' results until next search
noremap('n', '<Leader>n', ':nohlsearch<CR>')

-- Switch ';' with ':'
noremap('n', ';', ':')
noremap('n', ':', ';')
noremap('v', ';', ':')
noremap('v', ':', ';')

-- Toggle options ([c]hange [o]ption [<key>])
noremap('n', 'com', ':set mouse=<C-R>=&mouse == "a" ? "" : "a"<CR><CR>')
noremap('n', 'con', ':set number!<CR>')
noremap('n', 'cos', ':set spell!<CR>')
noremap('n', 'cow', ':set wrap!<CR>')

-- Move between splits without the <C-w> prefix.
noremap('n', '<C-h>', '<C-w>h')
noremap('n', '<C-j>', '<C-w>j')
noremap('n', '<C-k>', '<C-w>k')
noremap('n', '<C-l>', '<C-w>l')

-- Navigate next and previous commands starting with current input
noremap('c', '<C-n>', '<Down>')
noremap('c', '<C-p>', '<Up>')

-- Clipboard: cut/copy/paste
noremap('v', '<Leader>x', '"+x')
noremap('v', '<Leader>c', '"+y')
noremap('n', '<Leader>v', '"+p')
noremap('v', '<Leader>v', '"+p')
noremap('n', '<Leader><S-v>', '"+P')
noremap('v', '<Leader><S-v>', '"+P')

-- Copy current file path to clipboard
noremap('n', '<Leader>c', ':let @+=expand("%:p")<CR>')

-- Machine-local settings that can't live in a public repo, supplied by the
-- private overlay; absent everywhere else, hence the pcall. Loaded here rather
-- than where it is read because it also runs side effects -- a managed machine
-- needs vim.env.PATH adjusted so plugin git resolves to a real git rather than
-- a corporate wrapper, and that must land before the first vim.pack.add(),
-- which all run from plugin/ after this file. require caches, so the reads in
-- plugin/conform.lua and plugin/fff.lua get this same instance.
pcall(require, 'local')
