-- Treat JSON files as JSONC (JSON with JavaScript-style comments)
vim.api.nvim_command('autocmd BufNewFile,BufRead *.json setlocal filetype=jsonc')
