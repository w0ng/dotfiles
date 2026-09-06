-- incline.nvim: floating per-window statusline (+ web-devicons for the file
-- icon). plugin/lualine.lua declares web-devicons too; a repeat add is a no-op,
-- and each file declaring what it requires keeps either one removable.
vim.pack.add({
    'https://github.com/b0o/incline.nvim',
    'https://github.com/nvim-tree/nvim-web-devicons',
})

require('incline').setup({
    -- Hide floating statusline on focused window if on same line as cursor
    hide = {
        cursorline = 'focused_win',
    },
    -- Override highlight groups to match bottom statusline
    highlight = {
        groups = {
            InclineNormal = 'StatusLine',
            InclineNormalNC = 'StatusLineNC',
        },
    },
    -- Add web-devicons
    render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
        if filename == '' then
            filename = '[No Name]'
        end
        local icon, color = require('nvim-web-devicons').get_icon_color(filename)
        local hl = vim.api.nvim_get_hl(0, { name = 'InclineNormal', link = false })
        local attr = hl.reverse and 'guibg' or 'guifg'
        return {
            icon and { icon .. ' ', [attr] = color } or '',
            filename,
        }
    end,
})
