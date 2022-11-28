local lspconfig = require('lspconfig')

-- npm i -g stylelint-lsp
lspconfig.stylelint_lsp.setup({
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
      autoFixOnSave = true,
    },
  },
  filetypes = {
    'css',
  },
  root_dir = lspconfig.util.root_pattern('shell.nix'),
})
