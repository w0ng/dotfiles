-- Make signcolumn same color as regular background
vim.g.gruvbox_sign_column = 'bg0'
-- Set colorscheme
vim.api.nvim_command('colorscheme gruvbox')
-- Make statusline darker
vim.api.nvim_command('highlight! StatusLine gui=reverse guifg=#1d2021 guibg=#EBDBB2')
vim.api.nvim_command('highlight! StatusLineNC cterm=reverse gui=reverse guifg=#1d2021 guibg=#A89985')
