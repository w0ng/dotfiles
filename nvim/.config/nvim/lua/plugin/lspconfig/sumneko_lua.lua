-- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#sumneko_lua
-- https://github.com/folke/lua-dev.nvim
local lspconfig = require('lspconfig')
local luadev = require('lua-dev').setup({
  lspconfig = {
    cmd = { 'lua-language-server' },
  },
})

lspconfig.sumneko_lua.setup(luadev)
