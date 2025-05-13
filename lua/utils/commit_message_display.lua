local M = {}

--- Display a commit message in a floating buffer
--- @param messages string[] List of lines of the commit message
function M.show_commit_message(messages)
  local api = vim.api

  -- Combine lines into paragraphs separated by empty lines
  local combined_messages = {}
  if messages then
    local paragraph = {}
    for _, line in ipairs(messages) do
      if line == "" then
        if #paragraph > 0 then
          table.insert(combined_messages, table.concat(paragraph, "\n"))
          paragraph = {}
        end
      else
        table.insert(paragraph, line)
      end
    end
    if #paragraph > 0 then
      table.insert(combined_messages, table.concat(paragraph, "\n"))
    end
  end

  local commit_message = table.concat(combined_messages, "\n")

  -- Create a floating window to display the commit message
  local buf = api.nvim_create_buf(false, true) -- Create a new buffer
  local width = 60
  local height = 20
  local win = api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((api.nvim_get_option("columns") - width) / 2),
    row = math.floor((api.nvim_get_option("lines") - height) / 2),
    border = 'rounded',
    noautocmd = true,
  })

  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(commit_message, "\n")) -- Set the commit message in the buffer
  api.nvim_buf_set_option(buf, 'modifiable', false)                          -- Make the buffer read-only
  api.nvim_win_set_option(win, 'winhighlight', 'Normal:Normal')              -- Set window highlight
end

return M
