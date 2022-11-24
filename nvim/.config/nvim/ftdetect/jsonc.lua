-- Treat JSON files as JSONC (JSON with JavaScript-style comments)
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { '*.json' },
  callback = function()
    vim.bo.filetype = 'jsonc'
  end,
})
