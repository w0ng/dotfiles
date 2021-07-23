-- npm i -g stylelint-lsp
require('lspconfig').stylelint_lsp.setup({
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
      autoFixOnSave = true,
    },
  },
  filetypes = {
    'css',
  },
})
