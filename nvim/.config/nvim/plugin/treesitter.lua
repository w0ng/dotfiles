-- nvim-treesitter (main): parsers, highlighting, JSX commentstring
--------------------------------------------------------------------------------
vim.pack.add({
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
    'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
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
    'rust',
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
