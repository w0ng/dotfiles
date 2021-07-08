-- Screen columns are are highlighted with ColorColumn (default '')
vim.opt.colorcolumn = { 80, 100 }
-- vim.options for Insert mode completion (default 'menu,preview')
vim.opt.completeopt:remove('preview')
-- Hide fold column in diff mode (default 'internal,filler,closeoff')
vim.opt.diffopt:append('foldcolumn:0')
-- When foldmethod = 'indent', lines starting with ignore get fold level from
-- surrounding lines (default '#')
vim.opt.foldignore = ''
-- Sets 'foldlevel' when starting to edit another buffer (default -1)
vim.opt.foldlevelstart = 99
-- The kind of folding used for the current window (default: 'manual')
vim.opt.foldmethod = 'indent'
-- Enables hiding a buffer instead of discarding buffer on unload (default off)
vim.opt.hidden = true
-- Enables mouse support (default '')
vim.opt.mouse = 'a'
-- Show cursor line number (default off)
vim.opt.number = true
-- When a bracket is inserted, briefly jump to the matching one (default off)
vim.opt.showmatch = true
-- Show Insert, Replace, or Visual message on the last line (default on)
vim.opt.showmode = false
-- Enables 24-bit RGB color in the TUI (default off)
vim.opt.termguicolors = true
-- Set title of the find to 'filename [+=-] (path) - NVIM' (default off)
vim.opt.title = true
-- Sets text wrap (default on)
vim.opt.wrap = false
