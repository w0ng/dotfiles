-- render-markdown.nvim: in-buffer rendering for markdown (heading bars, code
-- block backgrounds, table borders, callouts). Purely a display layer built from
-- extmarks and conceal -- the buffer text is never touched, so dprint via conform
-- still owns markdown formatting. Insert mode and the cursor line fall back to
-- raw markdown, so editing is never done blind.
--------------------------------------------------------------------------------
vim.pack.add({ 'https://github.com/MeanderingProgrammer/render-markdown.nvim' })

require('render-markdown').setup({})

vim.keymap.set('n', '<Leader>r', '<Cmd>RenderMarkdown buf_toggle<CR>', {
    desc = 'Toggle markdown rendering (buffer)',
})
