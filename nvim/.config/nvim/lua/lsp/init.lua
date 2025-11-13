local cmp_nvim_lsp = require('cmp_nvim_lsp')

-- Configure diagnostic options globally
vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded',
    severity_sort = true,
    source = true,
  },
  -- Replace sign column diagnostic letters with nerdfonts icons
  -- (default { Error = 'E', Warning = 'W', Hint = 'H', Information = 'I' })
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = ' ',
      [vim.diagnostic.severity.WARN] = ' ',
      [vim.diagnostic.severity.INFO] = ' ',
      [vim.diagnostic.severity.HINT] = ' ',
    },
  },
})

-- Always show sign column
vim.opt.signcolumn = 'yes'

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<LocalLeader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<LocalLeader>l', ':LspEslintFixAll<CR>', opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'gk', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<LocalLeader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<LocalLeader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<LocalLeader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<LocalLeader>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<LocalLeader>r', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<LocalLeader>m', function()
    vim.lsp.buf.format({ async = true })
  end, bufopts)
  vim.keymap.set('n', '<LocalLeader>q', vim.diagnostic.setloclist, bufopts)

  -- Format file in buffer on save
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd('BufWritePre', {
      callback = function()
        vim.lsp.buf.format({ timeout_ms = 5000 })
      end,
    })
  end
end

-- Setup integration with cmp for autocompletion
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Extend default config for all servers
vim.lsp.config('*', {
  flags = {
    debounce_text_changes = 150,
  },
  on_attach = on_attach,
  capabilities = capabilities,
  root_markers = { 'shell.nix' },
})

-- Extend individual servers
-- (extends https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md)

-- npm i -g vscode-langservers-extracted
vim.lsp.config('cssls', {
  settings = {
    css = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore',
        unknownProperties = 'ignore',
      },
    },
  },
})
vim.lsp.enable('cssls')

-- npm i -g cssmodules-language-server
vim.lsp.config('cssmodules_ls', {})
vim.lsp.enable('cssmodules_ls')

-- npm i -g vscode-langservers-extracted
vim.lsp.config('eslint', {
  settings = {
    -- Disable formatting with eslint. Use dprint in efm instead
    format = false,
  },
})
vim.lsp.enable('eslint')

-- npm install -g graphql-language-service-cli
-- vim.lsp.enable('graphql')

-- npm i -g vscode-langservers-extracted
vim.lsp.config('html', {})
vim.lsp.enable('html')

-- npm i -g vscode-langservers-extracted
vim.lsp.config('jsonls', {
  filetypes = { 'json', 'jsonc' },
  init_options = {
    provideFormatter = false,
  },
})
vim.lsp.enable('jsonls')

--vim.lsp.enable('prismals')

-- npm i -g stylelint-lsp
vim.lsp.config('stylelint_lsp', {
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
      autoFixOnSave = true,
    },
  },
  filetypes = {
    'css',
  },
})
vim.lsp.enable('stylelint_lsp')

-- brew install lua-language-server
vim.lsp.config('lua_ls', {
  on_attach = function(client)
    -- Disable formatting with sumneko_lua. Use stylua in efm instead
    client.server_capabilities.documentFormattingProvider = false
  end,
})
vim.lsp.enable('lua_ls')

-- npm i -g typescript typescript-language-server
-- require('lsp/ts_ls')


-- npm i -g @typescript/native-preview
vim.lsp.config('tsgo', {
  on_attach = function(client)
    -- Disable formatting with tsserver. Use dprint in efm instead
    client.server_capabilities.documentFormattingProvider = false
  end,
})
vim.lsp.enable('tsgo')
