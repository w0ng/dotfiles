local cb = require('diffview.config').diffview_callback

require('diffview').setup({
  key_bindings = {
    file_panel = {
      ['s'] = cb('toggle_stage_entry'),
    },
  },
})

local map = vim.api.nvim_set_keymap
map('n', '<Leader>do', ':DiffviewOpen<CR>', { noremap = true })
map('n', '<Leader>dc', ':DiffviewClose<CR>', { noremap = true })
