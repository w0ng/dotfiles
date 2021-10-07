local formatter = require('formatter')

-- Dir that contains dprint.json config e.g. /repos/work
local WORK_ROOT_DIR = vim.fn.getenv('WORK_ROOT_DIR')
-- Dir that contains .eslintrc.* e.g. /repos/work/web
local WORK_WEB_DIR = vim.fn.getenv('WORK_WEB_DIR')
-- e.g. /repo/work/tools/dprint
local WORK_DPRINT_EXE = vim.fn.getenv('WORK_DPRINT_EXE')

---npm install -g eslint_d
---@return table
local function eslint()
  local filename = vim.api.nvim_buf_get_name(0)
  return {
    exe = 'eslint_d',
    cwd = WORK_WEB_DIR,
    args = {
      '--fix-to-stdout',
      '--stdin',
      '--stdin-filename',
      vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
    },
    stdin = true,
  }
end

local dprint_filetype_ext = {
  javascript = 'js',
  javascriptreact = 'jsx',
  json = 'json',
  jsonc = 'jsonc',
  markdown = 'md',
  typescript = 'ts',
  typescriptreact = 'tsx',
}

---brew install dprint
---@return table
local function dprint()
  local filename_or_ext = vim.api.nvim_buf_get_name(0)
  if filename_or_ext == '' then
    filename_or_ext = dprint_filetype_ext[vim.bo.filetype]
  end
  return {
    exe = WORK_DPRINT_EXE,
    cwd = WORK_ROOT_DIR,
    args = { 'fmt', '--stdin', filename_or_ext },
    stdin = true,
  }
end

-- cargo install stylua
local function stylua()
  return {
    exe = 'stylua',
    args = { '--config-path', '~/.config/stylua/stylua.toml', '-' },
    stdin = true,
  }
end

formatter.setup({
  logging = false,
  filetype = {
    javascript = { eslint, dprint },
    javascriptreact = { eslint, dprint },
    json = { dprint },
    jsonc = { dprint },
    lua = { stylua },
    markdown = { dprint },
    typescript = { eslint, dprint },
    typescriptreact = { eslint, dprint },
  },
})

-- Format file in buffer on save
vim.api.nvim_exec(
  [[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.js,*.jsx,*.json,*.jsonc,*.lua,*.md,*.ts,*.tsx silent! FormatWrite
augroup END
]],
  true
)

-- HACK: suppress formatting command messages
-- require('formatter.util').print = function() end

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
