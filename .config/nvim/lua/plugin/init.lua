local packer = require('packer')
local use = packer.use

packer.startup(function()
  -- packer.nvim: plugin manager
  use('wbthomason/packer.nvim')

  -- gruvbox: dark colorscheme
  use({
    'npxbr/gruvbox.nvim',
    requires = 'rktjmp/lush.nvim',
    config = function()
      require('plugin/gruvbox')
    end,
  })

  -- galaxyline.nvim: conigurable statusline
  use({
    'glepnir/galaxyline.nvim',
    branch = 'main',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require('plugin/galaxyline')
    end,
  })

  -- vim-jsx-pretty: react syntax highlighting and indenting
  use('MaxMEllon/vim-jsx-pretty')

  -- nvim-treesitter: code parser and syntax highlighting
  -- nvim-treesitter-textobjects: per-language text objects
  -- nvim-ts-context-commentstring: per-language comments for React files
  use({
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('plugin/treesitter')
    end,
  })

  -- nvim-lspconfig: common configs for built-in LSP
  -- cmp-nvim-lsp: nvim-cmp source for neovim builtin LSP client
  -- lua-dev.nvim: better neovim completion (see plugin/lspconfig/sumneko_lua)
  use({
    'neovim/nvim-lspconfig',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'folke/lua-dev.nvim',
    },
    config = function()
      require('plugin/lspconfig')
    end,
  })

  -- vim-vsnip: enable vscode-style snippets
  -- friendly-snippets: collection of preconfigured snippets
  use({
    'hrsh7th/vim-vsnip',
    requires = 'rafamadriz/friendly-snippets',
    config = function()
      require('plugin/vsnip')
    end,
  })

  -- cmp: autocompletion plugin
  -- cmp-buffer: nvim-cmp source for buffer words.
  -- cmp-nvim-lsp: nvim-cmp source for neovim builtin LSP client
  -- cmp-path: nvim-cmp source for filesystem paths
  -- cmp-vsnip: nvim-cmp source for vim-vsnip
  -- lspkind: pictograms to neovim built-in lsp kinds
  use({
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-vsnip',
      'hrsh7th/vim-vsnip',
      'onsails/lspkind-nvim',
    },
    config = function()
      require('plugin/cmp')
    end,
  })

  -- fzf.vim: fuzzy finder
  use({
    '/usr/local/opt/fzf',
    {
      'junegunn/fzf.vim',
      config = function()
        require('plugin/fzf')
      end,
    },
  })

  -- nvim-bqf: better quickfix windows
  use({
    'kevinhwang91/nvim-bqf',
    config = function()
      require('plugin/bqf')
    end,
  })

  -- nvim-tree.lua: file explorer sidebar
  -- nvim-web-devicons: icons in sidebar
  use({
    'kyazdani42/nvim-tree.lua',
    requires = {
      'kyazdani42/nvim-web-devicons',
      'npxbr/gruvbox.nvim',
    },
    config = function()
      require('plugin/tree')
    end,
  })

  -- gitsigns.nvim: git decorators for git modified lines
  use({
    'lewis6991/gitsigns.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('plugin/gitsigns')
    end,
  })

  -- diffview.nvim: single view for all file diffs
  use({
    'sindrets/diffview.nvim',
    config = function()
      require('plugin/diffview')
    end,
  })

  -- -- neogit: git interface (using this for everything except :Git blame)
  -- use({
  --   'TimUntersberger/neogit',
  --   requires = 'sindrets/diffview.nvim',
  --   config = function()
  --     require('plugin/neogit')
  --   end,
  -- })

  -- vim-fugitive: git wrapper (only still using this for :Git blame)
  use({
    'tpope/vim-fugitive',
    config = function()
      require('plugin/fugitive')
    end,
  })

  -- formatter.nvim: run external code formatters
  use({
    'mhartington/formatter.nvim',
    config = function()
      require('plugin/formatter')
    end,
  })

  -- nvim-colorizer.lua: highlights color codes
  use({
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  })

  -- vim-commentary: shortcuts for commenting code
  use('tpope/vim-commentary')

  -- vim-surround: mappings to edit surroundings
  -- vim-repeat: allows repeatable surround edits using '.'
  use({
    'tpope/vim-surround',
    requires = 'tpope/vim-repeat',
  })

  -- iamcco/markdown-preview.nvim: markdown preview in browser
  use({
    'iamcco/markdown-preview.nvim',
    run = 'cd app && yarn install',
  })
end)
