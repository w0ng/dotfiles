-- Based on:
-- https://gitlab.com/yorickpeterse/dotfiles/-/blob/master/dotfiles/.config/nvim/lua/dotfiles/diagnostics.lua
local M = {}
-- Timeout for debouncing print request
local timeout = 150
-- Callback function to call after timeout
local callback = nil
-- Previous diagnostic message printed
local prev_diagnostic = {
  bufnr = -1,
  linenr = -1,
  msg_printed = false,
}

local function is_same_diagnostic(bufnr, linenr)
  return bufnr == prev_diagnostic.bufnr
    and linenr == prev_diagnostic.linenr
    and prev_diagnostic.msg_printed
end

M.print_first_cursor_diagnostic = function()
  if callback then
    callback:stop()
  end

  callback = vim.defer_fn(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local linenr = vim.api.nvim_win_get_cursor(0)[1] - 1

    if is_same_diagnostic(bufnr, linenr) then
      return
    end

    local diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr, linenr)
    local msg = diagnostics[1] and diagnostics[1].message or nil

    if not msg then
      if prev_diagnostic.msg_printed then
        -- Clear previously printed message
        vim.api.nvim_echo({ { '', 'None' } }, false, {})
        prev_diagnostic = {
          bufnr = bufnr,
          linenr = linenr,
          msg_printed = false,
        }
      end
      return
    end

    -- Truncate msg to one line
    local width = vim.api.nvim_get_option('columns') - 15
    local truncated_msg = msg:gsub('[\n\r]', ' '):sub(1, width)

    vim.api.nvim_echo({ { truncated_msg, 'None' } }, false, {})
    prev_diagnostic = { bufnr = bufnr, linenr = linenr, msg_printed = true }
  end, timeout)
end

return M
