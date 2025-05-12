local telescope = require("telescope")

local function setup_opts(opts)
  local themes = require("telescope.themes")
  opts = opts or {}
  if opts.theme == nil then
    opts = themes.get_dropdown(opts)
  end
  return opts
end

local function push_changes()
  local Job = require("plenary.job")

  vim.notify("Pushing changes...", vim.log.levels.INFO)
  Job:new({
    command = "git",
    args = { "push" },
    on_exit = function(_, return_val)
      if return_val == 0 then
        vim.notify("Changes pushed successfully!", vim.log.levels.INFO)
      else
        vim.notify("Failed to push changes", vim.log.levels.ERROR)
      end
    end,
  }):start()
end

local function commit_changes(message)
  local Job = require("plenary.job")

  -- Split the message by new lines to separate subject and body
  local lines = {}
  for line in message:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  local args = { "commit" }
  if #lines > 0 then
    -- Use the first line as the commit subject
    table.insert(args, "-m")
    table.insert(args, lines[1])
    -- Add subsequent lines as additional -m arguments for the commit body
    for i = 2, #lines do
      table.insert(args, "-m")
      table.insert(args, lines[i])
    end
  else
    -- Fallback to the whole message if no lines found
    table.insert(args, "-m")
    table.insert(args, message)
  end

  Job:new({
    command = "git",
    args = args,
    on_exit = function(_, return_val)
      if return_val == 0 then
        vim.notify("Commit created successfully!", vim.log.levels.INFO)
        if require("ai-commit").config.auto_push then
          push_changes()
        end
      else
        vim.notify("Failed to create commit", vim.log.levels.ERROR)
      end
    end,
  }):start()
end

local function create_commit_picker(opts)
  local api = vim.api
  opts = setup_opts(opts)

  -- Combine lines into paragraphs separated by empty lines
  local messages = {}
  if opts.messages then
    local paragraph = {}
    for _, line in ipairs(opts.messages) do
      if line == "" then
        if #paragraph > 0 then
          table.insert(messages, table.concat(paragraph, "\n"))
          paragraph = {}
        end
      else
        table.insert(paragraph, line)
      end
    end
    if #paragraph > 0 then
      table.insert(messages, table.concat(paragraph, "\n"))
    end
  end

  -- Create a floating window to display the commit message
  local commit_message = table.concat(messages, "\n")
  local buf = api.nvim_create_buf(false, true) -- Create a new buffer
  local width = 60
  local height = 20
  local win = api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (api.nvim_get_option("columns") - width) / 2,
    row = (api.nvim_get_option("lines") - height) / 2,
    border = 'rounded',
  })

  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(commit_message, "\n")) -- Set the commit message in the buffer
  api.nvim_buf_set_option(buf, 'modifiable', false) -- Make the buffer read-only
  api.nvim_win_set_option(win, 'winhl', 'Normal:Normal') -- Set window highlight
end

return telescope.register_extension({
  exports = { commit = create_commit_picker },
})
