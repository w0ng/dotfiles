local formatter = require('formatter')

-- brew install prettierd
local prettierd = function()
  return {
    exe = 'prettierd',
    args = { vim.api.nvim_buf_get_name(0) },
    stdin = true,
  }
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
  -- logging = false,
  filetype = {
    css = { prettierd },
    graphql = { prettierd },
    html = { prettierd },
    javascript = { prettierd },
    javascriptreact = { prettierd },
    json = { prettierd },
    less = { prettierd },
    lua = { stylua },
    markdown = { prettierd },
    scss = { prettierd },
    typescript = { prettierd },
    typescriptreact = { prettierd },
    yaml = { prettierd },
  },
})

local map = vim.api.nvim_set_keymap
-- auto format <current filetype>
map('n', '<Leader>af', ':Format<CR>', { noremap = true })
map('v', '<Leader>af', ':Format<CR>', { noremap = true })
-- auto format css
map('n', '<Leader>ac', ':set ft=css<CR>:Format<CR>', { noremap = true })
-- auto format html
map('n', '<Leader>ah', ':set ft=html<CR>:Format<CR>', { noremap = true })
-- auto format js
map('n', '<Leader>aj', ':set ft=javascript<CR>:Format<CR>', { noremap = true })
-- auto format markdown
map('n', '<Leader>am', ':set ft=markdown<CR>:Format<CR>', { noremap = true })
-- auto format json
map('n', '<Leader>ao', ':set ft=json<CR>:Format<CR>', { noremap = true })
