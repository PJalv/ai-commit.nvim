local M = {}

local openrouter_api_endpoint = "https://openrouter.ai/api/v1/chat/completions"
-- TODO: Make commit message template configurable
local commit_prompt_template = [[
Generate 5 different git commit messages based on the following git diff:

Use the conventional commit format: type(scope): concise description
Analyze the entire diff and identify different aspects of the changes (new features, bug fixes, refactoring, etc.)
For each message, focus on a different significant aspect of the changes
Return ONLY the commit messages - no introduction, no quotes, and no explanations
Each message should be concise, stating only WHAT was done, not WHY
Each message should have a single type and scope, focusing on one aspect of the changes

Examples of good diverse commit messages for the same diff:
feat(auth): implement user login functionality
fix(validation): correct email format validation
refactor(api): restructure authentication routes
style(forms): standardize input field appearance
test(auth): add unit tests for authentication flow
This section provides specification on commit descriptions, commit content, granularity of commit, and commit methods. These specification must be carefully followed and strictly implemented.

3.1.    Commit instructions
Content of the Commit Message:
The commit message must explain the intention or motivation behind the changes relative to the parent commit and include all necessary information to allow reviewers to "fully understand and evaluate the correctness of the change," and to help the testing department "understand the change and design corresponding test plans." The more detailed, the better. The commit description should include the following content:

Title: A very brief summary of the change, explaining what happened in the most concise way. The title should not span multiple lines and must be separated by one blank line from the body text.
Problem Description: For bugs, a description of the original issue must be provided. Explain why the issue needs to be addressed, describe the problem scenario, including the symptoms, frequency, and reproduction steps. Evaluate the impact of the issue, such as the consequences, scope, and severity. Be sure to describe the visible impact from a black-box perspective, not just a white-box description.
Root Cause Analysis: Analyze the cause of the problem, explaining both the immediate and root causes, and provide an explanation from a principle and mechanism perspective.
Solution: For features, describe what functionality has been modified. For bugs, explain how the issue was fixed. Describe the overall structure of the code or changes as thoroughly as possible.
Self-Testing Results: Outline the verification and self-testing methods and conclusions. For critical or hard-to-reproduce bugs, provide detailed self-testing information, such as how many times the issue was tested without reproduction, and conclude that the issue is fixed. If the issue is related to specific devices, it's best to mention the device model used during testing.


The following are additional items that may be included in the commit message if necessary:

Change Overview: A brief introduction to the functionality implemented or the issue resolved. It should align perfectly with the commit content and must not be omitted or inconsistent.
Impact Assessment: Describe the results after the change is made. Explain the effects and impact of the modification. If the scope of the impact is not global and the modified library name and commit title prefix cannot accurately specify the impact range (e.g., which solution, model type, or modules), please provide a detailed explanation here. If the modification is made only within a specific macro-wrapped code, and the macro is not universally enabled, please specifically note which macro controls the modification and which model types currently enable this macro.
Known Issues: List any known issues and limitations.
Testing Suggestions: Provide testing requirements and suggestions for the testing department. If the change has a significant impact, this section should not be omitted.
Reference Commit: If the commit differs significantly from the reference commit and cannot be cherry-picked, but only referenced or ported, provide the list of reference commits and explain the adjustments made relative to those reference commits.
Related Commits: If there are cross-repository dependencies with other projects, list them here. Provide the paths and corresponding Change-Id for other projects.
Additional Information: Include any case numbers or relevant discussion email titles.


For feature development commits, the following content must be included at a minimum:

Change Overview, Solution, Self-Testing Results, and Impact Assessment.:

Title specification
The Header section is one line long and follows the format below:

<type>(<scope>): <subject>

  Below are the definitions of type, scope, and subject .

type : specify the type of the change (e.g. feat, fix, docs, style, refactor, test, chore, etc.).
scope : Specifies the scope or module affected by the change.
subject : A brief description of the change.

          type

feat: New feature
fix: Bug fix
docs: Documentation change
style: Code style changes, e.g., spaces, semicolons, etc.
refactor: Code changes that neither add a feature nor fix a bug
chore: Changes related to project build, non-code and non-test changes
revert: Version rollback


  scope

  used to describe the range affected by the commit. When the commit involves specific modules, the module name should be included. If the change spans multiple modules, separate them with "|". Examples include:

Modules such as build, client, server, plugin, etc
components such as ntpd, mount, etcin busybox
Plugins such as wds, guest-network in LuCI
Other qualifiers that can indicate range, such as 2g, 5g, band4 in wireless networks


      subject

The subject is a brief description of the commit's purpose, not exceeding 100 characters:
Start with a verb in the present tense (e.g., change, not changed or changes).
The first letter should be lowercase.
Do not add a period (.) at the end.
Reflect the extent and method of bug fix:
If it's a complete fix, use "Fix ..." format.
If the fix was believed to be complete but requires further changes, the new commit title can be the same as the previous one, with "(2)" added at the end to indicate it's a continued fix.
If it's a tentative fix and cannot be determined to be effective, use "Trivial fix ..." format.
If it's a partial fix, use "Partial fix ..." format.
If this change is a Walk Around (temporary workaround), add "(WAR)" at the end of the title.
If the change avoids an issue but doesn't eliminate the root cause, use "Avoid ..." or "Suppress ..." instead of "Fix ...". For example, suppressing warnings via configuration options doesn't address the root cause and should not be labeled as "Fix".
Including Bug/Issue Number in the title: If this commit is related to a bug in Bugzilla or an issue in Redmine related to a development task or research project (not project management), include the Bug/Issue number in the title using the format:
Fix #NNNNN:
Issue #NNNNN.




Example

fix(qca-nss-dp): Resolve cache dirty data issue caused by the introduction of fast_recycled mechanism

[Problem Description]
On 12.1 BE85 2.0, when downloading an app via HTTPS on IOS devices, the data field of the packet was modified to all 0s or other abnormalities, causing data parsing to fail and the download to be interrupted.

[Cause Analysis]
After the introduction of fast_recycled, during edma_rx or wifi_rx, the skb used for DMA operations was not cleared from the cache, causing a mismatch between the cache data and the memory. Later, TX writes the corresponding cache back, resulting in the tampering of the packet.

[Solution]
Disable this mechanism to resolve the issue of cache and memory inconsistency.

[Self-test Results]
The issue disappeared after self-testing on BE85 2.0.

(IMPORTANT TO KEEP THE BRACKET SYNTAX FORMAT!!



3.2.    Commit content
Use Unix Line Endings:
If Windows line endings are used, git diff will display ^M at the end of lines, so it is recommended to use Unix line endings. If the original file uses Windows line endings, follow the module's conventions. Consider converting all code to use Unix line endings for consistency, and continue using Unix line endings in future commits. For vendor or third-party code, do not make changes to the line endings.

Use UTF-8 Without BOM.
If there are Chinese characters in the text file, it is recommended to save it in UTF-8 format to prevent garbled characters in Gerrit. The UTF-8 Without BOM format is preferred.

Avoiding whitespace errors.
Do not introduce whitespace errors in newly added or modified code. This includes:

• No spaces or tabs at the end of lines.

• Do not mix spaces and tabs at the beginning of the same line.

Commit messages should also be free of whitespace errors.

Exceptions:

• When committing vendor or third-party code, whitespace errors are not fixed to facilitate code comparison.

• JavaDoc style comments can allow a space after the *.

Try to Match the Original Code Style:
When modifying code, try to maintain the style of the original file. For example, if the original code uses tabs for indentation, new lines should also use tabs, not spaces. If the original code uses spaces, do not use tabs. If the original code uses \n for line breaks, do not switch to \r\n.

Avoid Accidental File Permission Changes:
Do not accidentally change file permissions, as this increases the likelihood of conflicts and adds maintenance overhead. Pay close attention to the command line output during commits to check if file permission changes are indicated.

Do Not Commit Files That Are Difficult to Compare:
Take full advantage of version control's diff functionality by avoiding the inclusion of files that are difficult to compare. For example:
  • Generated compilation artifacts. Use .gitignore to filter them.
  • Binary files generated from text files. Only maintain the text files and use tools to convert them to binary files.
  • Obfuscated code. Commit the original code and obfuscate it during the build process.
  • Compressed files. It is recommended to extract them before committing.
  • PDF documents. If original Word/Excel documents are available, commit those instead of the converted PDF files.
If these files must be uploaded due to current constraints, clearly describe the differences from the parent commit in the commit message.

Do Not Commit Temporary Debug Code:
Do not commit changes that should not be shared, such as personal debugging code, enabled debugging macros, or module-specific debug information. If temporary debug code is committed and pushed to Gerrit for personal backup purposes, add (DO NOT MERGE) to the title to prevent accidental merging.

3.3.      Commit Granularity
The "commit" constraints discussed here refer specifically to commits pushed to the Gerrit server for review, not the local commits in a version control repository. Before pushing to the central repository, you can commit frequently and freely locally, but before pushing for review, you should review and organize your commits into logically independent atomic commits before submitting for review.

Each Commit Should Have One Clear Responsibility (Atomicity):
Precisely control commit granularity by structurally breaking changes into logically independent atomic commits. Ensure that each commit contains only one "logical change" and avoid mixing unrelated functional changes in a single commit.
Separate Logical Changes and Formatting Changes:
Do not mix whitespace changes (such as spaces, newlines, tabs, etc.) with functional code changes. Formatting changes can obscure important functional changes, making it difficult for reviewers to determine the correctness of the change. Solution: Split these into two commits: one for whitespace changes and another for functional changes. Generally, start by submitting whitespace-related changes first, though this order is not strict.
Do Not Implement a Large Feature in a Single Commit:
For large functional modules, split them into smaller, manageable logical units that can be committed frequently. Ensure that after each commit, the program still compiles and functions properly. Avoid committing incomplete changes.
In some cases, a new feature may only work when all changes are in place, but this doesn't mean the entire feature should be included in a single commit. New features often involve refactoring existing code, and it makes sense to separate those refactoring from the feature implementation. This helps reviewers and testers verify that these refactors do not introduce unexpected functional changes. Even new code can be broken down into multiple changes that can be reviewed independently.
Separate Fixes and Optimizations:
If a change contains both bug fixes and performance optimizations, split them into two or more commits, unless the bug is inherently related to performance issues.
Separate Feature Implementation and Enabling:
When adding a new feature with a switch, at least two commits are needed: one for the feature implementation and another to enable it on specific devices.
Although enabling a feature depends on its implementation, and enabling and implementation are typically committed across different repositories, the commit messages for these should not be the same with a (n/m) suffix. This is because enabling commits, when cherry-picked to other branches, may require modification of the commit message. Therefore:
• Separate the titles: one for "Implement..." and another for "[board] Enable...".
• In the implementation commit message, specify how to enable the feature (e.g., by enabling a macro in the device configuration).
• In the enabling commit message, specify which commit implements the feature.
Similarly, if your changes involve a new API and some modules are deprecating an old API, split the implementation of the new API and its enabling into separate commits.
Separate Common Changes and Specific Changes:
Separate common changes and changes targeting specific devices or configurations. If your changes include both common modifications and specific changes for certain devices or configurations, split them into independent commits.
Submit Third-Party Code Separately:
If your commit contains code from upstream vendors or third parties, submit it separately, maintaining the original code as much as possible, to a branch dedicated to maintaining upstream code. Specify the third-party code version in the commit message. Do not mix your changes into this commit.
This approach makes it easier to track upstream changes.
Organize Code When Cherry-Picking:
When cherry-picking code from other branches, do not directly cherry-pick large commits. If the original commit is large, split it into smaller commits and submit them.
If multiple commits need to be synchronized to your branch, avoid merging them into one large commit (with one parent commit), as this will increase the difficulty of review and maintenance. Follow the guidelines in this chapter to organize your commits and note the reference commits in the commit message.
Git diff:
%s
Recent commits:
%s
]]

local function validate_api_key(config)
  local api_key = config.openrouter_api_key or vim.env.OPENROUTER_API_KEY
  if not api_key then
    vim.notify(
      "OpenRouter API key not found. Please set OPENROUTER_API_KEY environment variable or configure openrouter_api_key in your config",
      vim.log.levels.ERROR
    )
    return nil
  end
  return api_key
end

local function collect_git_data()
  local diff_context = vim.fn.system("git -P diff --cached -U10")

  if diff_context == "" then
    vim.notify("No staged changes found. Add files with 'git add' first.", vim.log.levels.ERROR)
    return nil
  end

  local recent_commits = vim.fn.system("git log --oneline -n 5")

  return {
    diff = diff_context,
    commits = recent_commits,
  }
end

local function create_prompt(git_data)
  return string.format(commit_prompt_template, git_data.diff, git_data.commits)
end

local function prepare_request_data(prompt, model)
  return {
    model = model,
    messages = {
      {
        role = "system",
        content = "You are a helpful assistant that generates git commit messages following the conventional commits specification.",
      },
      {
        role = "user",
        content = prompt,
      },
    },
  }
end

-- TODO: Refactor this
local function handle_api_response(response)
  if response.status == 200 then
    local data = vim.json.decode(response.body)
    local messages = {}

    if data.choices and #data.choices > 0 and data.choices[1].message and data.choices[1].message.content then
      local message_content = data.choices[1].message.content
      for msg in message_content:gmatch("[^\n]+") do
        table.insert(messages, msg)
      end

      if #messages > 0 then
        require("ai-commit").show_commit_suggestions(messages)
      else
        vim.notify("No commit messages were generated. Try again or modify your changes.", vim.log.levels.WARN)
      end
    else
      vim.notify(
        "Received empty response from model. The model may be warming up, try again in a few moments.",
        vim.log.levels.WARN
      )
    end
  else
    local error_info = "Unknown error"

    local ok, error_data = pcall(vim.json.decode, response.body)

    if ok and error_data and error_data.error then
      local error_code = error_data.error.code or response.status
      local error_message = error_data.error.message or "No error message provided"

      if error_code == 402 then
        error_info = "Insufficient credits: " .. error_message
      elseif error_code == 403 and error_data.error.metadata and error_data.error.metadata.reasons then
        local reasons = table.concat(error_data.error.metadata.reasons, ", ")
        error_info = "Content moderation error: " .. reasons
        if error_data.error.metadata.flagged_input then
          error_info = error_info .. " (flagged input: '" .. error_data.error.metadata.flagged_input .. "')"
        end
      elseif error_code == 408 then
        error_info = "Request timed out. Try again later."
      elseif error_code == 429 then
        error_info = "Rate limited. Please wait before trying again."
      elseif error_code == 502 then
        error_info = "Model provider error: " .. error_message
        if error_data.error.metadata and error_data.error.metadata.provider_name then
          error_info = error_info .. " (provider: " .. error_data.error.metadata.provider_name .. ")"
        end
      elseif error_code == 503 then
        error_info = "No available model provider: " .. error_message
      else
        error_info = string.format("Error %d: %s", error_code, error_message)
      end
    else
      error_info = string.format("Error %d: %s", response.status, response.body)
    end

    vim.notify("Failed to generate commit message: " .. error_info, vim.log.levels.ERROR)
  end
end

local function send_api_request(api_key, data)
  vim.schedule(function()
    vim.notify("Generating commit message...", vim.log.levels.INFO)
  end)

  require("plenary.curl").post(openrouter_api_endpoint, {
    headers = {
      content_type = "application/json",
      authorization = "Bearer " .. api_key,
    },
    body = vim.json.encode(data),
    callback = vim.schedule_wrap(handle_api_response),
  })
end

function M.generate_commit(config)
  local api_key = validate_api_key(config)
  if not api_key then
    return
  end

  local git_data = collect_git_data()
  if not git_data then
    return
  end

  local prompt = create_prompt(git_data)
  local data = prepare_request_data(prompt, config.model)

  send_api_request(api_key, data)
end

return M
