local formatter = require('formatter')

local filetype = {}

-- brew install dprint
if vim.fn.executable('dprint') then
  local dprint_filetypes = {
    markdown = 'md',
    javascript = 'js',
    javascriptreact = 'jsx',
    json = 'json',
    typescript = 'ts',
    typescriptreact = 'tsx'
  }
  for ft, ext in pairs(dprint_filetypes) do
    filetype[ft] = {
      function()
        return {
          exe = 'dprint',
          args = { 'fmt', '--config', '~/.config/dprint.json', '--stdin', ext },
          stdin = true
        }
      end

    }
  end
end

-- Add filetypes to formatter config
formatter.setup({
  logging = false,
  filetype = filetype,
})

-- auto format <current filetype>
vim.api.nvim_set_keymap('n', '<Leader>af', ':Format<CR>', { noremap = true })
-- auto format css
vim.api.nvim_set_keymap('n', '<Leader>ac', ':set ft=css<CR>:Format<CR>', { noremap = true })
-- auto format html
-- vim.api.nvim_set_keymap('n', '<Leader>ah', ':set ft=css<CR>:Format<CR>', { noremap = true })
-- auto format js
vim.api.nvim_set_keymap('n', '<Leader>aj', ':set ft=javascript<CR>:Format<CR>', { noremap = true })
-- auto format markdown
vim.api.nvim_set_keymap('n', '<Leader>am', ':set ft=markdown<CR>:Format<CR>', { noremap = true })
-- auto format json
vim.api.nvim_set_keymap('n', '<Leader>ao', ':set ft=json<CR>:Format<CR>', { noremap = true })
