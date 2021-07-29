local galaxyline = require('galaxyline')
local condition = require('galaxyline.condition')
local provider_fileinfo = require('galaxyline.provider_fileinfo')

-- https://github.com/npxbr/gruvbox.nvim/blob/main/lua/gruvbox/colors.lua
local colors = {
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
}

local system_colors = {
  red = 'Maroon',
  green = 'DarkGreen',
  yellow = 'Olive',
  blue = 'DeepSkyBlue4',
  purple = 'Purple',
  aqua = 'DeepSkyBlue4',
  orange = 'DarkRed',
}

---@return string
local function filename_provider()
  local filename
  if vim.bo.filetype == 'qf' then
    filename = vim.w.quickfix_title or 'Quickfix'
  elseif vim.fn.winwidth(0) > 150 and vim.bo.filetype ~= 'help' then
    filename = vim.fn.expand('%:~:.')
  else
    filename = vim.fn.expand('%:t')
  end
  if filename == '' then
    return '[No Name]'
  end
  if vim.bo.readonly then
    return filename .. '  '
  end
  if vim.bo.modified then
    return filename .. '   '
  end
  return filename .. ' '
end

---@return string
local function filetype_provider()
  local filetype = vim.bo.filetype
  if filetype == '' then
    return 'no ft'
  end
  return filetype
end

table.insert(galaxyline.section.left, {
  ViMode = {
    ---@return string
    provider = function()
      local modes = {
        [110] = { char = 'n', fg = colors.dark0_hard, bg = colors.dark4 },
        [118] = { char = 'v', fg = system_colors.orange, bg = colors.orange },
        [86] = { char = 'V', fg = system_colors.orange, bg = colors.orange },
        [22] = { char = 'CTRL-V', fg = system_colors.orange, bg = colors.orange },
        [115] = { char = 's', fg = system_colors.orange, bg = colors.orange },
        [83] = { char = 'S', fg = system_colors.orange, bg = colors.orange },
        [19] = { char = 'CTRL-S', fg = system_colors.orange, bg = colors.orange },
        [105] = { char = 'i', fg = system_colors.green, bg = colors.green },
        [82] = { char = 'R', fg = system_colors.blue, bg = colors.blue },
        -- [99] = { char = 'c', fg = system_colors.purple, bg = colors.purple },
        -- [114] = { char = 'r', fg = system_colors.purple, bg = colors.purple },
        -- [33]  = { char = '!', fg = system_colors.red, bg = colors.red },
        [116] = { char = 't', fg = system_colors.red, bg = colors.red },
      }
      local mode = modes[vim.fn.mode():byte()]
      if mode then
        vim.api.nvim_command('hi GalaxyViMode guifg=' .. mode.fg .. ' guibg=' .. mode.bg)
      end
      if mode and (mode.char == 'i' or mode.char == 'R') then
        return '   '
      end
      return '   '
    end,
    separator = ' ',
    separator_highlight = { 'NONE', colors.dark0_hard },
    highlight = { colors.red, colors.dark0_hard, 'bold' },
  },
})

table.insert(galaxyline.section.left, {
  FileIcon = {
    provider = 'FileIcon',
    highlight = { provider_fileinfo.get_file_icon_color, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.left, {
  FileName = {
    provider = filename_provider,
    highlight = { colors.yellow, colors.dark0_hard, 'bold' },
  },
})

table.insert(galaxyline.section.left, {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = '  ',
    highlight = { colors.aqua, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.left, {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = { colors.blue, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.left, {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = { colors.yellow, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.left, {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = { colors.red, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.right, {
  GitIcon = {
    ---@return string
    provider = function()
      return '  '
    end,
    condition = condition.check_git_workspace,
    separator = ' ',
    separator_highlight = { 'NONE', colors.dark0_hard },
    highlight = { colors.purple, colors.dark0_hard, 'bold' },
  },
})

table.insert(galaxyline.section.right, {
  GitBranch = {
    -- galaxyline's GitBranch provider is mega slow during rebases
    -- Use git signs instead
    ---@return string
    provider = function()
      local branch = vim.b.gitsigns_head
      if branch and branch ~= '' then
        return branch .. ' '
      end
      return ''
    end,
    condition = condition.hide_in_width,
    highlight = { colors.purple, colors.dark0_hard, 'bold' },
  },
})

table.insert(galaxyline.section.right, {
  DiffAdd = {
    provider = 'DiffAdd',
    icon = ' ',
    highlight = { colors.green, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.right, {
  DiffModified = {
    provider = 'DiffModified',
    icon = '柳',
    highlight = { colors.orange, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.right, {
  DiffRemove = {
    provider = 'DiffRemove',
    icon = ' ',
    highlight = { colors.red, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.right, {
  FileType = {
    provider = filetype_provider,
    separator = ' ',
    separator_highlight = { 'NONE', colors.dark0_hard },
    highlight = { colors.blue, colors.dark0_hard, 'bold' },
  },
})

table.insert(galaxyline.section.right, {
  LineColumn = {
    provider = 'LineColumn',
    separator = ' ',
    separator_highlight = { 'NONE', colors.dark0_hard },
    highlight = { colors.blue, colors.dark0_hard, 'bold' },
  },
})

galaxyline.short_line_list = { 'DiffviewFiles', 'NvimTree', 'fzf', 'packer' }

table.insert(galaxyline.section.short_line_left, {
  SpacerInactiveLeft = {
    ---@return string
    provider = function()
      return ' '
    end,
    highlight = { colors.light4, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.short_line_left, {
  FileNameInactive = {
    provider = filename_provider,
    highlight = { colors.light4, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.short_line_right, {
  BufferIconInactive = {
    provider = 'BufferIcon',
    highlight = { colors.light4, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.short_line_right, {
  FileTypeInactive = {
    provider = filetype_provider,
    separator = ' ',
    separator_highlight = { 'NONE', colors.dark0_hard },
    highlight = { colors.light4, colors.dark0_hard },
  },
})

table.insert(galaxyline.section.short_line_right, {
  LineColumnInactive = {
    provider = 'LineColumn',
    separator = ' ',
    separator_highlight = { 'NONE', colors.dark0_hard },
    highlight = { colors.light4, colors.dark0_hard },
  },
})
