local galaxyline = require('galaxyline')
local condition = require('galaxyline.condition')
local provider_fileinfo = require('galaxyline.provider_fileinfo')
local provider_vcs = require('galaxyline.provider_vcs')

-- Gruvbox colorscheme: https://github.com/morhetz/gruvbox
local colors = {
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
  bg = '#1d2021',
  fg = '#ebdbb2',
  yellow = '#fabd2f',
  cyan = '#8ec07c',
  darkblue = '#458588',
  green = '#b8bb26',
  orange = '#fe8019',
  violet = '#d3869b',
  magenta = '#b16286',
  blue = '#83a598';
  red = '#fb4934';
  bg_inactive = '#32302f',
  fg_inactive = '#a89984',

}

local function filename_provider()
  local filename = provider_fileinfo.get_current_file_name();
  if filename == '' then
    return '[No Name]'
  end
  return filename
end

local function filetype_provider()
  local filetype = vim.bo.filetype
  if filetype == '' then
    return 'no ft'
  end
  return filetype
end

local function winwidth_condition()
  return vim.fn.winwidth(0) / 2 > 40
end

table.insert(galaxyline.section.left, {
  SpacerLeft = {
    provider = function()
      return ' '
    end,
    highlight = {colors.fg,colors.bg}
  }
})

table.insert(galaxyline.section.left, {
  ViMode = {
    provider = function()
      -- auto change color according the vim mode
      local mode_color = {
        n = colors.red,
        i = colors.green,
        v=colors.blue,
        [''] = colors.blue,
        V=colors.blue,
        c = colors.magenta,
        no = colors.red,
        s = colors.orange,
        S=colors.orange,
        [''] = colors.orange,
        ic = colors.yellow,
        R = colors.violet,
        Rv = colors.violet,
        cv = colors.red,
        ce=colors.red,
        r = colors.cyan,
        rm = colors.cyan,
        ['r?'] = colors.cyan,
        ['!']  = colors.red,
        t = colors.red
      }
      vim.api.nvim_command('hi GalaxyViMode guifg='..mode_color[vim.fn.mode()])
      return '  '
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
    highlight = {colors.cyan,colors.bg},
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
    highlight = {colors.violet,colors.bg,'bold'},
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
    condition = condition.check_git_workspace and winwidth_condition,
    highlight = {colors.violet,colors.bg,'bold'},
  }
})

table.insert(galaxyline.section.right, {
  DiffAdd = {
    provider = 'DiffAdd',
    condition = winwidth_condition,
    icon = ' ',
    highlight = {colors.green,colors.bg},
  }
})

table.insert(galaxyline.section.right, {
  DiffModified = {
    provider = 'DiffModified',
    condition = winwidth_condition,
    icon = '柳',
    highlight = {colors.orange,colors.bg},
  }
})

table.insert(galaxyline.section.right, {
  DiffRemove = {
    provider = 'DiffRemove',
    condition = winwidth_condition,
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
    provider = function()
      return ' '
    end,
    highlight = {colors.fg,colors.bg}
  }
})

galaxyline.short_line_list = { 'NvimTree', 'fzf', 'packer' }

table.insert(galaxyline.section.short_line_left, {
  SpacerShortLeft = {
    provider = function()
      return ' '
    end,
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
    provider = function()
      return ' '
    end,
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
