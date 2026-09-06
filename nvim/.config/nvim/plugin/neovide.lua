-- Neovide GUI settings. Not a plugin -- it lives in plugin/ only because that
-- is sourced after init.lua, like everything else here.
--------------------------------------------------------------------------------
-- Mirrors the terminal setup (ghostty/.config/ghostty/config) so the GUI matches
-- nvim running inside ghostty; each value below cites the ghostty option it
-- tracks.
--
-- Fonts are deliberately *not* set here: 'guifont' only accepts a family plus a
-- size, and macOS reports all 16 Maple Mono faces under the single family
-- 'Maple Mono NF CN', so the Medium/ExtraBold styles are only reachable from
-- neovide/.config/neovide/config.toml, which takes a family *and* a style per
-- slot. Setting 'guifont' here would override that file and silently fall back
-- to the Regular weight.

if vim.g.neovide then
    -- ghostty: cursor-color = #fe8019 / cursor-text = #282828. gruvbox leaves
    -- Cursor as plain reverse, so redefine it - but 'guicursor' has to name
    -- it too: Neovim's default guicursor gives no mode a highlight-group at
    -- all (only 't', terminal mode, references TermCursor), so without this
    -- the highlight below is defined but never actually used (:h guicursor).
    vim.api.nvim_set_hl(0, 'Cursor', { fg = '#282828', bg = '#fe8019' })

    -- ghostty: cursor-style-blink = false. The 'a' pseudo-mode merges into
    -- every mode's argument-list without resetting the rest of it, so this
    -- both kills blink and wires up the Cursor highlight above everywhere.
    vim.opt.guicursor:append('a:blinkon0-Cursor/lCursor')

    -- Hide the pointer while typing, as the terminal does.
    vim.g.neovide_hide_mouse_when_typing = true

    -- ghostty: custom-shader = shaders/cursor_tail.glsl. Neovide's cursor
    -- animation defaults (0.150s / 1.0 trail) smear more than that shader;
    -- tighten them to match its snappier comet-trail feel.
    vim.g.neovide_cursor_animation_length = 0.09
    vim.g.neovide_cursor_trail_size = 0.3

    -- <C-u>/<C-d>/<C-f>/<C-b> etc. felt sluggish at the 0.3s default; snap
    -- the viewport instantly instead, matching terminal nvim.
    vim.g.neovide_scroll_animation_length = 0

    -- ghostty binds Cmd+=/Cmd+-/Cmd+0 to zoom natively; Neovide has no
    -- built-in equivalent, so drive its scale factor ourselves.
    -- https://neovide.dev/faq.html#how-can-i-dynamically-change-the-scale-at-runtime
    vim.g.neovide_scale_factor = 1.0
    local function change_scale_factor(delta)
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
    end
    vim.keymap.set('n', '<D-=>', function()
        change_scale_factor(1.25)
    end, { desc = 'Zoom in' })
    vim.keymap.set('n', '<D-->', function()
        change_scale_factor(1 / 1.25)
    end, { desc = 'Zoom out' })
    vim.keymap.set('n', '<D-0>', function()
        vim.g.neovide_scale_factor = 1.0
    end, { desc = 'Reset zoom' })

    -- ghostty: theme = Gruvbox Dark plus the palette 0/8 overrides. Inside
    -- ghostty the terminal emulator supplies these to :terminal buffers; under
    -- Neovide nothing does, so restate the palette.
    vim.g.terminal_color_0 = '#1d2021'
    vim.g.terminal_color_1 = '#cc241d'
    vim.g.terminal_color_2 = '#98971a'
    vim.g.terminal_color_3 = '#d79921'
    vim.g.terminal_color_4 = '#458588'
    vim.g.terminal_color_5 = '#b16286'
    vim.g.terminal_color_6 = '#689d6a'
    vim.g.terminal_color_7 = '#a89984'
    vim.g.terminal_color_8 = '#3c3836'
    vim.g.terminal_color_9 = '#fb4934'
    vim.g.terminal_color_10 = '#b8bb26'
    vim.g.terminal_color_11 = '#fabd2f'
    vim.g.terminal_color_12 = '#83a598'
    vim.g.terminal_color_13 = '#d3869b'
    vim.g.terminal_color_14 = '#8ec07c'
    vim.g.terminal_color_15 = '#ebdbb2'

    -- ghostty intercepts the macOS clipboard shortcuts itself. Neovide registers a
    -- clipboard *provider* (so "+y and "+p work) but binds no keys, so ⌘c/⌘v/⌘x
    -- are dead in the GUI without these.
    vim.keymap.set({ 'n', 'v' }, '<D-v>', '"+p', { desc = 'Paste from system clipboard' })
    vim.keymap.set('i', '<D-v>', '<C-r><C-o>+', { desc = 'Paste from system clipboard' })
    vim.keymap.set('c', '<D-v>', '<C-r>+', { desc = 'Paste from system clipboard' })
    vim.keymap.set('t', '<D-v>', function()
        local chan = vim.b.terminal_job_id
        if chan then
            vim.api.nvim_chan_send(chan, vim.fn.getreg('+'))
        end
    end, { desc = 'Paste from system clipboard' })
    vim.keymap.set('v', '<D-c>', '"+y', { desc = 'Copy to system clipboard' })
    vim.keymap.set('v', '<D-x>', '"+d', { desc = 'Cut to system clipboard' })
    vim.keymap.set('n', '<D-a>', 'ggVG', { desc = 'Select all' })
end
