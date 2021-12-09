-- brew install efm-langserver
local lspconfig = require('lspconfig')

-- brew install dprint
local dprint = {
  formatCommand = 'dprint fmt --stdin ${INPUT}',
  formatStdin = true,
  rootMarkers = {
    'dprint.json',
  },
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
  root_dir = lspconfig.util.root_pattern('package.json', '.git', '.'),
  init_options = {
    documentFormatting = true,
  },
  settings = {
    languages = {
      javascript = { dprint },
      javascriptreact = { dprint },
      lua = { stylua },
      typescript = { dprint },
      typescriptreact = { dprint },
    },
  },
  filetypes = {
    'javascript',
    'javascriptreact',
    'lua',
    'typescript',
    'typescriptreact',
  },
})
