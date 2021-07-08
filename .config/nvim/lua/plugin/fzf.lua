-- Size and position of fzf window
vim.g.fzf_layout = { down = 10 }
-- Navigate current buffers
vim.api.nvim_set_keymap('n', '<Leader>b', ':Buffers<CR>', { noremap = true })
-- Navigate by text search
vim.api.nvim_set_keymap('n', '<Leader>f', ':Rg<CR>', { noremap = true })
-- Navigate by filename search
vim.api.nvim_set_keymap('n', '<Leader>p', ':Files<CR>', { noremap = true })
-- Toggle git-blame sidebar
vim.api.nvim_set_keymap('n', '<Leader>g', ':Git blame<CR>', { noremap = true })
