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
    -- Transparent SignColumn
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
  },
})

-- Set colorscheme, make statusline and pop-up menu darker
vim.cmd.colorscheme('gruvbox')
