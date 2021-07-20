local nvim_set_keymap = vim.api.nvim_set_keymap

-- Define <Leader> key (default nil)
vim.g.mapleader = ','
-- Set <LocalLeader> key (default nil)
vim.g.maplocalleader = ','

-- Map 'jj' to Escape key
nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true })
-- Write file as superuser
nvim_set_keymap('c', 'w!!', 'w !sudo tee > /dev/null %', { noremap = true })
-- Stop highlighting current 'hlsearch' results until next search
nvim_set_keymap('n', '<Space>', ':nohlsearch<CR>', { noremap = true })
-- Switch ';' with ':'
nvim_set_keymap('n', ';', ':', { noremap = true })
nvim_set_keymap('n', ':', ';', { noremap = true })
nvim_set_keymap('v', ';', ':', { noremap = true })
nvim_set_keymap('v', ':', ';', { noremap = true })
-- Toggle options ([c]hange [o]ption [<key>])
nvim_set_keymap('n', 'com', ':set mouse=<C-R>=&mouse == "a" ? "" : "a"<CR><CR>', { noremap = true })
nvim_set_keymap('n', 'con', ':set number!<CR>', { noremap = true })
nvim_set_keymap('n', 'cos', ':set spell!<CR>', { noremap = true })
nvim_set_keymap('n', 'cow', ':set wrap!<CR>', { noremap = true })
-- Navigate split windows with one key combo instead of two
nvim_set_keymap('n', '<C-h>', '<C-w>h', { noremap = true })
nvim_set_keymap('n', '<C-j>', '<C-w>j', { noremap = true })
nvim_set_keymap('n', '<C-k>', '<C-w>k', { noremap = true })
nvim_set_keymap('n', '<C-l>', '<C-w>l', { noremap = true })
-- Navigate next and previous commands starting with current input
nvim_set_keymap('c', '<C-n>', '<Down>', { noremap = true })
nvim_set_keymap('c', '<C-p>', '<Up>', { noremap = true })
-- Navigate next and previous buffers
nvim_set_keymap('n', ']b', ':bnext<CR>', { noremap = true })
nvim_set_keymap('n', '[b', ':bprevious<CR>', { noremap = true })
nvim_set_keymap('n', '<Leader><Tab>', ':b#<CR>', { noremap = true })
-- Navigate next and previous location lists
nvim_set_keymap('n', ']l', ':lnext<CR>', { noremap = true })
nvim_set_keymap('n', '[l', ':lprevious<CR>', { noremap = true })
-- Close the quickfix or location list window
nvim_set_keymap('n', '<Leader><Leader>', ':cclose|lclose<CR>', { noremap = true })
-- Clipboard: cut/copy/paste
nvim_set_keymap('v', '<Leader>x', '"*x', { noremap = true })
nvim_set_keymap('v', '<Leader>c', '"*y', { noremap = true })
nvim_set_keymap('n', '<Leader>v', '"*p', { noremap = true })
nvim_set_keymap('v', '<Leader>v', '"*p', { noremap = true })
nvim_set_keymap('n', '<Leader><S-v>', '"*P', { noremap = true })
nvim_set_keymap('v', '<Leader><S-v>', '"*P', { noremap = true })
-- Copy current file path to clipboard
nvim_set_keymap('n', '<Leader>c', ':let @*=expand("%:p")<CR>', { noremap = true })
