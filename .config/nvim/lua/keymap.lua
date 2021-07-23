-- Define <Leader> key (default nil)
vim.g.mapleader = ','
-- Set <LocalLeader> key (default nil)
vim.g.maplocalleader = ','

---@param mode string
---@param lhs string
---@param rhs string
local function noremap(mode, lhs, rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true })
end

-- Map 'jj' to Escape key
noremap('i', 'jj', '<Esc>')
-- Write file as superuser
noremap('c', 'w!!', 'w !sudo tee > /dev/null %')
-- Stop highlighting current 'hlsearch' results until next search
noremap('n', '<Space>', ':nohlsearch<CR>')
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
-- Navigate split windows with one key combo instead of two
noremap('n', '<C-h>', '<C-w>h')
noremap('n', '<C-j>', '<C-w>j')
noremap('n', '<C-k>', '<C-w>k')
noremap('n', '<C-l>', '<C-w>l')
-- Navigate next and previous commands starting with current input
noremap('c', '<C-n>', '<Down>')
noremap('c', '<C-p>', '<Up>')
-- Navigate next and previous buffers
noremap('n', ']b', ':bnext<CR>')
noremap('n', '[b', ':bprevious<CR>')
noremap('n', '<Leader><Tab>', ':b#<CR>')
-- Navigate next and previous location lists
noremap('n', ']l', ':lnext<CR>')
noremap('n', '[l', ':lprevious<CR>')
-- Close the quickfix or location list window
noremap('n', '<Leader><Leader>', ':cclose|lclose<CR>')
-- Clipboard: cut/copy/paste
noremap('v', '<Leader>x', '"*x')
noremap('v', '<Leader>c', '"*y')
noremap('n', '<Leader>v', '"*p')
noremap('v', '<Leader>v', '"*p')
noremap('n', '<Leader><S-v>', '"*P')
noremap('v', '<Leader><S-v>', '"*P')
-- Copy current file path to clipboard
noremap('n', '<Leader>c', ':let @*=expand("%:p")<CR>')
