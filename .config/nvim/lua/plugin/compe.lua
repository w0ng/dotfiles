require('compe').setup({
  enabled = true,
  autocomplete = true,
  debug = false,
  min_length = 1,
  preselect = 'enable',
  throttle_time = 80,
  source_timeout = 200,
  resolve_timeout = 800,
  incomplete_delay = 400,
  max_abbr_width = 100,
  max_kind_width = 100,
  max_menu_width = 100,
  documentation = {
    -- the border option is the same as `|help nvim_open_win|`
    border = { '', '', '', ' ', '', '', '', ' ' },
    winhighlight = 'NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder',
    max_width = 120,
    min_width = 60,
    max_height = math.floor(vim.o.lines * 0.3),
    min_height = 1,
  },
  source = {
    path = true,
    nvim_lsp = true,
    nvim_lua = true,
    vsnip = true,
  },
})

-- Pre-requisite for autocompletion window
vim.opt.completeopt = 'menuone,noselect'
-- Ignore ins-completion-menu messages in cmdline e.g. 'Pattern not found'
vim.opt.shortmess:append('c')

-- Set keymap
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
    return true
  else
    return false
  end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t '<C-n>'
  elseif vim.fn['vsnip#available'](1) == 1 then
    return t '<Plug>(vsnip-expand-or-jump)'
  elseif check_back_space() then
    return t '<Tab>'
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t '<C-p>'
  elseif vim.fn['vsnip#jumpable'](-1) == 1 then
    return t '<Plug>(vsnip-jump-prev)'
  else
    return t '<S-Tab>'
  end
end

-- Tab completion
vim.api.nvim_set_keymap('i', '<Tab>', 'v:lua.tab_complete()', { expr = true })
vim.api.nvim_set_keymap('s', '<Tab>', 'v:lua.tab_complete()', { expr = true })
vim.api.nvim_set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
vim.api.nvim_set_keymap('s', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
-- Complete highlighted suggestion
vim.api.nvim_set_keymap('i', '<C-Space>', 'compe#complete()', { expr = true, silent = true })
-- Confirm highlighted suggestion (auto-import, snippets, etc)
vim.api.nvim_set_keymap('i', '<CR>', 'compe#confirm("<CR>")', { expr = true, silent = true })
-- Close autocomplete menu
vim.api.nvim_set_keymap('i', '<C-e>', 'compe#close("<C-e>")', { expr = true, silent = true })
-- Scroll up/down documentation window for highlighted suggestion
vim.api.nvim_set_keymap('i', '<C-f>', 'compe#scroll({ "delta": +4 })', { expr = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-d>', 'compe#scroll({ "delta": -4 })', { expr = true, silent = true })
