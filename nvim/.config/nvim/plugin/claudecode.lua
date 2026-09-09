-- claudecode.nvim: connect an external Claude Code CLI to this nvim (IDE protocol)
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/coder/claudecode.nvim' })

-- You launch Claude at the project root, but nvim often starts deeper, because
-- :cd into a subdirectory scopes fff and grep to it. claudecode derives both its
-- lock file and its @-mention paths from nvim's cwd, so with claude at foo/ and
-- nvim at foo/bar/baz/ the IDE reads as unavailable in /ide, and a file there
-- sends as @x.ts, which Claude resolves against the wrong directory. Both
-- overrides below rebase on the repo root instead. They patch plugin internals,
-- so an upstream rename disables them silently rather than raising.
local function repo_root()
    local git = vim.fs.find('.git', { upward = true, path = vim.fn.getcwd() })[1]
    return (git and vim.fs.dirname(git) or vim.fn.getcwd()) .. '/'
end

-- (1) Advertise the repo root in the lock file so /ide matches. Must precede
-- setup(): the lock is written once on auto_start, not refreshed on :cd.
local claudecode_lockfile = require('claudecode.lockfile')
local default_get_workspace_folders = claudecode_lockfile.get_workspace_folders
function claudecode_lockfile.get_workspace_folders()
    local folders = default_get_workspace_folders()
    table.insert(folders, 1, repo_root():sub(1, -2)) -- drop trailing slash
    return folders
end

-- (2) Render @-mentions relative to the repo root: with nvim at foo/bar/baz/,
-- the file x.ts sends as @bar/baz/x.ts rather than @x.ts.
-- fnamemodify(':p') absolutizes ClaudeCodeAdd's relative `%`; send already
-- passes an absolute path. Every send/add path funnels through this formatter.
local claudecode = require('claudecode')
function claudecode._format_path_for_at_mention(path)
    local abs, root = vim.fn.fnamemodify(path, ':p'), repo_root()
    local is_dir = vim.fn.isdirectory(abs) == 1
    local rel = abs:sub(1, #root) == root and abs:sub(#root + 1) or abs
    if rel == '' then
        rel = './'
    end
    if is_dir and not rel:match('/$') then
        rel = rel .. '/'
    end
    return rel, is_dir
end

claudecode.setup({
    -- Don't spawn Claude inside nvim. Claude runs in a separate terminal pane
    -- and connects via /ide; nvim only runs the WebSocket/MCP server, which
    -- auto_start (on by default) brings up.
    terminal = { provider = 'none' },
})

-- Focus the Claude pane connected to this nvim so a send lands me in its prompt
-- ready to type. Scoped to nvim's own herdr tab ($HERDR_TAB_ID, which is
-- workspace-namespaced), so it picks the Claude pane in *this* tab and never
-- jumps to a Claude in another tab or workspace. nvim isn't a detected agent, so
-- the only claude in the tab is the connected one. Fully async (no UI block);
-- a no-op if herdr isn't running or there's no Claude alongside this tab.
local function focus_claude()
    local tab = vim.env.HERDR_TAB_ID
    if not tab then
        return
    end
    vim.system({ 'herdr', 'agent', 'list' }, { text = true }, function(res)
        if res.code ~= 0 then
            return
        end
        local ok, data = pcall(vim.json.decode, res.stdout)
        if not ok then
            return
        end
        for _, a in ipairs((data.result or {}).agents or {}) do
            if a.tab_id == tab and a.agent == 'claude' then
                vim.system({ 'herdr', 'agent', 'focus', a.pane_id })
                return
            end
        end
    end)
end

vim.keymap.set('v', '<Leader>as', function()
    -- Leave visual mode synchronously ('x') so '< / '> reflect the selection
    -- before ClaudeCodeSend reads the range from those marks.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    vim.cmd("'<,'>ClaudeCodeSend")
    focus_claude()
end, { desc = 'Claude: send selection + focus' })
vim.keymap.set('n', '<Leader>ab', function()
    vim.cmd('ClaudeCodeAdd %')
    focus_claude()
end, { desc = 'Claude: add buffer + focus' })
