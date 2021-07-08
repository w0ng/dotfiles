--[[
Install:
  npm i -g vscode-langservers-extracted

Commands:

Default Values:
  cmd = { "vscode-html-language-server", "--stdio" }
  filetypes = { "html" }
  init_options = {
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = {
      css = true,
      javascript = true
    }
  }
  root_dir = function(fname)
    return root_pattern(fname) or vim.loop.os_homedir()
  end,
  settings = {}
--]]

require('lspconfig').html.setup({})
