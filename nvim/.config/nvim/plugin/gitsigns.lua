-- gitsigns.nvim: git decorators for modified lines
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })

local activity = require('async_activity')

-- Blame walks a file's whole history: slow in a large repo, slower again over a
-- remote connection. gitsigns.blame() takes a completion callback, so a count of
-- the in-flight calls is enough to know whether one is still going.
local blame_running = 0

local function blame_start()
    blame_running = blame_running + 1
    activity.poke()
end

local function blame_done()
    blame_running = math.max(0, blame_running - 1)
end

activity.register(function()
    return blame_running > 0 and 'git blame...' or nil
end)

require('gitsigns').setup({
    on_attach = function(_)
        local gitsigns = require('gitsigns')
        vim.keymap.set('n', '<Leader>g', function()
            blame_start()
            gitsigns.blame({ ignore_whitespace = true }, blame_done)
        end, { buffer = true, desc = 'Toggle git blame sidebar' })
    end,
})
