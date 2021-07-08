-- append a trailing slash to folder names (default 0)
vim.g.nvim_tree_add_trailing = 1
-- closes the tree when it's the last window (default 0)
vim.g.nvim_tree_auto_close = 1
-- disable window picker when multiple splits open (default 0)
vim.g.nvim_tree_disable_window_picker = 1
-- hide git icons (default git = 1)
vim.g.nvim_tree_show_icons = {
  git = 0,
  folders = 1,
  files = 1,
  folder_arrows = 1,
}
-- increase sidebar width (default: 30)
vim.g.nvim_tree_width = 51
-- toggle tree
vim.api.nvim_set_keymap('n', '<Leader>1', ':NvimTreeToggle<CR>', { noremap = true })
-- toggle tree with current file highlighted
vim.api.nvim_set_keymap('n', '<Leader>2', ':NvimTreeFindFile<CR>', { noremap = true })
-- folder name color blue when gruvbox colortheme installed
vim.cmd([[
  highlight! link NvimTreeFolderName Identifier
  highlight! link NvimTreeEmptyFolderName Identifier
  highlight! link NvimTreeOpenedFolderName Identifier
]])
