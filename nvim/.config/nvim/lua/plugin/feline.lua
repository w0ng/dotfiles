local colors = {
  -- https://github.com/npxbr/gruvbox.nvim/blob/main/lua/gruvbox/colors.lua
  gruvbox = {
    dark0_hard = '#1d2021',
    -- dark0 = '#282828',
    -- dark0_soft = '#32302f',
    -- dark1 = '#3c3836',
    -- dark2 = '#504945',
    -- dark3 = '#665c54',
    dark4 = '#7c6f64',
    -- light0_hard = '#f9f5d7',
    -- light0 = '#fbf1c7',
    -- light0_soft = '#f2e5bc',
    -- light1 = '#ebdbb2',
    -- light2 = '#d5c4a1',
    -- light3 = '#bdae93',
    light4 = '#a89984',
    red = '#fb4934',
    green = '#b8bb26',
    yellow = '#fabd2f',
    blue = '#83a598',
    purple = '#d3869b',
    aqua = '#8ec07c',
    orange = '#fe8019',
  },

  system = {
    red = 'Maroon',
    green = 'DarkGreen',
    yellow = 'Olive',
    blue = 'DeepSkyBlue4',
    purple = 'Purple',
    aqua = 'DeepSkyBlue4',
    orange = 'DarkRed',
  },
}

local vi_modes = {
  [110] = { char = 'n', fg = colors.gruvbox.dark0_hard, bg = colors.gruvbox.dark4 },
  [118] = { char = 'v', fg = colors.system.orange, bg = colors.gruvbox.orange },
  [86] = { char = 'V', fg = colors.system.orange, bg = colors.gruvbox.orange },
  [22] = { char = 'CTRL-V', fg = colors.system.orange, bg = colors.gruvbox.orange },
  [115] = { char = 's', fg = colors.system.orange, bg = colors.gruvbox.orange },
  [83] = { char = 'S', fg = colors.system.orange, bg = colors.gruvbox.orange },
  [19] = { char = 'CTRL-S', fg = colors.system.orange, bg = colors.gruvbox.orange },
  [105] = { char = 'i', fg = colors.system.green, bg = colors.gruvbox.green },
  [82] = { char = 'R', fg = colors.system.blue, bg = colors.gruvbox.blue },
  -- [99] = { char = 'c', fg = colors.system.purple, bg = colors.gruvbox.purple },
  -- [114] = { char = 'r', fg = colors.system.purple, bg = colors.gruvbox.purple },
  -- [33]  = { char = '!', fg = colors.system.red, bg = colors.gruvbox.red },
  [116] = { char = 't', fg = colors.system.red, bg = colors.gruvbox.red },
}

local SECTION = { LEFT = 1, MIDDLE = 2, RIGHT = 3 }
local components = {
  active = { {}, {}, {} },
  inactive = { {}, {}, {} },
}

table.insert(components.active[SECTION.LEFT], {
  provider = function()
    local mode = vi_modes[vim.api.nvim_get_mode().mode:byte()]
    if mode and (mode.char == 'i' or mode.char == 'R') then
      return '  '
    end
    return '  '
  end,
  hl = function()
    local vi_mode = vi_modes[vim.api.nvim_get_mode().mode:byte()]
    local normal_mode = vi_modes[110]
    return {
      fg = vi_mode and vi_mode.fg or normal_mode.fg,
      bg = vi_mode and vi_mode.bg or normal_mode.bg,
    }
  end,
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'file_info',
    opts = {
      type = 'relative',
      file_modified_icon = '',
      file_readonly_icon = ' ',
    },
  },
  short_provider = {
    name = 'file_info',
    opts = {
      type = 'base-only',
      file_modified_icon = '',
      file_readonly_icon = ' ',
    },
  },
  hl = {
    fg = colors.gruvbox.yellow,
  },
  left_sep = ' ',
  right_sep = ' ',
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_errors',
  },
  hl = {
    fg = colors.gruvbox.red,
  },
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_warnings',
  },
  hl = {
    fg = colors.gruvbox.yellow,
  },
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_info',
  },
  hl = {
    fg = colors.gruvbox.blue,
  },
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_hints',
  },
  hl = {
    fg = colors.gruvbox.aqua,
  },
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_branch',
  },
  hl = {
    fg = colors.gruvbox.purple,
  },
  left_sep = ' ',
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_diff_added',
  },
  hl = {
    fg = colors.gruvbox.green,
  },
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_diff_removed',
  },
  hl = {
    fg = colors.gruvbox.red,
  },
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_diff_changed',
  },
  hl = {
    fg = colors.gruvbox.orange,
  },
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = function()
    return vim.bo.filetype
  end,
  hl = {
    fg = colors.gruvbox.blue,
  },
  left_sep = ' ',
})

table.insert(components.active[SECTION.RIGHT], {
  provider = 'position',
  hl = {
    fg = colors.gruvbox.blue,
  },
  left_sep = ' ',
  right_sep = ' ',
})

table.insert(components.inactive[SECTION.LEFT], {
  provider = {
    name = 'file_info',
    opts = {
      type = 'relative',
      file_modified_icon = '',
      file_readonly_icon = ' ',
      colored_icon = false,
    },
  },
  short_provider = {
    name = 'file_info',
    opts = {
      type = 'base-only',
      file_modified_icon = '',
      file_readonly_icon = ' ',
      colored_icon = false,
    },
  },
  hl = {
    fg = colors.gruvbox.light4,
  },
  left_sep = ' ',
  right_sep = ' ',
})

require('feline').setup({ components = components })
