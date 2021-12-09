-- Make signcolumn same color as regular background
vim.g.gruvbox_sign_column = 'bg0'
vim.g.gruvbox_bold = false
vim.g.gruvbox_italic = false
vim.g.gruvbox_italicize_comments = false
vim.g.gruvbox_italicize_strings = false

-- Set colorscheme, make statusline and pop-up menu darker
vim.cmd([[ colorscheme gruvbox ]])
vim.cmd([[ highlight! StatusLine gui=reverse guifg=#1d2021 guibg=#ebdbb2 ]])
vim.cmd([[ highlight! StatusLineNC cterm=reverse gui=reverse guifg=#1d2021 guibg=#A89985 ]])
vim.cmd([[ highlight! Pmenu guifg=#ebdbb2 guibg=#32302f ]])
vim.cmd([[ highlight! PmenuSel guifg=#32302f guibg=#83a598 ]])
vim.cmd([[ highlight! PmenuSbar guibg=#504945 ]])
vim.cmd([[ highlight! PmenuThumb guibg=#665c54 ]])
vim.cmd([[ highlight! FloatBorder guifg=#665c54 guibg=#32302f ]])
vim.cmd([[ highlight! QuickFixLine guifg=#FABD2E guibg=none ]])
