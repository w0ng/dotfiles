--- General
-- Screen columns are are highlighted with ColorColumn (default '')
vim.opt.colorcolumn = { 80, 100 }
-- Hide fold column in diff mode (default 'internal,filler,closeoff')
vim.opt.diffopt:append('foldcolumn:0')
-- When foldmethod == 'indent', lines starting with ignore get fold level from
-- surrounding lines (default '#')
vim.opt.foldignore = ''
-- Sets 'foldlevel' when starting to edit another buffer (default -1)
vim.opt.foldlevelstart = 99
-- The kind of folding used for the current window (default: 'manual')
vim.opt.foldmethod = 'indent'
-- Enables hiding a buffer instead of discarding buffer on unload (default off)
vim.opt.hidden = true
-- Only show statusline on last window (default 2)
vim.opt.laststatus = 3
-- Enables mouse support (default '')
vim.opt.mouse = 'a'
-- Show cursor line number (default off)
vim.opt.number = true
-- Show Insert, Replace, or Visual message on the last line (default on)
vim.opt.showmode = false
-- Enables 24-bit RGB color in the TUI (default off)
vim.opt.termguicolors = true
-- Set title of the find to 'filename [+=-] (path) - NVIM' (default off)
vim.opt.title = true
-- Sets text wrap (default on)
vim.opt.wrap = false

--- Indent
-- Number of spaces to insert a <Tab> in insert mode
vim.opt.expandtab = true
-- Number of spaces to use for each (auto)indent step (default 8)
vim.opt.shiftwidth = 2
-- Number of spaces that a <Tab> and <BS> counts during editing (default 0)
vim.opt.softtabstop = 2
-- Number of spaces that a <Tab> in the file counts for (default 8)
vim.opt.tabstop = 2

-- Search
-- Ignore case in search patterns (default off)
vim.opt.ignorecase = true
-- Override 'ignorecase' if the search pattern contains upper case (default off)
vim.opt.smartcase = true
-- Use ripgrep for grep command if installed (default 'grep -n ')
if vim.fn.executable('rg') then
  vim.opt.grepprg = 'rg --no-heading --vimgrep'
end
