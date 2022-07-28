require('nvim-tree').setup({
  actions = {
    open_file = {
      window_picker = {
        -- disable window picker when multiple splits open (default true)
        enable = false,
      },
    },
  },
  git = {
    enable = false,
  },
  renderer = {
    -- append a trailing slash to folder names (default false)
    add_trailing = true,
  },
  view = {
    -- increase sidebar width (default: 30)
    width = 51,
  },
})

-- folder name color blue when gruvbox colortheme installed
vim.cmd([[ highlight! link NvimTreeFolderName Identifier ]])
vim.cmd([[ highlight! link NvimTreeEmptyFolderName Identifier ]])
vim.cmd([[ highlight! link NvimTreeOpenedFolderName Identifier ]])

local map = vim.api.nvim_set_keymap
-- toggle tree
map('n', '<Leader>1', ':NvimTreeToggle<CR>', { noremap = true })
map('n', '<Leader>t', ':NvimTreeToggle<CR>', { noremap = true })
-- toggle tree with current file highlighted
map('n', '<Leader>2', ':NvimTreeFindFile<CR>', { noremap = true })
map('n', '<Leader>T', ':NvimTreeFindFile<CR>', { noremap = true })
