local formatter = require('formatter')

-- brew install dprint
-- local dprint_exe = 'dprint'
-- local dprint_config = '~/.config/dprint/dprint.json'
local dprint_exe = vim.fn.getenv('WORK_DPRINT_EXE')
local dprint_config = vim.fn.getenv('WORK_DPRINT_CONFIG')

local filetype = {}

if
  vim.fn.empty(dprint_exe) == 0
  and vim.fn.empty(dprint_config) == 0
  and vim.fn.executable(dprint_exe) == 1
  and vim.fn.filereadable(vim.fn.expand(dprint_config)) == 1
then
  for ft, ext in pairs({
    javascript = 'js',
    javascriptreact = 'jsx',
    json = 'json',
    jsonc = 'jsonc',
    markdown = 'md',
    typescript = 'ts',
    typescriptreact = 'tsx',
  }) do
    filetype[ft] = {
      function()
        return {
          exe = dprint_exe,
          args = { 'fmt', '--config', dprint_config, '--stdin', ext },
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
-- :ww to save file without formatting
map('c', 'ww', 'noautocmd w', { noremap = true })
-- auto format <current filetype>
map('n', '<Leader>af', ':Format<CR>', { noremap = true })
map('v', '<Leader>af', ':Format<CR>', { noremap = true })
-- auto format js
map('n', '<Leader>aj', ':set ft=javascript<CR>:Format<CR>', { noremap = true })
-- auto format markdown
map('n', '<Leader>am', ':set ft=markdown<CR>:Format<CR>', { noremap = true })
-- auto format json
map('n', '<Leader>ao', ':set ft=json<CR>:Format<CR>', { noremap = true })
