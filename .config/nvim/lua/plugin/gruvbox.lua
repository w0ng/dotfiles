local nvim_command = vim.api.nvim_command
-- Make signcolumn same color as regular background
vim.g.gruvbox_sign_column = 'bg0'
-- Set colorscheme
nvim_command('colorscheme gruvbox')
-- Make statusline darker
nvim_command('highlight! StatusLine gui=reverse guifg=#1d2021 guibg=#EBDBB2')
nvim_command('highlight! StatusLineNC cterm=reverse gui=reverse guifg=#1d2021 guibg=#A89985')
