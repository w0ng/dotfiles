vim.g.vsnip_snippet_dir = '~/.config/nvim/snippets'

-- (Note: vsnip <Tab>/<S-Tab> completion integrated in plugin/compe.lua)
local map = vim.api.nvim_set_keymap
-- Expand
map('i', '<C-j>', 'vsnip#expandable() ? "<Plug>(vsnip-expand)" : ""', { expr = true })
map('s', '<C-j>', 'vsnip#expandable() ? "<Plug>(vsnip-expand)" : ""', { expr = true })
-- Jump to prev/next placeholder
map('i', '<C-h>', 'vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "<Left>"', { expr = true })
map('s', '<C-h>', 'vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "<Left>"', { expr = true })
map('i', '<C-l>', 'vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "<Right>"', { expr = true })
map('s', '<C-l>', 'vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "<Right>"', { expr = true })
-- Select text to use as $TM_SELECTED_TEXT in the next snippet.
-- `< goes to the first char of last selected area (like y)
map('v', '<Leader>s', '<Plug>(vsnip-select-text)<Esc>`<', {})
