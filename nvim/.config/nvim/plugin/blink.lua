-- blink.cmp: completion engine
--------------------------------------------------------------------------------
vim.pack.add({ { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1') } })

require('blink.cmp').setup({
    -- <Tab> accepts the highlighted item, or advances a placeholder while a
    -- snippet is active. <CR> is deliberately unbound, so Enter is always a
    -- newline. Navigation is <C-n>/<C-p>.
    keymap = {
        preset = 'super-tab',
    },
    appearance = {
        -- Nerd Font icons in the completion menu.
        nerd_font_variant = 'mono',
    },
    sources = {
        default = { 'lsp', 'path', 'buffer' },
    },
    completion = {
        menu = {
            border = 'rounded',
            draw = {
                columns = {
                    { 'kind_icon' },
                    { 'label', 'label_description', gap = 1 },
                    { 'source_name' },
                },
            },
        },
        documentation = {
            auto_show = true,
            window = { border = 'rounded' },
        },
    },
    signature = {
        enabled = true,
        window = { border = 'rounded' },
    },
    -- Prefer the prebuilt Rust matcher (downloaded for the pinned release tag);
    -- fall back to the Lua implementation if it is unavailable.
    fuzzy = {
        implementation = 'prefer_rust_with_warning',
    },
})

-- Advertise blink's completion capabilities to every language server. The
-- servers themselves are configured in plugin/lsp.lua, which nvim sources after
-- this file. That is harmless, because vim.lsp.config('*') merges across calls
-- and nothing resolves a config until a client actually starts.
vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
})
