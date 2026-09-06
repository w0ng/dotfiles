-- lazydev.nvim: lua_ls completion for the Neovim API when editing this config.
-- It injects the workspace library on LspAttach and back-fills clients that are
-- already running, so it does not care whether it loads before plugin/lsp.lua.
vim.pack.add({ 'https://github.com/folke/lazydev.nvim' })

require('lazydev').setup()
