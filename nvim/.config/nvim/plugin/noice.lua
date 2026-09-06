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
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
    },
    messages = {
        view_search = false, -- disable search_count messages
    },
})
