-- noice.nvim: UI replacement for messages, cmdline, and popupmenu.
--------------------------------------------------------------------------------
vim.pack.add({
    'https://github.com/folke/noice.nvim',
    'https://github.com/MunifTanjim/nui.nvim',
})

require('noice').setup({
    lsp = {
        -- LSP progress is rendered in lualine instead (see lsp_activity), which
        -- also covers servers that report no progress at all. Leaving this on
        -- shows the same work twice, once here and once there.
        progress = { enabled = false },
        -- override markdown rendering so that hover/docs use Treesitter
        override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
        },
    },
    presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
    },
    messages = {
        view_search = false,
    },
})
