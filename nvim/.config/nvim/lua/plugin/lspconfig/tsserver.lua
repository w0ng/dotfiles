local lspconfig = require('lspconfig')

-- npm install -g typescript typescript-language-server
lspconfig.tsserver.setup({
  on_attach = function(client)
    -- Disable formatting with tsserver. Use prettier in efm instead
    client.server_capabilities.documentFormattingProvider = false
  end,
})
