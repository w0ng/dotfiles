-- npm i -g vscode-langservers-extracted
require('lspconfig').eslint.setup({
  settings = {
    -- Disable formatting with eslint. Use prettier in efm instead
    format = false,
  },
})
