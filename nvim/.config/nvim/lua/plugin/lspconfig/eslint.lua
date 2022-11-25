-- npm i -g vscode-langservers-extracted
require('lspconfig').eslint.setup({
  settings = {
    -- Disable formatting with eslint. Use dprint in efm instead
    format = false,
  },
})
