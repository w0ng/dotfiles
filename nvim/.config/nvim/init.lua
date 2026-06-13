-- Neovim configuration (single file).
-- Sections below: OPTIONS, KEYMAPS, PLUGINS, LSP.
-- Filetype-specific settings live in ftplugin/ and ftdetect/ (auto-loaded by
-- Neovim, so they stay as separate runtime files).

-- ============================================================================
-- OPTIONS
-- ============================================================================

--- General
-- Screen columns are are highlighted with ColorColumn (default '')
vim.opt.colorcolumn = { 100 }
-- Hide fold column in diff mode (default 'internal,filler,closeoff')
vim.opt.diffopt:append('foldcolumn:0')
-- Sets 'foldlevel' when starting to edit another buffer (default -1)
vim.opt.foldlevelstart = 99
-- Use treesitter for syntax-aware folding (default: 'manual')
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
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

-- Misc
-- Briefly highlight yanked text (native, replaces a plugin)
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Define <Leader> key (default nil)
vim.g.mapleader = ' '
-- Set <LocalLeader> key (default nil)
vim.g.maplocalleader = ' '

---@param mode string
---@param lhs string
---@param rhs string
local function noremap(mode, lhs, rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true })
end

-- Write file as superuser
noremap('c', 'w!!', 'w !sudo tee > /dev/null %')
-- Stop highlighting current 'hlsearch' results until next search
noremap('n', '<Leader>n', ':nohlsearch<CR>')
-- Switch ';' with ':'
noremap('n', ';', ':')
noremap('n', ':', ';')
noremap('v', ';', ':')
noremap('v', ':', ';')
-- Toggle options ([c]hange [o]ption [<key>])
noremap('n', 'com', ':set mouse=<C-R>=&mouse == "a" ? "" : "a"<CR><CR>')
noremap('n', 'con', ':set number!<CR>')
noremap('n', 'cos', ':set spell!<CR>')
noremap('n', 'cow', ':set wrap!<CR>')
-- Navigate next and previous commands starting with current input
noremap('c', '<C-n>', '<Down>')
noremap('c', '<C-p>', '<Up>')
-- Close the quickfix or location list window
noremap('n', '<Leader>l', ':cclose|lclose<CR>')
-- Clipboard: cut/copy/paste
noremap('v', '<Leader>x', '"+x')
noremap('v', '<Leader>c', '"+y')
noremap('n', '<Leader>v', '"+p')
noremap('v', '<Leader>v', '"+p')
noremap('n', '<Leader><S-v>', '"+P')
noremap('v', '<Leader><S-v>', '"+P')

-- Copy current file path to clipboard
noremap('n', '<Leader>c', ':let @+=expand("%:p")<CR>')

-- Clipboard: OSC 52 (works over SSH)
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- ============================================================================
-- PLUGINS
-- ============================================================================
-- Plugin management via native vim.pack (Neovim 0.12+). Each plugin's
-- vim.pack.add() sits next to its config; plugins install on first launch and
-- the lockfile lives at ~/.config/nvim/nvim-pack-lock.json (tracked in git).

-- Run plugin build hooks on install/update. Registered before any add() so it
-- fires on the very first install.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    -- fff.nvim ships a Rust binary that must be downloaded or built.
    if name == 'fff.nvim' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then
        vim.cmd.packadd('fff.nvim')
      end
      require('fff.download').download_or_build_binary()
    end
  end,
})

-- Expand a "user/repo" shorthand to a full GitHub URL for vim.pack.add().
local function gh(repo)
  return 'https://github.com/' .. repo
end

--------------------------------------------------------------------------------
-- gruvbox: dark colorscheme
--------------------------------------------------------------------------------
vim.pack.add({ gh('ellisonleao/gruvbox.nvim') })

local colors = require('gruvbox').palette

require('gruvbox').setup({
  bold = false,
  italic = {
    strings = false,
    emphasis = false,
    comments = false,
    operators = false,
    folds = false,
  },
  overrides = {
    -- Transparent SignColumn
    SignColumn = { bg = colors.dark0 },
    GruvboxRedSign = { fg = colors.neutral_red, bg = colors.dark0, reverse = false },
    GruvboxGreenSign = { fg = colors.neutral_green, bg = colors.dark0, reverse = false },
    GruvboxYellowSign = { fg = colors.neutral_yellow, bg = colors.dark0, reverse = false },
    GruvboxBlueSign = { fg = colors.neutral_blue, bg = colors.dark0, reverse = false },
    GruvboxPurpleSign = { fg = colors.neutral_purple, bg = colors.dark0, reverse = false },
    GruvboxAquaSign = { fg = colors.neutral_aqua, bg = colors.dark0, reverse = false },
    GruvboxOrangeSign = { fg = colors.neutral_orange, bg = colors.dark0, reverse = false },

    -- Darker StatusLine
    StatusLine = { fg = colors.dark0_hard, bg = colors.bright_yellow, reverse = true },
    StatusLineNC = { fg = colors.dark0_hard, bg = colors.light4, reverse = true },

    -- Darker LSP popup menu
    Pmenu = { fg = colors.light1, bg = colors.dark0_soft },
    PmenuSel = { fg = colors.dark0_soft, bg = colors.bright_blue },
    PmenuSbar = { bg = colors.dark2 },
    PmenuThumb = { bg = colors.dark3 },
    FloatBorder = { fg = colors.dark3, bg = colors.dark0_soft },
    QuickFixLine = { fg = colors.bright_yellow, bg = 'none' },
  },
})

-- Set colorscheme, make statusline and pop-up menu darker
vim.cmd.colorscheme('gruvbox')

--------------------------------------------------------------------------------
-- gitsigns.nvim: git decorators for modified lines
--------------------------------------------------------------------------------
vim.pack.add({ gh('lewis6991/gitsigns.nvim') })

require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')
    -- Toggle git-blame sidebar
    vim.keymap.set('n', '<leader>g', function()
      gitsigns.blame_line({ full = true })
    end)
    vim.keymap.set('n', '<leader>G', function()
      gitsigns.blame({ ignore_whitespace = true })
    end)
  end,
})

--------------------------------------------------------------------------------
-- noice.nvim: UI replacement for messages, cmdline, and popupmenu
-- (+ nui.nvim for rendering, + nvim-notify for the notification view)
--------------------------------------------------------------------------------
vim.pack.add({
  gh('folke/noice.nvim'),
  gh('MunifTanjim/nui.nvim'),
  gh('rcarriga/nvim-notify'),
})

require('noice').setup({
  lsp = {
    -- override markdown rendering so that hover/docs use Treesitter
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
    },
  },
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
  messages = {
    view_search = false, -- disable search_count messages
  },
})

--------------------------------------------------------------------------------
-- lualine.nvim: configurable statusline (+ web-devicons)
--------------------------------------------------------------------------------
vim.pack.add({ gh('nvim-lualine/lualine.nvim'), gh('nvim-tree/nvim-web-devicons') })

local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed,
    }
  end
end

require('lualine').setup({
  options = {
    theme = 'gruvbox-material',
    section_separators = '',
    component_separators = '',
  },
  sections = {
    lualine_a = {
      {
        'mode',
        color = { gui = '' },
        fmt = function(str)
          if str == 'INSERT' or str == 'REPLACE' then
            return ''
          end
          return ''
        end,
      },
    },
    lualine_b = {
      { 'b:gitsigns_head', icon = '' },
      { 'diff', source = diff_source },
      -- https://github.com/nvim-lualine/lualine.nvim/issues/1355
      {
        'macro',
        fmt = function()
          local reg = vim.fn.reg_recording()
          if reg ~= '' then
            return 'Recording @' .. reg
          end
          return nil
        end,
        draw_empty = false,
      },
    },
    lualine_c = {
      '%=',
      { 'filename', path = 1, color = { fg = '#fabd2f', gui = '' } },
    },
    lualine_x = {},
    lualine_y = {
      { 'diagnostics', color = { gui = '' } },
    },
    lualine_z = {
      { 'location', color = { gui = '' } },
    },
  },
})

--------------------------------------------------------------------------------
-- incline.nvim: floating per-window statusline
--------------------------------------------------------------------------------
vim.pack.add({ gh('b0o/incline.nvim') })

require('incline').setup({
  -- Hide floating statusline on focused window if on same line as cursor
  hide = {
    cursorline = 'focused_win',
  },
  -- Override highlight groups to match bottom statusline
  highlight = {
    groups = {
      InclineNormal = 'StatusLine',
      InclineNormalNC = 'StatusLineNC',
    },
  },
})

--------------------------------------------------------------------------------
-- nvim-treesitter (main): parser/highlight, text objects, JSX commentstring
--------------------------------------------------------------------------------
vim.pack.add({
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'main' },
  gh('JoosepAlviste/nvim-ts-context-commentstring'),
})

require('nvim-treesitter').setup({})

require('nvim-treesitter').install({
  'bash',
  'css',
  'graphql',
  'html',
  'java',
  'javascript',
  'json',
  'lua',
  'markdown',
  'markdown_inline',
  'regex',
  'tsx',
  'typescript',
  'vim',
  'yaml',
})

-- Enable treesitter highlighting for all filetypes
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

require('nvim-treesitter-textobjects').setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

-- Select textobjects
vim.keymap.set({ 'x', 'o' }, 'af', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'if', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ac', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ic', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
end)

-- Move textobjects
vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
  require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
  require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, ']M', function()
  require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '][', function()
  require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
  require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
  require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[M', function()
  require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[]', function()
  require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
end)

-- nvim-ts-context-commentstring: pick the right commentstring for embedded
-- languages (e.g. JSX) so the native `gc` operator comments them correctly.
require('ts_context_commentstring').setup({ enable_autocmd = false })
vim.g.skip_ts_context_commentstring_module = true
local get_option = vim.filetype.get_option
vim.filetype.get_option = function(filetype, option)
  return option == 'commentstring'
      and require('ts_context_commentstring.internal').calculate_commentstring()
      or get_option(filetype, option)
end

--------------------------------------------------------------------------------
-- blink.cmp: completion engine (replaces nvim-cmp + sources + lspkind)
--------------------------------------------------------------------------------
vim.pack.add({ { src = gh('Saghen/blink.cmp'), version = vim.version.range('1') } })

require('blink.cmp').setup({
  -- Preserve the previous nvim-cmp keymaps.
  keymap = {
    preset = 'none',
    ['<CR>'] = { 'accept', 'fallback' },
    ['<Tab>'] = { 'select_next', 'fallback' },
    ['<S-Tab>'] = { 'select_prev', 'fallback' },
    ['<C-Space>'] = { 'show', 'fallback' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<C-d>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  },
  appearance = {
    -- Nerd-font icons in the completion menu (matches the old lspkind setup)
    nerd_font_variant = 'mono',
  },
  sources = {
    default = { 'lsp', 'path', 'buffer' },
  },
  completion = {
    menu = {
      border = 'rounded',
      draw = { columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } } },
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

--------------------------------------------------------------------------------
-- nvim-bqf: better quickfix windows
--------------------------------------------------------------------------------
vim.pack.add({ gh('kevinhwang91/nvim-bqf') })

require('bqf').setup({
  preview = {
    win_height = 10,
    win_vheight = 10,
  },
  func_map = {
    open = 'o',
    openc = '<CR>',
  },
})

--------------------------------------------------------------------------------
-- nvim-tree.lua: file explorer sidebar
--------------------------------------------------------------------------------
vim.pack.add({ gh('nvim-tree/nvim-tree.lua') })

require('nvim-tree').setup({
  actions = {
    open_file = {
      window_picker = {
        -- disable window picker when multiple splits open (default true)
        enable = false,
      },
    },
  },
  git = {
    enable = false,
  },
  renderer = {
    -- append a trailing slash to folder names (default false)
    add_trailing = true,
  },
  view = {
    -- increase sidebar width (default: 30)
    width = 51,
  },
})

-- folder name color blue when gruvbox colortheme installed
vim.api.nvim_set_hl(0, 'NvimTreeFolderName', { link = 'Identifier' })
vim.api.nvim_set_hl(0, 'NvimTreeEmptyFolderName', { link = 'Identifier' })
vim.api.nvim_set_hl(0, 'NvimTreeOpenedFolderName', { link = 'Identifier' })

-- toggle tree
noremap('n', '<Leader>t', ':NvimTreeToggle<CR>')
-- toggle tree with current file highlighted
noremap('n', '<Leader>T', ':NvimTreeFindFile<CR>')

--------------------------------------------------------------------------------
-- conform.nvim: single formatting path (dprint + stylua, format on save)
--------------------------------------------------------------------------------
vim.pack.add({ gh('stevearc/conform.nvim') })

local conform = require('conform')

-- Inside any checkout that vendors its own dprint (main repo OR a git worktree,
-- wherever it lives), format with THAT checkout's dprint so output matches the
-- repo's config; elsewhere fall back to system dprint + personal config.
-- Detected by walking up to the repo root and checking for tools/dprint/dprint
-- — no hardcoded path.
local function repo_dprint(filename)
  if type(filename) ~= 'string' then return nil end
  local git = vim.fs.find('.git', { upward = true, path = vim.fs.dirname(filename) })[1]
  if not git then return nil end
  local fork = vim.fs.dirname(git) .. '/tools/dprint/dprint'
  return vim.fn.executable(fork) == 1 and fork or nil
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
        return { 'fmt', '--config', vim.fn.expand('~/.config/dprint/dprint.json'), '--stdin', ctx.filename }
      end,
      stdin = true,
      -- Run from the directory holding dprint.json so config is discovered.
      cwd = require('conform.util').root_file({ 'dprint.json', 'dprint.jsonc', '.git' }),
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
  },
  -- CSS formatting stays with stylelint_lsp (see the LSP section below).
  -- Async (runs on BufWritePost) so saving never blocks on dprint's cold start.
  format_after_save = {
    lsp_format = 'never',
  },
})

-- Manual format (was <Leader>af :Format under formatter.nvim).
vim.keymap.set({ 'n', 'v' }, '<LocalLeader>m', function()
  require('conform').format({ async = true, lsp_format = 'never' })
end, { desc = 'Format buffer' })

--------------------------------------------------------------------------------
-- nvim-colorizer.lua (maintained fork): highlight color codes
--------------------------------------------------------------------------------
vim.pack.add({ gh('catgoose/nvim-colorizer.lua') })

require('colorizer').setup()

--------------------------------------------------------------------------------
-- snacks.nvim: utility library; here used for the buffer picker (replaces fzf.vim)
--------------------------------------------------------------------------------
vim.pack.add({ gh('folke/snacks.nvim') })

require('snacks').setup({
  picker = {
    enabled = true,
    -- fzf/fff style: input line at the bottom, list above growing upward
    -- (reverse), and no preview window.
    layout = {
      reverse = true,
      preview = false,
      layout = {
        box = 'vertical',
        width = 0.6,
        height = 0.6,
        border = 'rounded',
        { win = 'list', border = 'none' },
        { win = 'input', height = 1, border = 'top', title = '{title} {live} {flags}', title_pos = 'center' },
      },
    },
    -- Stay insert-only (no vim/normal mode): <Esc> closes the picker.
    win = {
      input = {
        keys = {
          ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
        },
      },
    },
  },
})
vim.keymap.set('n', '<Leader>b', function() require('snacks').picker.buffers() end, { desc = 'Buffers' })

--------------------------------------------------------------------------------
-- fff.nvim: fast file finder (needs a binary; see PackChanged hook at top)
--------------------------------------------------------------------------------
vim.pack.add({ gh('dmtrKovalenko/fff.nvim') })

require('fff').setup({
  prompt_vim_mode = false,
  preview = {
    enabled = false,
  },
})
vim.keymap.set('n', '<Leader>p', function() require('fff').find_files() end, { desc = 'Find files' })
vim.keymap.set('n', '<Leader>f', function() require('fff').live_grep() end, { desc = 'Live grep' })
vim.keymap.set('n', '<Leader>s', function() require('fff').live_grep({ query = vim.fn.expand('<cword>') }) end, { desc = 'Grep current word' })

--------------------------------------------------------------------------------
-- nvim-surround: add/change/delete surrounding pairs (replaces vim-surround;
-- same ys/cs/ds mappings, with built-in dot-repeat so vim-repeat isn't needed)
--------------------------------------------------------------------------------
vim.pack.add({ gh('kylechui/nvim-surround') })

require('nvim-surround').setup({})

--------------------------------------------------------------------------------
-- vim-obsession: session files (pairs with tmux-resurrect)
--------------------------------------------------------------------------------
vim.pack.add({ gh('tpope/vim-obsession') })

--------------------------------------------------------------------------------
-- vim-tmux-navigator: seamless split navigation between vim and tmux
--------------------------------------------------------------------------------
vim.pack.add({ gh('christoomey/vim-tmux-navigator') })

vim.g.tmux_navigator_no_wrap = 1

-- ============================================================================
-- LSP
-- ============================================================================
-- nvim-lspconfig: per-server config DATA read by vim.lsp.enable().
-- lazydev.nvim: lua_ls completion for the Neovim API (replaces neodev.nvim).
vim.pack.add({ gh('neovim/nvim-lspconfig'), gh('folke/lazydev.nvim') })

-- Configure diagnostic options globally
vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = 'rounded',
    severity_sort = true,
    source = true,
  },
  -- Replace sign column diagnostic letters with nerdfonts icons
  -- (default { Error = 'E', Warning = 'W', Hint = 'H', Information = 'I' })
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = ' ',
      [vim.diagnostic.severity.WARN] = ' ',
      [vim.diagnostic.severity.INFO] = ' ',
      [vim.diagnostic.severity.HINT] = ' ',
    },
  },
})

-- Always show sign column
vim.opt.signcolumn = 'yes'

-- Diagnostic mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<LocalLeader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<LocalLeader>l', ':LspEslintFixAll<CR>', opts)
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)

-- Buffer-local LSP keymaps on every attach.
-- A single LspAttach autocmd (rather than a per-server on_attach) guarantees
-- these apply to every server, including ones that set their own on_attach
-- (lua_ls, tsgo) which would otherwise override a global on_attach.
-- Native defaults already provide grn/gra/grr/gri/grt/K/<C-S>, so we only add
-- the maps with no native equivalent.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', '<LocalLeader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<LocalLeader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<LocalLeader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<LocalLeader>q', vim.diagnostic.setloclist, bufopts)
  end,
})

-- Completion capabilities from blink.cmp
local capabilities = require('blink.cmp').get_lsp_capabilities()

-- Extend default config for all servers
vim.lsp.config('*', {
  flags = {
    debounce_text_changes = 150,
  },
  capabilities = capabilities,
  root_markers = { 'shell.nix' },
})

-- Extend individual servers
-- (extends https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md)

-- npm i -g vscode-langservers-extracted
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

-- npm i -g cssmodules-language-server
vim.lsp.config('cssmodules_ls', {})
vim.lsp.enable('cssmodules_ls')

-- npm i -g vscode-langservers-extracted
vim.lsp.config('eslint', {
  settings = {
    -- Disable formatting with eslint. Use dprint via conform instead.
    format = false,
  },
})
vim.lsp.enable('eslint')

-- npm i -g vscode-langservers-extracted
vim.lsp.config('html', {})
vim.lsp.enable('html')

-- npm i -g vscode-langservers-extracted
vim.lsp.config('jsonls', {
  filetypes = { 'json', 'jsonc' },
  init_options = {
    provideFormatter = false,
  },
})
vim.lsp.enable('jsonls')

-- npm i -g stylelint-lsp
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

-- lazydev.nvim: lua_ls completion for the Neovim API when editing this config.
require('lazydev').setup()

-- brew install lua-language-server
vim.lsp.config('lua_ls', {
  on_attach = function(client)
    -- Disable formatting with lua_ls. Use stylua via conform instead.
    client.server_capabilities.documentFormattingProvider = false
  end,
})
vim.lsp.enable('lua_ls')

-- npm i -g @typescript/native-preview
vim.lsp.config('tsgo', {
  on_attach = function(client)
    -- Disable formatting with tsgo. Use dprint via conform instead.
    client.server_capabilities.documentFormattingProvider = false
  end,
})
vim.lsp.enable('tsgo')
