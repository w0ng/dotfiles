-- Ignore case in search patterns (default off)
vim.opt.ignorecase = true
-- Override 'ignorecase' if the search pattern contains upper case (default off)
vim.opt.smartcase = true
-- Use ripgrep for grep command if installed (default 'grep -n ')
if vim.fn.executable('rg') then
  vim.opt.grepprg = 'rg --no-heading --vimgrep'
end
