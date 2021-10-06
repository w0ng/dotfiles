-- npm install -g typescript typescript-language-server
require('lspconfig').tsserver.setup({
  on_attach = function(client)
    -- Disable formatting with tsserver. Use formatter plugin to prevent locking main thread
    client.resolved_capabilities.document_formatting = false
  end,
})
