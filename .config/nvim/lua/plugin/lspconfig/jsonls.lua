-- npm i -g vscode-langservers-extracted
require('lspconfig').jsonls.setup({
  on_attach = function(client)
    -- Disable formatting with jsonls. Use dprint instead.
    client.resolved_capabilities.document_formatting = false
  end,
})
