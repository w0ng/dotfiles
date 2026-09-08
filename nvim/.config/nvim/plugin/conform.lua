-- conform.nvim: single formatting path (dprint + stylua, format on save)
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })

local conform = require('conform')

-- Optional per-machine overrides, supplied by a private overlay; absent on a
-- plain checkout, hence the pcall.
local ok_local, localcfg = pcall(require, 'local')
if not ok_local then
    localcfg = {}
end

-- Inside any checkout (main repo OR a git worktree, wherever it lives) that
-- vendors its own dprint, format with THAT binary so output matches the repo's
-- CI; elsewhere fall back to system dprint + personal config.
--
-- The sub-path is repo-specific, so it lives in lua/local.lua rather than here.
-- Without it this returns nil and the plain `dprint` lookup wins, which is
-- already right whenever the checkout puts its own copy on PATH (a direnv
-- PATH_add, say). What this covers is when it does not, such as nvim launched
-- from a shell where that never happened, or one nvim editing files across two
-- checkouts, since PATH is fixed at launch while this resolves per buffer.
--
-- Memoised on the containing directory. conform asks for the command and the
-- arguments separately, so an uncached lookup walks the tree upward twice per
-- format, and again on every save. false is the cached "no fork here", since a
-- nil entry is indistinguishable from an absent one.
local repo_dprint_cache = {}

local function repo_dprint(filename)
    local sub = localcfg.dprint_subpath
    if not sub or type(filename) ~= 'string' then
        return nil
    end
    local dir = vim.fs.dirname(filename)
    local cached = repo_dprint_cache[dir]
    if cached ~= nil then
        return cached or nil
    end

    local found = false
    local git = vim.fs.find('.git', { upward = true, path = dir })[1]
    if git then
        local fork = vim.fs.dirname(git) .. '/' .. sub
        if vim.fn.executable(fork) == 1 then
            found = fork
        end
    end
    repo_dprint_cache[dir] = found
    return found or nil
end

conform.setup({
    formatters = {
        dprint = {
            command = function(_, ctx)
                return repo_dprint(ctx.filename) or 'dprint'
            end,
            args = function(_, ctx)
                if repo_dprint(ctx.filename) then
                    -- Let the fork discover the repo's dprint.json (see cwd below).
                    return { 'fmt', '--stdin', ctx.filename }
                end
                return {
                    'fmt',
                    '--config',
                    vim.fn.expand('~/.config/dprint/dprint.json'),
                    '--stdin',
                    ctx.filename,
                }
            end,
            stdin = true,
            -- Run from the directory holding dprint.json so config is discovered.
            cwd = require('conform.util').root_file({ 'dprint.json', 'dprint.jsonc', '.git' }),
        },
        shfmt = {
            -- 2-space indent and indented switch cases, per the Google shell
            -- style guide; -bn keeps `&&` and `||` at the start of a continued
            -- line, which is how these scripts already read. No -sr: redirects
            -- are written `2>/dev/null`, without the space.
            prepend_args = { '-i', '2', '-ci', '-bn' },
        },
        stylua = {
            prepend_args = { '--config-path', vim.fn.expand('~/.config/stylua/stylua.toml') },
        },
    },
    formatters_by_ft = {
        javascript = { 'dprint' },
        javascriptreact = { 'dprint' },
        typescript = { 'dprint' },
        typescriptreact = { 'dprint' },
        json = { 'dprint' },
        jsonc = { 'dprint' },
        markdown = { 'dprint' },
        lua = { 'stylua' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        rust = { 'rustfmt' },
    },
    -- CSS formatting stays with stylelint_lsp; see plugin/lsp.lua.
    -- Async (runs on BufWritePost) so saving never blocks on dprint's cold start.
    format_after_save = {
        lsp_format = 'never',
    },
})

-- Manual format
vim.keymap.set({ 'n', 'v' }, '<LocalLeader>m', function()
    require('conform').format({ async = true, lsp_format = 'never' })
end, { desc = 'Format buffer' })
