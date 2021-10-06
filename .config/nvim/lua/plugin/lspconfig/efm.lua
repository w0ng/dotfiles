-- brew install efm-langserver
local lspconfig = require('lspconfig')

-- npm install -g eslint_d
local eslint = {
  lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
  prefix = 'eslint',
  lintStdin = true,
  lintFormats = { '%f:%l:%c: %m' },
  lintIgnoreExitCode = true,
  rootMarkers = {
    '.eslintrc.js',
    '.eslintrc',
    'package.json',
  },
}

lspconfig.efm.setup({
  root_dir = lspconfig.util.root_pattern('package.json', '.git') or vim.fn.getcwd(),
  init_options = {
    documentFormatting = false,
  },
  settings = {
    languages = {
      javascript = { eslint },
      javascriptreact = { eslint },
      typescript = { eslint },
      typescriptreact = { eslint },
    },
  },
  filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
})
