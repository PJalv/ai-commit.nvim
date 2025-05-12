local M = {}

M.config = {
  openrouter_api_key = nil,
  model = "google/gemini-2.5-flash-preview",
  auto_push = false,
}

M.setup = function(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
end

M.generate_commit = function()
  require("commit_generator").generate_commit(M.config)
end

M.show_commit_suggestions = function(messages)
  local display = require("utils.commit_message_display")
  display.show_commit_message(messages)
end

vim.api.nvim_create_user_command("AICommit", function()
  M.generate_commit()
end, {})

return M
