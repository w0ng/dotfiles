-- `:RG` - delegate search to ripgrep for faster grepping code
-- `--colors  "match:fg:250,189,47"` -> yellow matching text
vim.cmd([[
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --colors  "match:fg:250,189,47" --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
]])

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
