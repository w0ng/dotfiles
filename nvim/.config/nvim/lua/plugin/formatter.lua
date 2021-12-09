local formatter = require('formatter')

-- brew install dprint
local dprint = function(ext)
  return function()
    return {
      exe = 'dprint',
      args = { 'fmt', '--config', '~/.config/dprint/dprint.json', '--stdin', ext },
      stdin = true,
    }
  end
end

-- cargo install stylua
local stylua = function()
  return {
    exe = 'stylua',
    args = { '--config-path', '~/.config/stylua/stylua.toml', '-' },
    stdin = true,
  }
end

-- Add filetypes to formatter config
formatter.setup({
  logging = false,
  filetype = {
    javascript = { dprint('js') },
    javascriptreact = { dprint('jsx') },
    json = { dprint('json') },
    jsonc = { dprint('jsonc') },
    lua = { stylua },
    markdown = { dprint('md') },
    typescript = { dprint('ts') },
    typescriptreact = { dprint('tsx') },
  },
})

local map = vim.api.nvim_set_keymap
-- auto format <current filetype>
map('n', '<Leader>af', ':Format<CR>', { noremap = true })
map('v', '<Leader>af', ':Format<CR>', { noremap = true })
-- auto format js
map('n', '<Leader>aj', ':set ft=javascript<CR>:Format<CR>', { noremap = true })
-- auto format markdown
map('n', '<Leader>am', ':set ft=markdown<CR>:Format<CR>', { noremap = true })
-- auto format json
map('n', '<Leader>ao', ':set ft=json<CR>:Format<CR>', { noremap = true })
