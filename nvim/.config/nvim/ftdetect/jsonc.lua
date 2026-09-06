-- Treat .json as jsonc so comments and trailing commas are not flagged. Many
-- tools that read .json (tsconfig, .luarc.json, VS Code settings) permit both.
--
-- vim.filetype.add rather than an autocmd setting 'filetype' after the fact:
-- this replaces the built-in detection instead of correcting it, so only one
-- FileType event fires, and it fires as jsonc.
vim.filetype.add({
    extension = {
        json = 'jsonc',
    },
})
