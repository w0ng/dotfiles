local lspconfig = require('lspconfig')
local utils = require('plugin/lspconfig/utils')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  -- Print first diagnostic message for the current cursor line
  _G.print_first_cursor_diagnostic = utils.print_first_cursor_diagnostic
  vim.api.nvim_command('autocmd CursorMoveD <buffer> lua print_first_cursor_diagnostic()')

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap = true, silent = true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'gk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<LocalLeader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<LocalLeader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap(
    'n',
    '<LocalLeader>wl',
    '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
    opts
  )
  buf_set_keymap('n', '<LocalLeader>d', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<LocalLeader>r', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap(
    'n',
    '<LocalLeader>e',
    '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({ border = "rounded" })<CR>',
    opts
  )
  buf_set_keymap(
    'n',
    '[d',
    '<cmd>lua vim.lsp.diagnostic.goto_prev({ popup_opts = { border = "rounded" } })<CR>',
    opts
  )
  buf_set_keymap(
    'n',
    ']d',
    '<cmd>lua vim.lsp.diagnostic.goto_next({ popup_opts = { border = "rounded" } })<CR>',
    opts
  )
  buf_set_keymap('n', '<LocalLeader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<LocalLeader>m', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

  -- Format file in buffer on save
  if client.resolved_capabilities.document_formatting then
    vim.api.nvim_command('autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()')
  end
end

-- Extend default config for all servers
lspconfig.util.default_config = vim.tbl_deep_extend('force', lspconfig.util.default_config, {
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  },
})

-- Always show sign column
vim.opt.signcolumn = 'yes'

-- Disable inline buffer error messages
vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  { virtual_text = false }
)

-- Replace sign column diagnostic letters with nerdfonts icons
-- (default { Error = 'E', Warning = 'W', Hint = 'H', Information = 'I' })
for type, icon in pairs({
  Error = ' ',
  Warning = ' ',
  Hint = ' ',
  Information = ' ',
}) do
  local hl = 'LspDiagnosticsSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end

-- Prefix completion kinds with icons (default: just the words)
local kind_icons = {
  Class = ' ',
  Color = ' ',
  Constant = ' ',
  Constructor = ' ',
  Enum = '了 ',
  EnumMember = ' ',
  Field = ' ',
  File = ' ',
  Folder = ' ',
  Function = ' ',
  Interface = 'ﰮ ',
  Keyword = ' ',
  Method = 'ƒ ',
  Module = ' ',
  Property = ' ',
  Snippet = '﬌ ',
  Struct = ' ',
  Text = ' ',
  Unit = ' ',
  Value = ' ',
  Variable = ' ',
}
local kinds = vim.lsp.protocol.CompletionItemKind
for i, kind in ipairs(kinds) do
  local icon = kind_icons[kind]
  if icon then
    kinds[i] = kind_icons[kind] .. kind
  end
end

-- Add border to popup menus (default: none)
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'rounded',
})
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = 'rounded',
})

-- Setup servers
require('plugin/lspconfig/tsserver')
require('plugin/lspconfig/cssls')
require('plugin/lspconfig/html')
require('plugin/lspconfig/jsonls')
require('plugin/lspconfig/stylelint_lsp')
require('plugin/lspconfig/efm')
require('plugin/lspconfig/sumneko_lua')
