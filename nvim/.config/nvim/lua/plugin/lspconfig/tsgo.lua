local lspconfig = require('lspconfig')

lspconfig.tsgo.setup({
  on_attach = function(client)
    -- Disable formatting with tsserver. Use dprint in efm instead
    client.server_capabilities.documentFormattingProvider = false
  end,
  root_dir = lspconfig.util.root_pattern('shell.nix'),
})
vim.lsp.enable('tsgo')
