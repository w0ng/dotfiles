local formatter = require('formatter')
local filetype = {}

if vim.fn.executable('custom_dprint') == 1 then
  for ft, ext in pairs({
    javascript = 'js',
    javascriptreact = 'jsx',
    typescript = 'ts',
    typescriptreact = 'tsx',
  }) do
    filetype[ft] = {
      function()
        return {
          exe = 'custom_dprint',
          args = { 'fmt', '--config', '~/dprint.json', '--stdin', ext },
          stdin = true,
        }
      end,
    }
  end
end

-- brew install dprint
if vim.fn.executable('dprint') == 1 then
  for ft, ext in pairs({
    markdown = 'md',
    json = 'json',
  }) do
    filetype[ft] = {
      function()
        return {
          exe = 'dprint',
          args = { 'fmt', '--config', '~/.config/dprint/dprint.json', '--stdin', ext },
          stdin = true,
        }
      end,
    }
  end
end

-- Add filetypes to formatter config
formatter.setup({
  logging = false,
  filetype = filetype,
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
