-- gruvbox.nvim: dark colorscheme
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/ellisonleao/gruvbox.nvim' })

local colors = require('gruvbox').palette

require('gruvbox').setup({
    bold = false,
    italic = {
        strings = false,
        emphasis = false,
        comments = false,
        operators = false,
        folds = false,
    },
    overrides = {
        -- Paint the gutter in Normal's own background so signs sit on the
        -- same colour as the text, with no lighter strip down the left.
        SignColumn = { bg = colors.dark0 },
        GruvboxRedSign = { fg = colors.neutral_red, bg = colors.dark0, reverse = false },
        GruvboxGreenSign = { fg = colors.neutral_green, bg = colors.dark0, reverse = false },
        GruvboxYellowSign = { fg = colors.neutral_yellow, bg = colors.dark0, reverse = false },
        GruvboxBlueSign = { fg = colors.neutral_blue, bg = colors.dark0, reverse = false },
        GruvboxPurpleSign = { fg = colors.neutral_purple, bg = colors.dark0, reverse = false },
        GruvboxAquaSign = { fg = colors.neutral_aqua, bg = colors.dark0, reverse = false },
        GruvboxOrangeSign = { fg = colors.neutral_orange, bg = colors.dark0, reverse = false },

        -- Darker StatusLine
        StatusLine = { fg = colors.dark0_hard, bg = colors.bright_yellow, reverse = true },
        StatusLineNC = { fg = colors.dark0_hard, bg = colors.light4, reverse = true },

        -- Darker LSP popup menu
        Pmenu = { fg = colors.light1, bg = colors.dark0_soft },
        PmenuSel = { fg = colors.dark0_soft, bg = colors.bright_blue },
        PmenuSbar = { bg = colors.dark2 },
        PmenuThumb = { bg = colors.dark3 },
        FloatBorder = { fg = colors.dark3, bg = colors.dark0_soft },
        QuickFixLine = { fg = colors.bright_yellow, bg = 'none' },

        -- Render bold only in markdown files (disabled elsewhere)
        ['@markup.strong.markdown_inline'] = { bold = true },
    },
})

-- bold = false above turns off bold everywhere, which flattens markdown
-- headings into body text. Restore it for headings only, in Title's colour.
--
-- On a ColorScheme autocmd rather than inline, for two reasons. Loading a
-- colorscheme resets every highlight group, so anything set beforehand is
-- discarded, and Title itself only holds gruvbox's colour once gruvbox has
-- loaded. It also re-applies on any later reload, which plugin/neovide.lua
-- triggers when it sets 'background'.
vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = 'gruvbox',
    callback = function()
        local title_fg = vim.api.nvim_get_hl(0, { name = 'Title', link = false }).fg
        for level = 1, 6 do
            vim.api.nvim_set_hl(0, '@markup.heading.' .. level .. '.markdown', {
                fg = title_fg,
                bold = true,
            })
        end
        vim.api.nvim_set_hl(0, '@markup.heading.markdown', { fg = title_fg, bold = true })
    end,
})

vim.cmd.colorscheme('gruvbox')
