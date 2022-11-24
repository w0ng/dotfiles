-- brew install lua-language-server
-- https://github.com/folke/neodev.nvim
local lspconfig = require('lspconfig')

lspconfig.sumneko_lua.setup({
  on_attach = function(client)
    -- Disable formatting with sumneko_lua. Use stylua in efm instead
    client.server_capabilities.documentFormattingProvider = false
  end,
})
