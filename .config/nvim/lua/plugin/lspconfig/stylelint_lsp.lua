--[[
Install:
  npm i -g stylelint-lsp

Commands:

Default Values:
  cmd = { "stylelint-lsp", "--stdio" }
  filetypes = { "css", "less", "scss", "sugarss", "vue", "wxss", "javascript", "javascriptreact", "typescript", "typescriptreact" }
  root_dir =  root_pattern('.stylelintrc', 'package.json') 
  settings = {}
--]]
require('lspconfig').stylelint_lsp.setup({
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
