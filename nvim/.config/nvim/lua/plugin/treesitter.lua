require('nvim-treesitter.configs').setup({
  ensure_installed = {
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
  },

  -- Built in module
  highlight = {
    enable = true,
  },

  -- Built in module
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<C-n>',
      node_incremental = '<C-n>',
      scope_incremental = '<C-s>',
      node_decremental = '<C-p>',
    },
  },

  --https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
  },
})

require('ts_context_commentstring').setup({
  -- Disable updating commentstring on CursorHold
  enable_autocmd = false,
})
