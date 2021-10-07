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

-- brew install dprint
-- local dprint_exe = 'dprint'
local dprint_exe = vim.fn.getenv('WORK_DPRINT_EXE')
local dprint = {
  formatCommand = dprint_exe .. ' fmt --stdin ${INPUT}',
  formatStdin = true,
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
      javascript = { eslint, dprint },
      javascriptreact = { eslint, dprint },
      lua = { stylua },
      typescript = { eslint, dprint },
      typescriptreact = { eslint, dprint },
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
