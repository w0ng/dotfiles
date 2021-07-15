local galaxyline = require('galaxyline')
local condition = require('galaxyline.condition')
local provider_fileinfo = require('galaxyline.provider_fileinfo')
local provider_vcs = require('galaxyline.provider_vcs')

-- Gruvbox colorscheme: https://github.com/morhetz/gruvbox
-- dark0_hard = hsl("#1d2021"),
-- dark0 = hsl("#282828"),
-- dark0_soft = hsl("#32302f"),
-- dark1 = hsl("#3c3836"),
-- dark2 = hsl("#504945"),
-- dark3 = hsl("#665c54"),
-- dark4 = hsl("#7c6f64"),
-- light0_hard = hsl("#f9f5d7"),
-- light0 = hsl("#fbf1c7"),
-- light0_soft = hsl("#f2e5bc"),
-- light1 = hsl("#ebdbb2"),
-- light2 = hsl("#d5c4a1"),
-- light3 = hsl("#bdae93"),
-- light4 = hsl("#a89984"),
-- statusline: bg=#4F4945 fg=#ebdbb2
-- statuslinenc: bg=#3B3735 fg=#A89985
local colors = {
  bg = '#1d2021',
  bg_inactive = '#32302f',
  fg = '#ebdbb2',
  fg_inactive = '#a89984',
  red = '#fb4934';
  green = '#b8bb26',
  yellow = '#fabd2f',
  blue = '#83a598';
  purple = '#d3869b',
  aqua = '#8ec07c',
  orange = '#fe8019',
}

local function spacer_provider()
  return ' '
end

local function filename_provider()
  local filename
  if vim.fn.winwidth(0) > 150 and vim.bo.filetype ~= 'help' then
    filename = vim.fn.expand('%:~:.')
  else
    filename = vim.fn.expand('%:t')
  end
  if filename == '' then return '[No Name]' end
  if vim.bo.readonly then return filename .. '  ' end
  if vim.bo.modified then return filename .. '   ' end
  return filename .. ' '
end

local function filetype_provider()
  local filetype = vim.bo.filetype
  if filetype == '' then
    return 'no ft'
  end
  return filetype
end

table.insert(galaxyline.section.left, {
  SpacerLeft = {
    provider = spacer_provider,
    highlight = {colors.fg,colors.bg}
  }
})

table.insert(galaxyline.section.left, {
  ViMode = {
    provider = function()
      -- auto change color according the vim mode
      local mode_colors = {
        -- 'n' NORMAL
        [110] = colors.red,
        -- 'v' VISUAL
        [118] = colors.blue,
        -- 'V' V-LINE
        [86] = colors.blue,
        -- Ctrl+v ctrl+v V-BLOCK
        [22] = colors.blue,
        -- 's' SELECT
        [115] = colors.orange,
        -- 'S' S-LINE
        [83] = colors.orange,
        -- Ctrl+v Ctrl+s S-BLOCK
        [19] = colors.orange,
        -- 'i' INSERT
        [105] = colors.green,
        -- 'R' REPLACE
        [82] = colors.purple,
        -- 'c' COMMAND
        [99] = colors.purple,
        -- 'r' Hit enter prompt
        [114] = colors.aqua,
        -- '!' SHELL
        [33]  = colors.red,
        -- t TERMINAL
        [116] = colors.red,
      }
      local mode_char = vim.fn.mode():byte()
      local color = mode_colors[mode_char]
      if color then
        vim.api.nvim_command('hi GalaxyViMode guifg=' .. color)
      end
      return '  '
    end,
    highlight = {colors.red,colors.bg,'bold'},
  },
})

table.insert(galaxyline.section.left, {
  FileIcon = {
   provider = 'FileIcon',
    highlight = { provider_fileinfo.get_file_icon_color,colors.bg },
  },
})

table.insert(galaxyline.section.left, {
  FileName = {
    provider = filename_provider,
    highlight = {colors.yellow,colors.bg,'bold'}
  }
})

table.insert(galaxyline.section.left, {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = '  ',
    highlight = {colors.aqua,colors.bg},
  }
})

table.insert(galaxyline.section.left, {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = {colors.blue,colors.bg},
  }
})

table.insert(galaxyline.section.left, {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.yellow,colors.bg},
  }
})

table.insert(galaxyline.section.left, {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {colors.red,colors.bg}
  }
})

table.insert(galaxyline.section.right, {
  GitIcon = {
    provider = function() return '  ' end,
    condition = condition.check_git_workspace,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.purple,colors.bg,'bold'},
  }
})

table.insert(galaxyline.section.right, {
  GitBranch = {
    provider = function()
      local branch = provider_vcs.get_git_branch()
      if not branch then
        return
      end
      return branch .. ' '
    end,
    condition = condition.hide_in_width,
    highlight = {colors.purple,colors.bg,'bold'},
  }
})

table.insert(galaxyline.section.right, {
  DiffAdd = {
    provider = 'DiffAdd',
    icon = ' ',
    highlight = {colors.green,colors.bg},
  }
})

table.insert(galaxyline.section.right, {
  DiffModified = {
    provider = 'DiffModified',
    icon = '柳',
    highlight = {colors.orange,colors.bg},
  }
})

table.insert(galaxyline.section.right, {
  DiffRemove = {
    provider = 'DiffRemove',
    icon = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.red,colors.bg},
  }
})

table.insert(galaxyline.section.right, {
  FileType = {
    provider = filetype_provider,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.blue,colors.bg,'bold'}
  }
})

table.insert(galaxyline.section.right, {
  LineColumn = {
    provider = 'LineColumn',
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.blue,colors.bg,'bold'}
  }
})

table.insert(galaxyline.section.right, {
  SpacerRight = {
    provider = spacer_provider,
    highlight = {colors.fg,colors.bg}
  }
})

galaxyline.short_line_list = { 'NvimTree', 'fzf', 'packer' }

table.insert(galaxyline.section.short_line_left, {
  SpacerShortLeft = {
    provider = spacer_provider,
    highlight = {colors.fg_inactive,colors.bg}
  }
})

table.insert(galaxyline.section.short_line_left, {
  FileNameShort = {
    provider = filename_provider,
    highlight = {colors.fg_inactive,colors.bg}
  }
})

table.insert(galaxyline.section.short_line_right, {
  SpacerShortRight = {
    provider = spacer_provider,
    highlight = {colors.fg_inactive,colors.bg}
  }
})

table.insert(galaxyline.section.short_line_right, {
  BufferIconShort = {
    provider= 'BufferIcon',
    highlight = {colors.fg_inactive,colors.bg}
  }
})

table.insert(galaxyline.section.short_line_right, {
  FileTypeShort = {
    provider = filetype_provider,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.fg_inactive,colors.bg}
  }
})

table.insert(galaxyline.section.short_line_right, {
  LineColumnShort = {
    provider = 'LineColumn',
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.fg_inactive,colors.bg}
  }
})
