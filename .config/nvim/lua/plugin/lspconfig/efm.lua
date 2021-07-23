-- brew install efm-langserver
local lspconfig = require('lspconfig')

-- npm install -g eslint_d
local eslint = {
  lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
  prefix = 'eslint',
  lintStdin = true,
  lintFormats = { '%f:%l:%c: %m' },
  lintIgnoreExitCode = true,
  formatCommand = 'eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}',
  formatStdin = true,
  rootMarkers = {
    '.eslintrc.js',
    '.eslintrc',
    'package.json',
  },
}

-- cargo install stylua
local stylua = {
  formatCommand = 'stylua --config-path ~/.config/stylua/stylua.toml -',
  formatStdin = true,
  rootMarkers = {
    '.git',
  },
}

lspconfig.efm.setup({
  root_dir = lspconfig.util.root_pattern('package.json', '.git') or vim.fn.getcwd(),
  init_options = {
    documentFormatting = true,
  },
  settings = {
    languages = {
      javascript = { eslint },
      javascriptreact = { eslint },
      lua = { stylua },
      typescript = { eslint },
      typescriptreact = { eslint },
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
