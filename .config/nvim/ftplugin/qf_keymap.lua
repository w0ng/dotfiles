-- Close quickfix window
vim.api.nvim_buf_set_keymap(0, 'n', '<Esc>', ':cclose|lclose<CR>', { noremap = true })
-- Go to selected file and close quickfix window
vim.api.nvim_buf_set_keymap(0, 'n', '<Enter>', '<CR>:cclose|lclose<CR>', { noremap = true })
