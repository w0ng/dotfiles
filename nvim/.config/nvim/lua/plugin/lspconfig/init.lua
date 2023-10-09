local lspconfig = require('lspconfig')
local cmp_nvim_lsp = require('cmp_nvim_lsp')

-- Configure diagnostic options globally
vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded',
    severity_sort = true,
    source = true,
  },
})

-- Always show sign column
vim.opt.signcolumn = 'yes'

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<LocalLeader>e', vim.diagnostic.open_float, opts)
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
lspconfig.util.default_config = vim.tbl_deep_extend('force', lspconfig.util.default_config, {
  flags = {
    debounce_text_changes = 150,
  },
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Replace sign column diagnostic letters with nerdfonts icons
-- (default { Error = 'E', Warning = 'W', Hint = 'H', Information = 'I' })
for type, icon in pairs({
  Error = ' ',
  Warn = ' ',
  Hint = ' ',
  Info = ' ',
}) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end

-- Setup servers
require('plugin/lspconfig/cssls')
require('plugin/lspconfig/cssmodules_ls')
require('plugin/lspconfig/efm')
require('plugin/lspconfig/eslint')
-- require('plugin/lspconfig/graphql')
require('plugin/lspconfig/html')
require('plugin/lspconfig/jsonls')
-- require('plugin/lspconfig/prismals')
require('plugin/lspconfig/stylelint_lsp')
require('plugin/lspconfig/lua_ls')
require('plugin/lspconfig/tsserver')
