-- `:RG` - delegate search to ripgrep for faster grepping code
function _G.ripgrep_fzf(query, fullscreen)
  local command = table.concat({
    'rg',
    '--column',
    '--line-number',
    '--no-heading',
    '--color=always',
    -- yellow matching text
    '--colors',
    'match:fg:250,189,47',
    '--smart-case',
    '--',
    '%s',
    '||',
    'true',
  }, ' ')
  local initial_command = command:format(vim.fn.shellescape(query))
  local reload_command = command:format('{q}')
  local spec = vim.fn['fzf#vim#with_preview']({
    options = {
      '--phony',
      '--query',
      query,
      '--bind',
      'change:reload:' .. reload_command,
      -- Add all results to quickfix
      '--bind',
      'ctrl-q:select-all+accept',
    },
  })
  vim.fn['fzf#vim#grep'](initial_command, 1, spec, fullscreen)
end

vim.cmd('command! -nargs=* -bang RG call v:lua.ripgrep_fzf(<q-args>, <bang>0)')

-- Size and position of fzf window
-- Hide preview window by default, ctrl+/ to toggle.
vim.g.fzf_preview_window = { 'right:50%:hidden', 'ctrl-/' }

local map = vim.api.nvim_set_keymap
-- Navigate current buffers
map('n', '<Leader>b', ':Buffers<CR>', { noremap = true })
-- Navigate by text search
map('n', '<Leader>f', ':RG<CR>', { noremap = true })
-- Navigate by filename search
map('n', '<Leader>p', ':Files<CR>', { noremap = true })
-- Toggle git-blame sidebar
map('n', '<Leader>g', ':Git blame<CR>', { noremap = true })
