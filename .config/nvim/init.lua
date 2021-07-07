--------------------------------------------------------------------------------
-- Options: General
--------------------------------------------------------------------------------
-- Screen columns are are highlighted with ColorColumn (default '')
vim.opt.colorcolumn:append('100')
-- Options for Insert mode completion (default 'menu,preview')
vim.opt.completeopt:remove('preview')
-- Hide fold column in diff mode (default 'internal,filler,closeoff')
vim.opt.diffopt:append('foldcolumn:0')
-- When foldmethod = 'indent', lines starting with ignore get fold level from
-- surrounding lines (default '#')
vim.opt.foldignore = ''
-- Sets 'foldlevel' when starting to edit another buffer (default -1)
vim.opt.foldlevelstart = 99
-- The kind of folding used for the current window (default: 'manual')
vim.opt.foldmethod = 'indent'
-- Enables hiding a buffer instead of discarding buffer on unload (default off)
vim.opt.hidden = true
-- Enables mouse support (default '')
vim.opt.mouse = 'a'
-- Show cursor line number (default off)
vim.opt.number = true
-- When a bracket is inserted, briefly jump to the matching one (default off)
vim.opt.showmatch = true
-- Show Insert, Replace, or Visual message on the last line (default on)
vim.opt.showmode = false
-- Enables 24-bit RGB color in the TUI (default off)
vim.opt.termguicolors = true
-- Set title of the find to 'filename [+=-] (path) - NVIM' (default off)
vim.opt.title = true
-- Sets text wrap (default on)
vim.opt.wrap = false

--------------------------------------------------------------------------------
-- Options: Tabs and indents
--------------------------------------------------------------------------------
-- See ~/.vim/config/ftplugin for filetype-specific overrides
-- Number of spaces to insert a <Tab> in insert mode
vim.opt.expandtab = true
-- Number of spaces to use for each (auto)indent step (default 8)
vim.opt.shiftwidth = 2
-- Number of spaces that a <Tab> and <BS> counts during editing (default 0)
vim.opt.softtabstop = 2
-- Number of spaces that a <Tab> in the file counts for (default 8)
vim.opt.tabstop = 2

--------------------------------------------------------------------------------
-- Options: Search
--------------------------------------------------------------------------------
-- Ignore case in search patterns (default off)
vim.opt.ignorecase = true
-- Override 'ignorecase' if the search pattern contains upper case (default off)
vim.opt.smartcase = true
-- Use ripgrep for grep command if installed (default 'grep -n ')
if vim.fn.executable('rg') then
  vim.opt.grepprg = 'rg --no-heading --vimgrep'
end

--------------------------------------------------------------------------------
-- Keymapping
--------------------------------------------------------------------------------
-- Define <Leader> key (default nil)
vim.g.mapleader = ','
-- Set <LocalLeader> key (default nil)
vim.g.maplocalleader = ','

local function noremap(mapmode, lhs, rhs)
  vim.api.nvim_set_keymap(mapmode, lhs, rhs, { noremap = true })
end

-- Map 'jj' to Escape key
noremap('i', 'jj', '<Esc>')
-- Write file as superuser
noremap('c', 'w!!', 'w !sudo tee > /dev/null %')
-- Stop highlighting current 'hlsearch' results until next search
noremap('n', '<Space>', ':nohlsearch<CR>')
-- Switch ';' with ':'
noremap('n', ';', ':')
noremap('n', ':', ';')
noremap('v', ';', ':')
noremap('v', ':', ';')
-- Toggle options ([c]hange [o]ption [<key>])
noremap('n', 'com', ":set mouse=<C-R>=&mouse == 'a' ? '' : 'a'<CR><CR>")
noremap('n', 'con', ':set number!<CR>')
noremap('n', 'cop', ':set paste!<CR>')
noremap('n', 'cos', ':set spell!<CR>')
noremap('n', 'cow', ':set wrap!<CR>')
-- Navigate split windows with one key combo instead of two
noremap('n', '<C-h>', '<C-w>h')
noremap('n', '<C-j>', '<C-w>j')
noremap('n', '<C-k>', '<C-w>k')
noremap('n', '<C-l>', '<C-w>l')
-- Navigate next and previous commands starting with current input
noremap('c', '<C-n>', '<Down>')
noremap('c', '<C-p>', '<Up>')
-- Navigate next and previous buffers
noremap('n', ']b', ':bnext<CR>')
noremap('n', '[b', ':bprevious<CR>')
noremap('n', '<Leader><Tab>', ':b#<CR>')
-- Navigate next and previous location lists
noremap('n', ']l', ':lnext<CR>')
noremap('n', '[l', ':lprevious<CR>')
-- Cut and copy to clipboard. Paste from clipboard
noremap('v', '<Leader>x', '"*x')
noremap('v', '<Leader>c', '"*y')
noremap('n', '<Leader>v', '"*p')
noremap('v', '<Leader>v', '"*p')
noremap('n', '<Leader><S-v>', '"*P')
noremap('v', '<Leader><S-v>', '"*P')
-- Copy current file path to clipboard
noremap('n', '<Leader>c', ':let @*=expand("%:p")<CR>')

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------
local packer = require('packer')
local use = packer.use
packer.startup(function()
  -- Plugin manager
  use 'wbthomason/packer.nvim'

  ------------------------------------------------------------------------------
  -- gruvbox: colorscheme
  ------------------------------------------------------------------------------
  use {
    'morhetz/gruvbox',
    config = function()
      -- Set colorscheme.  Make signcolumn same color as regular background
      vim.api.nvim_command([[
        colorscheme gruvbox
        highlight! link SignColumn Normal
      ]])
    end
  }

  ------------------------------------------------------------------------------
  -- treesitter: code parser and syntax highlighting
  ------------------------------------------------------------------------------
  use 'MaxMEllon/vim-jsx-pretty'
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
        },
      }
    end
  }

  ------------------------------------------------------------------------------
  -- lspconfig: Language server client configs
  ------------------------------------------------------------------------------
  use {
    'neovim/nvim-lspconfig',
    requires = 'nvim-lua/lsp-status.nvim',
    config = function ()
      local lsp_status = require('lsp-status')
      local nvim_lsp = require('lspconfig')

      -- Register statusline progress handler
      lsp_status.register_progress()
      lsp_status.config({
        status_symbol = '',
        indicator_errors = 'E',
        indicator_warnings = 'W',
        indicator_info = 'I',
        indicator_hint = 'H',
        indicator_ok = 'OK',
      })

      -- Always show sign column
      vim.opt.signcolumn = 'yes'

      -- Disable inline buffer error messages
      vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          virtual_text = false
        }
      )

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
        local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

        -- Attach client to lsp_status to provide updates for status line
        lsp_status.on_attach(client)

        --Enable completion triggered by <c-x><c-o>
        buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        local opts = { noremap=true, silent=true }

        -- See `:help vim.lsp.*` for documentation on any of the below functions
        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>k', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>d', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>r', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
        buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
        buf_set_keymap('n', '<LocalLeader>m', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

        -- Format file in buffer on save
        if client.resolved_capabilities.document_formatting then
          vim.api.nvim_command(
            'autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()'
          )
        end
      end

      -- npm install -g typescript typescript-language-server
      nvim_lsp.tsserver.setup{
        on_attach = function(client, bufnr)
          -- Disable formatting with tsserver. Use eslint in efm instead
          client.resolved_capabilities.document_formatting = false
          on_attach(client, bufnr)
        end,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        }
      }

      -- npm i -g vscode-langservers-extracted
      nvim_lsp.cssls.setup{
        on_attach = on_attach,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        },
        settings = {
          css = {
            validate = true,
            lint = {
              unknownAtRules = 'ignore',
              unknownProperties = 'ignore',
            }
          },
        }
      }
      nvim_lsp.html.setup{
        on_attach = on_attach,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        }
      }
      nvim_lsp.jsonls.setup{
        on_attach = on_attach,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        }
      }

      -- npm i -g stylelint-lsp
      nvim_lsp.stylelint_lsp.setup{
        on_attach = on_attach,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        },
        settings = {
          stylelintplus = {
            autoFixOnFormat = true,
            autoFixOnSave = true
          }
        },
        filetypes = {
          'css',
        }
      }

      -- brew install efm-langserver
      -- npm install -g eslint_d
      local eslint = {
        lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
        lintStdin = true,
        lintFormats = {'%f:%l:%c: %m'},
        lintIgnoreExitCode = true,
        formatCommand = 'eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}',
        formatStdin = true,
        rootMarkers = {
          '.eslintrc.js',
          '.eslintrc',
          vim.fn.getcwd(),
        }
      }
      nvim_lsp.efm.setup{
        root_dir = nvim_lsp.util.root_pattern('.eslintrc*') or nvim_lsp.util.dirname,
        init_options = {
          documentFormatting = true;
        },
        on_attach = on_attach,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        },
        settings = {
          languages = {
            javascript = {eslint},
            javascriptreact = {eslint},
            ['javascript.jsx'] = {eslint},
            typescript = {eslint},
            ['typescript.tsx'] = {eslint},
            typescriptreact = {eslint}
          }
        },
        filetypes = {
          'javascript',
          'javascriptreact',
          'javascript.jsx',
          'typescript',
          'typescript.tsx',
          'typescriptreact'
        },
      }

      -- https://github.com/sumneko/lua-language-server
      local system_name
      if vim.fn.has('mac') == 1 then
        system_name = 'macOS'
      elseif vim.fn.has('unix') == 1 then
        system_name = 'Linux'
      elseif vim.fn.has('win32') == 1 then
        system_name = 'Windows'
      else
        print('Unsupported system for sumneko')
      end

      -- set the path to the sumneko installation; if you previously installed via the now deprecated :LspInstall, use
      local sumneko_root_path = '/Users/andrew.w/repos/lua-language-server'
      local sumneko_binary = sumneko_root_path..'/bin/'..system_name..'/lua-language-server'

      local runtime_path = vim.split(package.path, ';')
      table.insert(runtime_path, 'lua/?.lua')
      table.insert(runtime_path, 'lua/?/init.lua')

      nvim_lsp.sumneko_lua.setup{
        cmd = {sumneko_binary, '-E', sumneko_root_path .. '/main.lua'};
        on_attach = on_attach,
        capabilities = lsp_status.capabilities,
        flags = {
          debounce_text_changes = 150,
        },
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
              version = 'LuaJIT',
              -- Setup your lua path
              path = runtime_path,
            },
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = {'vim'},
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file('', true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
              enable = false,
            },
          },
        },
      }
    end
  }

  ------------------------------------------------------------------------------
  -- lightline: configurable statusbar
  ------------------------------------------------------------------------------
  use {
    'itchyny/lightline.vim',
    requires = 'nvim-lua/lsp-status.nvim',
    config = function()
      vim.api.nvim_command([[
        function! LspStatus() abort
          if luaeval('#vim.lsp.buf_get_clients() > 0')
            return luaeval("require('lsp-status').status()")
          endif
          return ''
        endfunction
      ]])

      vim.g.lightline = {
        colorscheme = 'gruvbox',
        component_function = {
          lsp_status = 'LspStatus'
        },
        component = {
          lineinfo = '%3l:%-2v%<',
        },
        subseparator = {
          left = '',
          right = ''
        },
        active = {
          left = {
            { 'mode', 'paste' },
            -- { 'readonly', 'absolutepath', 'modified' }
            { 'readonly', 'filename', 'modified' }
          },
          right = {
            { 'lineinfo' },
            { 'filetype' },
            { 'lsp_status' }
          },
        },
        inactive = {
          left = {
            { 'readonly', 'filename', 'modified' }
          },
          right = {
              { 'lineinfo' },
              { 'filetype' },
            },
          },
      }
    end
  }

  ------------------------------------------------------------------------------
  -- comple: autocompletion plugin for language server client
  ------------------------------------------------------------------------------
  use {
    'hrsh7th/nvim-compe',
    config = function ()
      -- Pre-requisite for autocompletion window
      vim.opt.completeopt = 'menuone,noselect'
      -- Ignore ins-completion-menu messages in cmdline e.g. 'Pattern not found'
      vim.opt.shortmess:append('c')

      require('compe').setup {
        enabled = true;
        autocomplete = true;
        debug = false;
        min_length = 1;
        preselect = 'enable';
        throttle_time = 80;
        source_timeout = 200;
        resolve_timeout = 800;
        incomplete_delay = 400;
        max_abbr_width = 100;
        max_kind_width = 100;
        max_menu_width = 100;
        documentation = {
          border = { '', '' ,'', ' ', '', '', '', ' ' }, -- the border option is the same as `|help nvim_open_win|`
          winhighlight = 'NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder',
          max_width = 120,
          min_width = 60,
          max_height = math.floor(vim.o.lines * 0.3),
          min_height = 1,
        };

        source = {
          path = true;
          nvim_lsp = true;
          nvim_lua = true;
        };
      }

      local t = function(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
      end

      local check_back_space = function()
        local col = vim.fn.col('.') - 1
        if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
          return true
        else
          return false
        end
      end

      -- Use (s-)tab to:
      --- move to prev/next item in completion menuone
      --- jump to prev/next snippet's placeholder
      _G.tab_complete = function()
        if vim.fn.pumvisible() == 1 then
          return t '<C-n>'
        elseif check_back_space() then
          return t '<Tab>'
        else
          return vim.fn['compe#complete']()
        end
      end
      _G.s_tab_complete = function()
        if vim.fn.pumvisible() == 1 then
          return t '<C-p>'
        else
          return t '<S-Tab>'
        end
      end

      vim.api.nvim_set_keymap('i', '<Tab>', 'v:lua.tab_complete()', {expr = true})
      vim.api.nvim_set_keymap('s', '<Tab>', 'v:lua.tab_complete()', {expr = true})
      vim.api.nvim_set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', {expr = true})
      vim.api.nvim_set_keymap('s', '<S-Tab>', 'v:lua.s_tab_complete()', {expr = true})
    end
  }

  ------------------------------------------------------------------------------
  -- fzf: fuzzy finder
  ------------------------------------------------------------------------------
  use {
    { '/usr/local/opt/fzf' },
    {
      'junegunn/fzf.vim',
      config = function ()
        -- Size and position of fzf window
        vim.g.fzf_layout = { down = 10 }
        -- Navigate current buffers
        vim.api.nvim_set_keymap('n', '<Leader>b', ':Buffers<CR>', { noremap = true })
        -- Navigate by text search
        vim.api.nvim_set_keymap('n', '<Leader>f', ':Rg<CR>', { noremap = true })
        -- Navigate by filename search
        vim.api.nvim_set_keymap('n', '<Leader>p', ':Files<CR>', { noremap = true })
      end
    }
  }

  ------------------------------------------------------------------------------
  -- nerdtree: file tree Explorer, devicons: filetype glyphs
  ------------------------------------------------------------------------------
  use {
    {
      'preservim/nerdtree',
      config = function ()
        -- Width of sidebar
        vim.g.NERDTreeWinSize = 51
        -- Toggle sidebar
        vim.api.nvim_set_keymap('n', '<Leader>1', ':NERDTreeToggle<CR>', { noremap = true })
        -- Toggle sidebar with current file highlighted
        vim.api.nvim_set_keymap('n', '<Leader>2', ':NERDTreeFind<CR>', { noremap = true })
      end
    },
    {
      'ryanoasis/vim-devicons',
      config = function ()
        -- Make devicons colors same as open/closed directory icon
        vim.api.nvim_command('highlight! link NERDTreeFlags Special')
      end
    }
  }

  ------------------------------------------------------------------------------
  -- commentary: shortcuts for commenting code
  ------------------------------------------------------------------------------
  use 'tpope/vim-commentary'

  ------------------------------------------------------------------------------
  -- fugitive: git wrapper
  ------------------------------------------------------------------------------
  use {
    'tpope/vim-fugitive',
    config = function ()
      -- Toggle git-blame sidebar
      vim.api.nvim_set_keymap('n', '<Leader>g', ':Git blame<CR>', { noremap = true })
    end
  }

  ------------------------------------------------------------------------------
  -- surround: mappings to edit surroundings, repeat: repeatable surround edits
  ------------------------------------------------------------------------------
  use {
    'tpope/vim-surround',
    'tpope/vim-repeat'
  }

  ------------------------------------------------------------------------------
  -- easy-align text alignment by character
  ------------------------------------------------------------------------------
  use {
    'junegunn/vim-easy-align',
    config = function ()
      -- Start interactive EasyAlign in visual mode (e.g. vipga)
      vim.api.nvim_set_keymap('x', 'ga', '<Plug>(EasyAlign)', {})
      -- Start interactive EasyAlign for a motion/text object (e.g. gaip)
      vim.api.nvim_set_keymap('n', 'ga', '<Plug>(EasyAlign)', {})
    end
  }
end)
