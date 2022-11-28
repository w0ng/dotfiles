local lspconfig = require('lspconfig')

-- npm i -g vscode-langservers-extracted
lspconfig.cssls.setup({
  settings = {
    css = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore',
        unknownProperties = 'ignore',
      },
    },
  },
  root_dir = lspconfig.util.root_pattern('shell.nix'),
})
