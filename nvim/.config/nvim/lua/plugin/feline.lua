-- https://github.com/ellisonleao/gruvbox.nvim/blob/7a5c7ace3ac169b2898a4c7d8abec42cf9e18003/lua/gruvbox/palette.lua
local gruvbox_colors = require('gruvbox.palette')

local system_colors = {
  red = 'Maroon',
  green = 'DarkGreen',
  yellow = 'Olive',
  blue = 'DeepSkyBlue4',
  purple = 'Purple',
  aqua = 'DeepSkyBlue4',
  orange = 'DarkRed',
}

local vi_modes = {
  [110] = { char = 'n', fg = gruvbox_colors.dark0_hard, bg = gruvbox_colors.dark4 },
  [118] = { char = 'v', fg = system_colors.orange, bg = gruvbox_colors.bright_orange },
  [86] = { char = 'V', fg = system_colors.orange, bg = gruvbox_colors.bright_orange },
  [22] = { char = 'CTRL-V', fg = system_colors.orange, bg = gruvbox_colors.bright_orange },
  [115] = { char = 's', fg = system_colors.orange, bg = gruvbox_colors.bright_orange },
  [83] = { char = 'S', fg = system_colors.orange, bg = gruvbox_colors.bright_orange },
  [19] = { char = 'CTRL-S', fg = system_colors.orange, bg = gruvbox_colors.bright_orange },
  [105] = { char = 'i', fg = system_colors.green, bg = gruvbox_colors.bright_green },
  [82] = { char = 'R', fg = system_colors.blue, bg = gruvbox_colors.bright_blue },
  -- [99] = { char = 'c', fg = system_colors.purple, bg = gruvbox_colors.bright_purple },
  -- [114] = { char = 'r', fg = system_colors.purple, bg = gruvbox_colors.bright_purple },
  -- [33]  = { char = '!', fg = system_colors.red, bg = gruvbox_colors.bright_red },
  [116] = { char = 't', fg = system_colors.red, bg = gruvbox_colors.bright_red },
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
    name = 'diagnostic_errors',
  },
  hl = {
    fg = gruvbox_colors.bright_red,
  },
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_warnings',
  },
  hl = {
    fg = gruvbox_colors.bright_yellow,
  },
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_info',
  },
  hl = {
    fg = gruvbox_colors.bright_blue,
  },
})

table.insert(components.active[SECTION.LEFT], {
  provider = {
    name = 'diagnostic_hints',
  },
  hl = {
    fg = gruvbox_colors.bright_aqua,
  },
})

table.insert(components.active[SECTION.MIDDLE], {
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
    fg = gruvbox_colors.bright_yellow,
  },
  left_sep = ' ',
  right_sep = ' ',
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_branch',
  },
  hl = {
    fg = gruvbox_colors.bright_purple,
  },
  left_sep = ' ',
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_diff_added',
  },
  hl = {
    fg = gruvbox_colors.bright_green,
  },
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_diff_removed',
  },
  hl = {
    fg = gruvbox_colors.bright_red,
  },
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = {
    name = 'git_diff_changed',
  },
  hl = {
    fg = gruvbox_colors.bright_orange,
  },
  truncate_hide = true,
})

table.insert(components.active[SECTION.RIGHT], {
  provider = function()
    return vim.bo.filetype
  end,
  hl = {
    fg = gruvbox_colors.bright_blue,
  },
  left_sep = ' ',
})

table.insert(components.active[SECTION.RIGHT], {
  provider = 'position',
  hl = {
    fg = gruvbox_colors.bright_blue,
  },
  left_sep = ' ',
  right_sep = ' ',
})

table.insert(components.inactive[SECTION.MIDDLE], {
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
    fg = gruvbox_colors.light4,
  },
  left_sep = ' ',
  right_sep = ' ',
})

require('feline').setup({ components = components })
