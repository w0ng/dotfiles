-- npm i -g vscode-langservers-extracted
require('lspconfig').jsonls.setup({
  filetypes = { 'json', 'jsonc' },
  init_options = {
    provideFormatter = false,
  },
})
