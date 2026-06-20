-- Make
function SetReleaseBuild()
  vim.opt.makeprg = 'cmake --preset=release && cmake --build --preset=release'
  print 'Build type set to: Release with vcpkg'
end

function SetDebugBuild()
  vim.opt.makeprg = 'cmake --preset=debug && cmake --build --preset=debug'
  print 'Build type set to: Debug with vcpkg'
end

vim.api.nvim_create_user_command('MakeRelease', SetReleaseBuild, {})
vim.api.nvim_create_user_command('MakeDebug', SetDebugBuild, {})

-- .NET build and restore
local function find_sln_file(start_path)
  local function is_sln_file(name)
    return name:match '%.sln$'
  end

  local path = vim.fn.expand(start_path or '%:p:h')
  while path ~= '/' and path ~= '' do
    local files = vim.fn.readdir(path)
    for _, filename in ipairs(files) do
      if is_sln_file(filename) then
        return path .. '/' .. filename
      end
    end
    path = vim.fn.fnamemodify(path .. '/..', ':p') or ''
  end
  return nil
end

local function strip_ansi(line)
  return line:gsub('\27%[[0-?]*[ -/]*[@-~]', '')
end

local command_icons = vim.g.have_nerd_font and {
  error = '',
  success = '',
  test = '',
} or {
  error = '[x]',
  success = '[ok]',
  test = '[test]',
}

local function quickfix_text(text)
  text = strip_ansi(text)
  text = text:gsub('[\r\n\t]+', ' ')
  text = text:gsub('%c+', ' ')
  text = text:gsub('%s+', ' ')
  text = vim.trim(text)

  if #text > 160 then
    text = text:sub(1, 157) .. '...'
  end

  return text
end

local function add_dotnet_diagnostic(qf_list, seen, file, lnum, col, type, code, msg, user_data)
  local key = table.concat({ file, lnum, col, type, code, msg }, '|')
  if seen[key] then
    return
  end

  seen[key] = true
  table.insert(qf_list, {
    filename = vim.fn.fnamemodify(file, ':p'),
    lnum = tonumber(lnum),
    col = tonumber(col),
    text = quickfix_text(string.format('%s %s: %s', type:upper(), code, msg)),
    type = type:sub(1, 1):upper(),
    user_data = user_data,
  })
end

local function set_quickfix(qf_list, title)
  vim.fn.setqflist({}, 'r', { title = title, items = qf_list })
end

local function open_quickfix(mode, action)
  if vim.fn.exists ':Trouble' == 2 then
    local trouble_mode = mode or 'quickfix'
    vim.cmd('silent Trouble ' .. trouble_mode)
    vim.defer_fn(function()
      vim.cmd('silent Trouble ' .. trouble_mode .. ' ' .. (action or 'fold_close_all'))
    end, 50)
  else
    vim.cmd 'silent copen'
  end
end

local function dotnet_build_async()
  local sln = find_sln_file()
  if not sln then
    print(command_icons.error .. ' No .sln file found')
    return
  end

  local qf_list = {}
  local seen = {}
  vim.fn.setqflist({}, 'r') -- clear quickfix first

  vim.fn.jobstart({ 'dotnet', 'build', sln }, {
    stdout_buffered = true,

    on_stdout = function(_, data)
      if not data then
        return
      end

      for _, line in ipairs(data) do
        local file, lnum, col, type, code, msg = string.match(line, '^(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+(%w+)%s*:%s*(.+)$')

        if file and lnum and col and type and code and msg and (type == 'error' or type == 'warning') then
          local key = table.concat({ file, lnum, col, type, code, msg }, '|')
          if not seen[key] then
            seen[key] = true
            table.insert(qf_list, {
              filename = vim.fn.fnamemodify(file, ':p'),
              lnum = tonumber(lnum),
              col = tonumber(col),
              text = string.format('%s %s: %s', type:upper(), code, msg),
              type = type:sub(1, 1):upper(), -- "E" or "W"
            })
          end
        end
      end
    end,

    on_exit = function(_, code)
      if #qf_list > 0 then
        vim.fn.setqflist(qf_list, 'r')
        vim.cmd 'Trouble quickfix'
      end

      if code == 0 then
        if #qf_list == 0 then
          print(command_icons.success .. ' Build succeeded with no errors or warnings.')
        else
          print(command_icons.success .. ' Build succeeded with warnings.')
        end
      else
        print(command_icons.error .. ' Build failed with exit code ' .. code)
      end
    end,
  })
end

-- Run `dotnet test` asynchronously and publish failures to the normal quickfix
-- list. Test failures are grouped by source file/line so quickfix navigation
-- jumps once per failing line. The dotnet_test Trouble mode renders multiline
-- text without Treesitter because failure output is not valid C#.
local function dotnet_test_quickfix_async(cmd)
  local test_cmd = cmd
  if not test_cmd then
    local sln = find_sln_file()
    if not sln then
      print(command_icons.error .. ' No .sln file found')
      return
    end

    test_cmd = { 'dotnet', 'test', sln }
  end
  vim.fn.setqflist({}, 'r') -- clear quickfix first
  if type(test_cmd) == 'string' then
    print(command_icons.test .. ' dotnet test - Running: ' .. quickfix_text(test_cmd))
  else
    print(command_icons.test .. ' dotnet test - Running: ' .. quickfix_text(table.concat(test_cmd, ' ')))
  end

  local diagnostic_pattern = '^(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+(%w+)%s*:%s*(.+)$'
  local stack_frame_pattern = '%s+at .- in (.-):line (%d+)'
  local parser = {
    qf_list = {},
    failure_groups = {},
    seen = {},
    current_test = nil,
    current_message = nil,
    in_error_message = false,
    run_error_message = nil,
    current_frames = {},
    current_failure_lines = {},
  }

  local function short_test_name(test_name)
    return test_name:match '([%w_`]+%.[^%.]+)$' or test_name
  end

  local function test_display_name(test_name)
    return short_test_name(test_name):match '^[^%.]+%.(.+)$' or test_name
  end

  local function sort_quickfix()
    local severity_order = {
      E = 1,
      W = 2,
    }

    table.sort(parser.qf_list, function(a, b)
      local a_severity = severity_order[a.type] or 99
      local b_severity = severity_order[b.type] or 99
      if a_severity ~= b_severity then
        return a_severity < b_severity
      end

      local a_has_location = a.filename ~= nil and a.lnum ~= nil
      local b_has_location = b.filename ~= nil and b.lnum ~= nil
      if a_has_location ~= b_has_location then
        return a_has_location
      end

      local a_filename = a.filename or ''
      local b_filename = b.filename or ''
      if a_filename ~= b_filename then
        return a_filename < b_filename
      end

      local a_lnum = a.lnum or 0
      local b_lnum = b.lnum or 0
      if a_lnum ~= b_lnum then
        return a_lnum < b_lnum
      end

      local a_col = a.col or 0
      local b_col = b.col or 0
      if a_col ~= b_col then
        return a_col < b_col
      end

      return (a.text or '') < (b.text or '')
    end)
  end

  local function add_quickfix_item(item)
    local key = table.concat({
      item.filename or '',
      item.lnum or 0,
      item.col or 0,
      item.type or '',
      item.text or '',
    }, '|')
    if parser.seen[key] then
      return false
    end

    parser.seen[key] = true
    table.insert(parser.qf_list, item)
    return true
  end

  local function fallback_location()
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file ~= '' and vim.fn.filereadable(current_file) == 1 then
      return current_file
    end

    return find_sln_file(vim.fn.getcwd())
  end

  local function add_failure(file, lnum, summary, text)
    local filename = vim.fn.fnamemodify(file, ':p')
    local line_number = tonumber(lnum)
    local key = table.concat({ filename, line_number, 1 }, '|')
    local group = parser.failure_groups[key]
    if not group then
      group = {
        filename = filename,
        lnum = line_number,
        col = 1,
        summaries = {},
        details = {},
      }
      parser.failure_groups[key] = group
    end

    table.insert(group.summaries, summary)
    table.insert(group.details, text)
  end

  local function add_failure_without_location(text)
    local fallback_file = fallback_location()
    local item = {
      text = text,
      type = 'E',
    }

    if fallback_file then
      item.filename = vim.fn.fnamemodify(fallback_file, ':p')
      item.lnum = 1
      item.col = 1
    end

    add_quickfix_item(item)
  end

  -- Finalize the currently parsed failing test. Prefer a frame matching the
  -- test class, then any *.Tests frame, then the first parsed frame. Stackless
  -- failures use a fallback file so Trouble can display them as valid items.
  local function flush_failure()
    if not parser.current_test then
      parser.current_frames = {}
      parser.current_message = nil
      parser.current_failure_lines = {}
      return
    end

    local frame = nil
    local class_name = short_test_name(parser.current_test):match '^([^%.]+)%.'
    if class_name then
      for _, candidate in ipairs(parser.current_frames) do
        if candidate.file and vim.fn.fnamemodify(candidate.file, ':t:r') == class_name then
          frame = candidate
          break
        end
      end
    end

    if not frame then
      for _, candidate in ipairs(parser.current_frames) do
        if candidate.file and candidate.file:match '%.Tests/' then
          frame = candidate
          break
        end
      end
    end

    frame = frame or parser.current_frames[1]

    local test_name = test_display_name(parser.current_test)
    local full_message = parser.current_message and ('FAILED ' .. test_name .. ': ' .. parser.current_message) or ('FAILED ' .. test_name)
    local summary = full_message
    if parser.current_message then
      summary = quickfix_text(full_message)
    end

    local full_text = vim.trim(table.concat(parser.current_failure_lines, '\n'))
    local qf_text = summary
    if full_text ~= '' then
      qf_text = summary .. '\n' .. full_text
    end

    if frame then
      add_failure(frame.file, frame.lnum, summary, qf_text)
    else
      add_failure_without_location(qf_text)
    end

    parser.current_test = nil
    parser.current_message = nil
    parser.current_frames = {}
    parser.current_failure_lines = {}
  end

  -- Parse one line of dotnet output.
  -- Handles compiler diagnostics immediately, otherwise accumulates test failure
  -- context until the next failure or process exit calls `flush_failure`.
  local function parse_line(line)
    line = strip_ansi(line)
    if line:match '^%s*Failed!%s+%-%s+Failed:%s+%d+,%s+Passed:%s+%d+,%s+Skipped:%s+%d+,%s+Total:%s+%d+,' then
      flush_failure()
      return
    end

    local file, lnum, col, type, code, msg = string.match(line, diagnostic_pattern)
    if file and lnum and col and type and code and msg and (type == 'error' or type == 'warning') then
      add_dotnet_diagnostic(parser.qf_list, parser.seen, file, lnum, col, type, code, msg)
      return
    end

    local failed_test = string.match(line, '^%s*Failed%s+(.+)$')
    if failed_test then
      flush_failure()
      parser.current_test = vim.trim(failed_test:gsub('%s*%[%d+%s*ms%]%s*$', ''))
      parser.current_message = nil
      parser.current_frames = {}
      parser.current_failure_lines = { line }
      parser.in_error_message = false
      return
    end

    if parser.current_test then
      table.insert(parser.current_failure_lines, line)
    end

    if string.match(line, 'The active test run was aborted') or string.match(line, 'Test Run Aborted') then
      parser.run_error_message = vim.trim(line)
      return
    end

    if string.match(line, '^%s*Error Message:%s*$') then
      parser.in_error_message = true
      return
    end

    if string.match(line, '^%s*Stack Trace:%s*$') then
      parser.in_error_message = false
      return
    end

    if parser.in_error_message and string.match(line, '%S') then
      local message_line = vim.trim(line)
      if parser.current_message then
        parser.current_message = parser.current_message .. ' ' .. message_line
      else
        parser.current_message = message_line
      end
      return
    end

    local stack_file, stack_lnum = string.match(line, stack_frame_pattern)
    if stack_file and stack_lnum then
      table.insert(parser.current_frames, { file = stack_file, lnum = stack_lnum })
    end
  end

  local function parse_output(_, data)
    if not data then
      return
    end

    for _, line in ipairs(data) do
      parse_line(line)
    end
  end

  local function add_grouped_failures()
    for _, group in pairs(parser.failure_groups) do
      local count = #group.details
      local text = group.details[1]
      if count > 1 then
        local lines = { string.format('[%d failures] %s', count, group.summaries[1]) }
        for index, detail in ipairs(group.details) do
          table.insert(lines, '')
          table.insert(lines, string.format('--- Failure %d of %d ---', index, count))
          table.insert(lines, detail)
        end
        text = table.concat(lines, '\n')
      end

      add_quickfix_item {
        filename = group.filename,
        lnum = group.lnum,
        col = group.col,
        text = text,
        type = 'E',
      }
    end
  end

  vim.fn.jobstart(test_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = parse_output,
    on_stderr = parse_output,

    on_exit = function(_, code)
      flush_failure()
      add_grouped_failures()

      if parser.run_error_message and #parser.qf_list == 0 then
        add_failure_without_location(parser.run_error_message)
      end

      if code ~= 0 and #parser.qf_list == 0 then
        add_failure_without_location('dotnet test failed with exit code ' .. code)
      end

      if #parser.qf_list > 0 then
        sort_quickfix()
        set_quickfix(parser.qf_list, 'dotnet test')
        open_quickfix 'dotnet_test'
      end

      if code == 0 then
        print(command_icons.success .. ' Tests passed.')
      else
        print(command_icons.error .. ' Tests failed with exit code ' .. code)
      end
    end,
  })
end

_G.DotnetTestQuickfixRun = dotnet_test_quickfix_async

local function dotnet_restore_async()
  local sln = find_sln_file()
  if not sln then
    print(command_icons.error .. ' No .sln file found')
    return
  end

  local output_lines = {}

  vim.fn.jobstart({ 'dotnet', 'restore', sln }, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      if data then
        vim.list_extend(output_lines, data)
      end
    end,

    on_stderr = function(_, data)
      if data then
        vim.list_extend(output_lines, data)
      end
    end,

    on_exit = function(_, code)
      if code == 0 then
        print(command_icons.success .. ' Restore succeeded.')
      else
        print(command_icons.error .. ' Restore failed with exit code ' .. code)
        for _, line in ipairs(output_lines) do
          print(line)
        end
      end
    end,
  })
end

vim.api.nvim_create_user_command('DotnetBuildAsync', dotnet_build_async, {})
vim.api.nvim_create_user_command('DotnetTestAsync', function()
  dotnet_test_quickfix_async()
end, {})
vim.api.nvim_create_user_command('DotnetTestNearestAsync', function()
  vim.cmd 'TestNearest -strategy=quickfix_dotnet'
end, {})
vim.api.nvim_create_user_command('DotnetRestoreAsync', dotnet_restore_async, {})
