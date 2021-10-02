local formatter = require('formatter')

local work_dprint_exe = vim.fn.getenv('WORK_DPRINT_EXE')
local work_dprint_config = vim.fn.getenv('WORK_DPRINT_CONFIG')
local dprint_ft_ext = {
  javascript = 'js',
  javascriptreact = 'jsx',
  json = 'json',
  jsonc = 'jsonc',
  markdown = 'md',
  typescript = 'ts',
  typescriptreact = 'tsx',
}

local filetype = {}

if
  work_dprint_exe ~= vim.NIL
  and work_dprint_config ~= vim.NIL
  and vim.fn.executable(work_dprint_exe) == 1
then
  for ft, ext in pairs(dprint_ft_ext) do
    filetype[ft] = {
      function()
        return {
          exe = work_dprint_exe,
          args = { 'fmt', '--config', work_dprint_config, '--stdin', ext },
          stdin = true,
        }
      end,
    }
  end
elseif vim.fn.executable('dprint') == 1 then
  -- brew install dprint
  for ft, ext in pairs(dprint_ft_ext) do
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
