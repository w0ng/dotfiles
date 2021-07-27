-- Close quickfix window
vim.api.nvim_buf_set_keymap(0, 'n', '<Esc>', ':cclose|lclose<CR>', { noremap = true })
