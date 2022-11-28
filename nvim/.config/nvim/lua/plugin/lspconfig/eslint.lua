local lspconfig = require('lspconfig')

-- npm i -g vscode-langservers-extracted
lspconfig.eslint.setup({
  settings = {
    -- Disable formatting with eslint. Use dprint in efm instead
    format = false,
  },
  root_dir = lspconfig.util.root_pattern('shell.nix'),
})
