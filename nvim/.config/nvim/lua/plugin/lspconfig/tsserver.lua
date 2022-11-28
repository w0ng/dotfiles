local lspconfig = require('lspconfig')

-- npm install -g typescript typescript-language-server
lspconfig.tsserver.setup({
  on_attach = function(client)
    -- Disable formatting with tsserver. Use dprint in efm instead
    client.server_capabilities.documentFormattingProvider = false
  end,
  root_dir = lspconfig.util.root_pattern('shell.nix'),
})
