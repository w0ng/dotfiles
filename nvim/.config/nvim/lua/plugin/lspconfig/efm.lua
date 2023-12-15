-- brew install efm-langserver
local lspconfig = require('lspconfig')

-- brew install prettierd
local prettierd = {
  formatCommand = 'prettierd "${INPUT}"',
  formatStdin = true,
  env = { string.format('PRETTIERD_DEFAULT_CONFIG=%s', vim.fn.expand('~/.prettierrc')) },
}

-- cargo install stylua
local stylua = {
  formatCommand = 'stylua -',
  formatStdin = true,
  rootMarkers = {
    '.stylua.toml',
    'stylua.toml',
  },
}

lspconfig.efm.setup({
  root_dir = lspconfig.util.root_pattern('package.json', '.git'),
  init_options = {
    documentFormatting = true,
  },
  settings = {
    languages = {
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
  },
  filetypes = {
    'css',
    'graphql',
    'html',
    'javascript',
    'javascriptreact',
    'json',
    'less',
    'lua',
    'markdown',
    'scss',
    'typescript',
    'typescriptreact',
    'yaml',
  },
})
