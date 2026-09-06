-- nvim-bqf: better quickfix windows
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/kevinhwang91/nvim-bqf' })

require('bqf').setup({
    preview = {
        win_height = 10,
        win_vheight = 10,
    },
    func_map = {
        open = 'o',
        openc = '<CR>',
    },
})
