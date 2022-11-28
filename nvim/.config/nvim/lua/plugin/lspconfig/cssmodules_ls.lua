local lspconfig = require('lspconfig')

lspconfig.cssmodules_ls.setup({
  root_dir = lspconfig.util.root_pattern('shell.nix'),
})
