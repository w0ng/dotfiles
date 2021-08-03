require('neogit').setup({
  disable_context_highlighting = true,
  signs = {
    -- { CLOSED, OPENED }
    section = { '', '' },
    item = { '', '' },
    hunk = { '', '' },
  },
  integrations = {
    diffview = true,
  },
  mappings = {
    status = {
      ['o'] = 'Toggle',
    },
  },
})

vim.api.nvim_set_keymap('n', '<Leader>gs', ':Neogit<CR>', { noremap = true })
