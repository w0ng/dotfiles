--[[
Install:
  npm install -g typescript typescript-language-server

Commands:

Default Values:
  cmd = { "typescript-language-server", "--stdio" }
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" }
  root_dir = root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")
--]]

require('lspconfig').tsserver.setup({
  on_attach = function(client, _)
    -- Disable formatting with tsserver. Use eslint in efm instead
    client.resolved_capabilities.document_formatting = false
  end
})
