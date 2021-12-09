-- npm i -g vscode-langservers-extracted
require('lspconfig').cssls.setup({
  settings = {
    css = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore',
        unknownProperties = 'ignore',
      },
    },
  },
})
