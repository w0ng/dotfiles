-- snacks.nvim: utility library; only its picker is used, for buffers
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/folke/snacks.nvim' })

require('snacks').setup({
    picker = {
        enabled = true,
        -- fzf/fff style: input line at the bottom, list above growing upward
        -- (reverse), and no preview window.
        layout = {
            reverse = true,
            preview = false,
            layout = {
                box = 'vertical',
                width = 0.6,
                height = 0.6,
                border = 'rounded',
                { win = 'list', border = 'none' },
                {
                    win = 'input',
                    height = 1,
                    border = 'top',
                    title = '{title} {live} {flags}',
                    title_pos = 'center',
                },
            },
        },
        -- Stay insert-only (no vim/normal mode): <Esc> closes the picker.
        win = {
            input = {
                keys = {
                    ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
                },
            },
        },
    },
})
vim.keymap.set('n', '<Leader>b', function()
    require('snacks').picker.buffers()
end, { desc = 'Buffers' })
