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
            return ''
          end
          return ''
        end,
      },
    },
    lualine_b = {},
    lualine_c = {
      '%=',
      { 'filename', color = { fg = '#fabd2f', gui = '' } },
    },
    lualine_x = {},
    lualine_y = {
      { 'diagnostics', color = { gui = '' } },
    },
    lualine_z = {
      { 'location', color = { gui = '' } },
    },
  },
})
