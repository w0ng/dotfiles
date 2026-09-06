-- lualine.nvim: configurable statusline (+ web-devicons)
--------------------------------------------------------------------------------
vim.pack.add({
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/nvim-tree/nvim-web-devicons',
})

local function diff_source()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns then
        return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
        }
    end
end

require('lualine').setup({
    options = {
        theme = 'gruvbox-material',
        section_separators = '',
        component_separators = '',
    },
    sections = {
        lualine_a = {
            {
                'mode',
                color = { gui = '' },
                fmt = function(str)
                    if str == 'INSERT' or str == 'REPLACE' then
                        return '󰙌'
                    end
                    return '󰙋'
                end,
            },
        },
        lualine_b = {
            { 'b:gitsigns_head', icon = '' },
            { 'diff', source = diff_source },
            -- lualine ships no macro-recording component
            -- (https://github.com/nvim-lualine/lualine.nvim/issues/1355), so
            -- this is a plain function component; draw_empty hides the section
            -- when it returns nothing.
            {
                function()
                    local reg = vim.fn.reg_recording()
                    return reg ~= '' and 'Recording @' .. reg or ''
                end,
                draw_empty = false,
            },
        },
        lualine_c = {
            '%=',
            {
                'filetype',
                icon_only = true,
                separator = '',
                padding = { left = 1, right = 0 },
            },
            {
                'filename',
                path = 1,
                padding = { left = 0, right = 1 },
                color = { fg = '#fabd2f', gui = '' },
            },
        },
        lualine_x = {
            { require('async_activity').status, color = { fg = '#fabd2f', gui = '' } },
        },
        lualine_y = {
            { 'diagnostics', color = { gui = '' } },
        },
        lualine_z = {
            { 'location', color = { gui = '' } },
        },
    },
})

-- Let lua/async_activity.lua drive the spinner redraw without requiring lualine
-- itself; this file is the one that declares it.
require('async_activity').on_refresh(function()
    require('lualine').refresh()
end)
