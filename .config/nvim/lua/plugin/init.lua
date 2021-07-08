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
  use({
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('plugin/treesitter')
    end,
  })

  -- nvim-lspconfig: common configs for built-in LSP
  use({
    'neovim/nvim-lspconfig',
    config = function()
      require('plugin/lspconfig')
    end,
  })


  -- compl: autocompletion plugin for LSP
  use({
    'hrsh7th/nvim-compe',
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
    }
  })

  -- nvim-tree.lua: file explorer sidebar
  -- nvim-web-devicons: icons in sidebar
  use({
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('plugin/tree')
    end,
  })

  -- gitsigns.nvim: git decorators for git modified lines
  use({
    'lewis6991/gitsigns.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('gitsigns').setup()
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
    requires = 'tpope/vim-repeat'
  })

  -- vim-easy-align: text alignment by character
  use({
    'junegunn/vim-easy-align',
    config = function()
      require('plugin/easy_align')
    end,
  })
end)
