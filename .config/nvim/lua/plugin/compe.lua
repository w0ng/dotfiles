require('compe').setup({
  documentation = {
    border = 'rounded',
  },
  source = {
    path = true,
    buffer = true,
    nvim_lsp = true,
    vsnip = true,
  },
})

-- Pre-requisite for autocompletion window
vim.opt.completeopt = 'menuone,noselect'
-- Ignore ins-completion-menu messages in cmdline e.g. 'Pattern not found'
vim.opt.shortmess:append('c')

---Convert terminal keycode mappings e.g. '<CR>' --> '\n'
---@param str string
---@return string
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---@return boolean
local check_back_space = function()
  local col = vim.fn.col('.') - 1
  local line = vim.fn.getline('.')
  if col == 0 or line:sub(col, col):match('%s') then
    return true
  else
    return false
  end
end

---Use <Tab> to:
--expand or move to next item in completion menuone
--jump to next snippet's placeholder
---@return string
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t('<C-n>')
  elseif vim.fn['vsnip#available'](1) == 1 then
    return t('<Plug>(vsnip-expand-or-jump)')
  elseif check_back_space() then
    return t('<Tab>')
  else
    return vim.fn['compe#complete']()
  end
end

---Use <S-Tab> to:
--move to prev item in completion menuone
--jump to prev snippet's placeholder
---@return string
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t('<C-p>')
  elseif vim.fn['vsnip#jumpable'](-1) == 1 then
    return t('<Plug>(vsnip-jump-prev)')
  else
    return t('<S-Tab>')
  end
end

--- Keymappings
local map = vim.api.nvim_set_keymap
-- Tab completion
map('i', '<Tab>', 'v:lua.tab_complete()', { expr = true })
map('s', '<Tab>', 'v:lua.tab_complete()', { expr = true })
map('i', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
map('s', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
-- Complete highlighted suggestion
map('i', '<C-Space>', 'compe#complete()', { expr = true, silent = true })
-- Confirm highlighted suggestion (auto-import, snippets, etc)
map('i', '<CR>', 'compe#confirm("<CR>")', { expr = true, silent = true })
-- Close autocomplete menu
map('i', '<C-e>', 'compe#close("<C-e>")', { expr = true, silent = true })
-- Scroll up/down documentation window for highlighted suggestion
map('i', '<C-f>', 'compe#scroll({ "delta": +4 })', { expr = true, silent = true })
map('i', '<C-d>', 'compe#scroll({ "delta": -4 })', { expr = true, silent = true })
