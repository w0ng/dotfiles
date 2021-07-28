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
  -- lua-dev.nvim: better neovim completion (see plugin/lspconfig/sumneko_lua)
  use({
    'neovim/nvim-lspconfig',
    requires = 'folke/lua-dev.nvim',
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

  -- compe: autocompletion plugin for LSP
  use({
    'hrsh7th/nvim-compe',
    requires = 'hrsh7th/vim-vsnip',
    config = function()
      require('plugin/compe')
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

  -- vim-fugitive: git wrapper
  use({
    'tpope/vim-fugitive',
    config = function()
      require('plugin/fugitive')
    end,
  })

  -- vim-surround: mappings to edit surroundings
  -- vim-repeat: allows repeatable surround edits using '.'
  use({
    'tpope/vim-surround',
    requires = 'tpope/vim-repeat',
  })
end)
