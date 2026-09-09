-- nvim-lspconfig: per-server config DATA, meaning cmd, filetypes and root
-- markers, which vim.lsp.enable() reads off the runtimepath. The servers
-- themselves are configured below with the built-in vim.lsp.config/enable
-- (0.11+).
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' })

-- Extend individual servers
-- (extends https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md)
--
-- Every binary here is declared in bootstrap.sh, under mod_neovim or
-- mod_runtimes. A server that will not start is usually one whose module has
-- not been run.
--
-- conform.lua owns formatting, so each server that offers its own has
-- documentFormattingProvider switched off below. Two formatters racing over one
-- buffer is the failure this avoids.

-- Brings no linter of its own: diagnostics are shellcheck, which the server
-- shells out to whenever it is on PATH.
vim.lsp.config('bashls', {
    on_attach = function(client)
        -- bashls drives shfmt with its own defaults, which would retab these
        -- files.
        client.server_capabilities.documentFormattingProvider = false
    end,
})
vim.lsp.enable('bashls')

-- buf_ls ships inside the buf CLI (`buf lsp serve`), installed by bootstrap.sh.
-- It reads buf.yaml workspaces/modules, so go-to-definition and references work
-- across .proto files.
--
-- Resolved to an absolute path rather than trusting $PATH. A project that
-- vendors its own buf can place it earlier on PATH, and a build predating
-- `lsp serve` makes the server fail to start. Prefer a hand-placed
-- ~/.local/bin/buf, then Homebrew's.
local function buf_bin()
    for _, candidate in ipairs({ '~/.local/bin/buf', '/opt/homebrew/bin/buf', '/usr/local/bin/buf' }) do
        local abs = vim.fn.expand(candidate)
        if vim.fn.executable(abs) == 1 then
            return abs
        end
    end
    return 'buf'
end

vim.lsp.config('buf_ls', {
    cmd = { buf_bin(), 'lsp', 'serve', '--log-format=text' },
})
vim.lsp.enable('buf_ls')

vim.lsp.config('cssls', {
    settings = {
        css = {
            validate = true,
            lint = {
                unknownAtRules = 'ignore',
                unknownProperties = 'ignore',
            },
        },
    },
})
vim.lsp.enable('cssls')

vim.lsp.config('cssmodules_ls', {})
vim.lsp.enable('cssmodules_ls')

vim.lsp.config('eslint', {
    settings = {
        format = false,
    },
})
vim.lsp.enable('eslint')

vim.lsp.config('html', {})
vim.lsp.enable('html')

vim.lsp.config('jsonls', {
    filetypes = { 'json', 'jsonc' },
    init_options = {
        provideFormatter = false,
    },
})
vim.lsp.enable('jsonls')

vim.lsp.config('stylelint_lsp', {
    settings = {
        stylelintplus = {
            autoFixOnFormat = true,
            autoFixOnSave = true,
        },
    },
    filetypes = {
        'css',
    },
})
vim.lsp.enable('stylelint_lsp')

vim.lsp.config('lua_ls', {
    on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
    end,
})
vim.lsp.enable('lua_ls')

-- Not part of rustup's default profile, unlike rustfmt and clippy, so
-- mod_runtimes adds it explicitly.
vim.lsp.config('rust_analyzer', {
    on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
    end,
})
vim.lsp.enable('rust_analyzer')

-- Only the native compiler (TypeScript 7+) speaks `--lsp`, so the server skips a
-- repo's vendored 5.x `node_modules/.bin/tsc` and falls through to the global one.
vim.lsp.config('tsc', {
    on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
    end,
})
vim.lsp.enable('tsc')

-- ============================================================================
-- DIAGNOSTICS AND KEYMAPS
-- ============================================================================

-- Diagnostics are core nvim, not LSP-specific, but every producer here is a
-- language server, and <LocalLeader>l below is an nvim-lspconfig command.
vim.diagnostic.config({
    virtual_text = false,
    float = {
        border = 'rounded',
        severity_sort = true,
        source = true,
    },
    -- Nerd Font glyphs in the sign column instead of the default E/W/H/I.
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '󰅙 ',
            [vim.diagnostic.severity.WARN] = '󰀦 ',
            [vim.diagnostic.severity.INFO] = '󰋼 ',
            [vim.diagnostic.severity.HINT] = '󰌵 ',
        },
    },
})

vim.opt.signcolumn = 'yes'

vim.keymap.set('n', '<LocalLeader>e', vim.diagnostic.open_float, {
    silent = true,
    desc = 'Show diagnostics under cursor',
})
vim.keymap.set('n', '<LocalLeader>l', '<Cmd>LspEslintFixAll<CR>', {
    silent = true,
    desc = 'eslint: fix all in buffer',
})

-- Buffer-local LSP keymaps on every attach.
-- A single LspAttach autocmd (rather than a per-server on_attach) guarantees
-- these apply to every server, including ones that set their own on_attach
-- (lua_ls, tsc) which would otherwise override a global on_attach.
-- Native defaults already provide grn/gra/grr/gri/grt/K/<C-S>, so we only add
-- the maps with no native equivalent.
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {
            buffer = args.buf,
            silent = true,
            desc = 'Go to definition',
        })
        vim.keymap.set('n', '<LocalLeader>q', vim.diagnostic.setloclist, {
            buffer = args.buf,
            silent = true,
            desc = 'Diagnostics to location list',
        })
    end,
})

-- ============================================================================
-- LSP ACTIVITY
-- ============================================================================
-- Registers a source with lua/async_activity.lua. Nothing here touches the
-- statusline plugin directly, since plugin/lualine.lua supplies the redraw
-- hook, so this file depends only on what it declares above. The spinner shows
-- while a server attached to the current buffer is working. Two signals are
-- needed, because servers differ in what they report:
--   * $/progress: rust-analyzer, gopls and tsserver announce indexing.
--   * no tokens yet: buf_ls announces no progress at all. A semantic-token
--     server that has not sent its first batch is still indexing, and gd will
--     not resolve until it has.
-- A uv timer drives the redraw so the spinner animates; requests are async, so
-- the editor stays free to redraw during the wait.

-- A server advertising semanticTokensProvider is still indexing until its first
-- token lands: that batch is what recolours identifiers, and the same index
-- answers gd. LspTokenUpdate fires once per token, so the guard makes all but
-- the first a table lookup.
local lsp_tokens_seen = {}

vim.api.nvim_create_autocmd('LspTokenUpdate', {
    callback = function(ev)
        local seen = lsp_tokens_seen[ev.buf] or {}
        if not seen[ev.data.client_id] then
            seen[ev.data.client_id] = true
            lsp_tokens_seen[ev.buf] = seen
            require('async_activity').refresh()
        end
    end,
})

vim.api.nvim_create_autocmd({ 'LspDetach', 'BufDelete' }, {
    callback = function(ev)
        lsp_tokens_seen[ev.buf] = nil
    end,
})

-- Unfinished $/progress sequences are tracked by nvim itself, in
-- client.progress.pending. All this adds is which clients use $/progress at
-- all, which nothing built-in exposes: pending reads empty both for a server
-- that has finished and one that never reports, and the fallback below has to
-- tell those apart.
local lsp_uses_progress = {}
vim.api.nvim_create_autocmd('LspProgress', {
    callback = function(args)
        lsp_uses_progress[args.data.client_id] = true
    end,
})

-- Names of clients on the current buffer that are busy, else nil.
local function lsp_activity()
    local buf = vim.api.nvim_get_current_buf()
    local parts = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        -- 1) an active $/progress for this client, or
        -- 2) still indexing, only for servers that have never reported
        --    progress, since one that announces its work is the better signal
        --    and this would just duplicate it between messages.
        local busy = next(client.progress.pending) ~= nil
            or (
                not lsp_uses_progress[client.id]
                and (client.server_capabilities or {}).semanticTokensProvider ~= nil
                and not (lsp_tokens_seen[buf] or {})[client.id]
            )
        if busy then
            parts[#parts + 1] = client.name .. '...'
        end
    end
    return #parts > 0 and table.concat(parts, '  ') or nil
end

require('async_activity').register(lsp_activity)

vim.api.nvim_create_autocmd({ 'LspProgress', 'LspRequest', 'LspAttach' }, {
    callback = require('async_activity').poke,
})
