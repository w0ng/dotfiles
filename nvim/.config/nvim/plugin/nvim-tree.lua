-- nvim-tree.lua: file explorer sidebar
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/nvim-tree/nvim-tree.lua' })

require('nvim-tree').setup({
    actions = {
        open_file = {
            window_picker = {
                -- Reuse the last focused window instead of prompting which
                -- split to open in.
                enable = false,
            },
        },
    },
    git = {
        enable = false,
    },
    renderer = {
        add_trailing = true,
    },
    view = {
        width = 51,
    },
})

-- Folder names take Identifier's colour rather than nvim-tree's own.
vim.api.nvim_set_hl(0, 'NvimTreeFolderName', { link = 'Identifier' })
vim.api.nvim_set_hl(0, 'NvimTreeEmptyFolderName', { link = 'Identifier' })
vim.api.nvim_set_hl(0, 'NvimTreeOpenedFolderName', { link = 'Identifier' })

vim.keymap.set('n', '<Leader>t', function()
    -- find_file: when opening, reveal and highlight the current buffer
    require('nvim-tree.api').tree.toggle({ find_file = true })
end, { desc = 'Toggle file tree' })
