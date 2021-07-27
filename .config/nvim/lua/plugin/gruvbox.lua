-- Make signcolumn same color as regular background
vim.g.gruvbox_sign_column = 'bg0'

local nvim_command = vim.api.nvim_command
-- Set colorscheme, make statusline and pop-up menu darker
nvim_command([[
  colorscheme gruvbox
  highlight! StatusLine gui=reverse guifg=#1d2021 guibg=#ebdbb2
  highlight! StatusLineNC cterm=reverse gui=reverse guifg=#1d2021 guibg=#A89985
  highlight! Pmenu guifg=#ebdbb2 guibg=#32302f
  highlight! PmenuSel guifg=#32302f guibg=#83a598
  highlight! PmenuSbar guibg=#504945
  highlight! PmenuThumb guibg=#665c54
  highlight! FloatBorder guifg=#665c54 guibg=#32302f
  highlight! QuickFixLine guifg=#FABD2E guibg=none
]])
