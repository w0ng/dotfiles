-- npm install -g typescript typescript-language-server
require('lspconfig').tsserver.setup({
  on_attach = function(client, _)
    -- Disable formatting with tsserver. Use eslint in efm instead
    client.resolved_capabilities.document_formatting = false
  end,
})
