-- <Esc> closes whichever of the two list windows is open. <Cmd> keeps this off
-- the cmdline, so it works regardless of the ';'/':' swap in init.lua.
vim.keymap.set('n', '<Esc>', '<Cmd>cclose <Bar> lclose<CR>', {
    buffer = true,
    desc = 'Close quickfix/location list',
})
