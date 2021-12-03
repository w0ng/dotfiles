local lspconfig = require('lspconfig')

-- npm install -g typescript typescript-language-server
lspconfig.tsserver.setup({
  root_dir = lspconfig.util.root_pattern(
    'package.json',
    'tsconfig.json',
    'jsconfig.json',
    '.git',
    '.'
  ),
  on_attach = function(client)
    -- Disable formatting with tsserver. Use eslint/dprint in efm instead
    client.resolved_capabilities.document_formatting = false
  end,
})
