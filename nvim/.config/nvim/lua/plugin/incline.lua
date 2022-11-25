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
})
