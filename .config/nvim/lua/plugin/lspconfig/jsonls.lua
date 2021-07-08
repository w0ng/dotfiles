--[[
Install:
  npm i -g vscode-langservers-extracted

Commands:

Default Values:
  cmd = { "vscode-json-language-server", "--stdio" }
  filetypes = { "json" }
  init_options = {
    provideFormatter = true
  }
  root_dir = root_pattern(".git", vim.fn.getcwd())
--]]

require('lspconfig').jsonls.setup({})
