require('gitsigns').setup()

-- Toggle git-blame sidebar
vim.api.nvim_set_keymap('n', '<Leader>g', ':Gitsigns blame<CR>', { noremap = true })
