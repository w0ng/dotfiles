--[[
Install:
  npm i -g vscode-langservers-extracted

Commands:

Default Values:
  cmd = { "vscode-css-language-server", "--stdio" }
  filetypes = { "css", "scss", "less" }
  root_dir = root_pattern("package.json")
  settings = {
    css = {
      validate = true
    },
    less = {
      validate = true
    },
    scss = {
      validate = true
    }
  }
--]]

require('lspconfig').cssls.setup({
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
