-- npm i -g vscode-langservers-extracted
require('lspconfig').eslint.setup({
  settings = {
    format = false,
  },
})
