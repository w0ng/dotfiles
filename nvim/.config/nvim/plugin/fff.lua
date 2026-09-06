-- fff.nvim: fast file finder
--------------------------------------------------------------------------------
-- fff ships a Rust binary that has to be downloaded or built. Registered above
-- the add() below so it also fires on the very first install.
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local kind = ev.data.kind
        if ev.data.spec.name == 'fff.nvim' and (kind == 'install' or kind == 'update') then
            if not ev.data.active then
                vim.cmd.packadd('fff.nvim')
            end
            require('fff.download').download_or_build_binary()
        end
    end,
})

vim.pack.add({ 'https://github.com/dmtrKovalenko/fff.nvim' })

-- Optional per-machine overrides, supplied by a private overlay; absent on a
-- plain checkout, hence the pcall.
local ok_local, localcfg = pcall(require, 'local')
if not ok_local then
    localcfg = {}
end

-- fff eagerly indexes (full file scan + frecency/history DBs) at startup unless
-- lazy_sync is true. Only pay that inside a real project root -- this repo, plus
-- anything lua/local.lua adds. Elsewhere (home, /tmp, ad-hoc dirs) it stays lazy
-- and the index builds on demand at the first <Leader>p / <Leader>f.
--
-- fff reads vim.g.fff.lazy_sync at UIEnter, so setup() here still wins. init.lua
-- is a stow symlink, so resolving it finds the repo wherever it is checked out.
local function dotfiles_root()
    return vim.fs.root(vim.fn.resolve(vim.fn.stdpath('config') .. '/init.lua'), '.git')
end

local function fff_eager_root()
    local cwd = vim.fn.getcwd()
    -- A nil from dotfiles_root() just yields an empty table, so ipairs below
    -- never sees a hole and needs no guard.
    local roots = { dotfiles_root() }
    for _, extra in ipairs(localcfg.eager_roots or {}) do
        table.insert(roots, vim.fn.expand(extra))
    end
    for _, root in ipairs(roots) do
        if cwd == root or vim.startswith(cwd, root .. '/') then
            return true
        end
    end
    return false
end

require('fff').setup({
    prompt_vim_mode = false,
    preview = {
        enabled = false,
    },
    -- false = eager scan/cache at startup; true = lazy (build index on first use).
    lazy_sync = not fff_eager_root(),
    -- Never index $HOME directly (default is true). Stops a stray picker open
    -- from the home dir from trying to scan the entire home tree.
    enable_home_dir_scanning = false,
})
vim.keymap.set('n', '<Leader>p', function()
    require('fff').find_files()
end, { desc = 'Find files' })
vim.keymap.set('n', '<Leader>f', function()
    require('fff').live_grep()
end, { desc = 'Live grep' })
vim.keymap.set('n', '<Leader>s', function()
    require('fff').live_grep({ query = vim.fn.expand('<cword>') })
end, { desc = 'Grep current word' })
