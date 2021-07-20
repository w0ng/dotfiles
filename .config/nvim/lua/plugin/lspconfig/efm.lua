--[[
Install:
  brew install efm-langserver

Commands:

Default Values:
  cmd = { "efm-langserver" }
  root_dir = util.root_pattern(".git")(fname) or util.path.dirname(fname)
--]]
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

lspconfig.efm.setup({
  root_dir = lspconfig.util.root_pattern('package.json', '.git') or vim.fn.getcwd(),
  init_options = {
    documentFormatting = true,
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
