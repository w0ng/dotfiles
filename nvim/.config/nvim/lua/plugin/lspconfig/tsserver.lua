local lspconfig = require('lspconfig')

-- npm install -g typescript typescript-language-server
lspconfig.tsserver.setup({
  on_attach = function(client)
    -- Disable formatting with tsserver. Use dprint in efm instead
    client.resolved_capabilities.document_formatting = false
  end,
})
