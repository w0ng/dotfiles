local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed
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
            return ''
          end
          return ''
        end,
      },
    },
    lualine_b = {
      {'diff', source = diff_source},
      -- https://github.com/nvim-lualine/lualine.nvim/issues/1355
      {
        'macro',
        fmt = function()
          local reg = vim.fn.reg_recording()
          if reg ~= '' then
            return 'Recording @' .. reg
          end
          return nil
        end,
        draw_empty = false,
      },
    },
    lualine_c = {
      '%=',
      { 'filename', path = 1, color = { fg = '#fabd2f', gui = '' } },
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
