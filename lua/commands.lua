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

local function add_dotnet_diagnostic(qf_list, seen, file, lnum, col, type, code, msg)
  local key = table.concat({ file, lnum, col, type, code, msg }, '|')
  if seen[key] then
    return
  end

  seen[key] = true
  table.insert(qf_list, {
    filename = vim.fn.fnamemodify(file, ':p'),
    lnum = tonumber(lnum),
    col = tonumber(col),
    text = string.format('%s %s: %s', type:upper(), code, msg),
    type = type:sub(1, 1):upper(),
  })
end

local function strip_ansi(line)
  return line:gsub('\27%[[0-?]*[ -/]*[@-~]', '')
end

local function set_quickfix(qf_list, title)
  vim.fn.setqflist({}, 'r', { title = title, items = qf_list })
end

local function open_quickfix()
  if vim.fn.exists ':Trouble' == 2 then
    vim.cmd 'Trouble quickfix'
  else
    vim.cmd 'copen'
  end
end

local function dotnet_build_async()
  local sln = find_sln_file()
  if not sln then
    print '❌ No .sln file found'
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
        line = strip_ansi(line)
        local file, lnum, col, type, code, msg = string.match(line, '^(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+(%w+)%s*:%s*(.+)$')

        if file and lnum and col and type and code and msg and (type == 'error' or type == 'warning') then
          add_dotnet_diagnostic(qf_list, seen, file, lnum, col, type, code, msg)
        end
      end
    end,

    on_exit = function(_, code)
      if #qf_list > 0 then
        set_quickfix(qf_list, 'dotnet build')
        open_quickfix()
      end

      if code == 0 then
        if #qf_list == 0 then
          print '✅ Build succeeded with no errors or warnings.'
        else
          print '✅ Build succeeded with warnings.'
        end
      else
        print('❌ Build failed with exit code ' .. code)
      end
    end,
  })
end

local function dotnet_test_quickfix_async(cmd)
  local sln = find_sln_file()
  local test_cmd = cmd or { 'dotnet', 'test', sln }
  if not cmd and not sln then
    print '❌ No .sln file found'
    return
  end

  local qf_list = {}
  local seen = {}
  local current_test = nil
  local current_message = nil
  local in_error_message = false
  local run_error_message = nil
  local current_frames = {}

  vim.fn.setqflist({}, 'r') -- clear quickfix first
  if type(test_cmd) == 'string' then
    print('🧪 dotnet test - Running: ' .. test_cmd)
  else
    print('🧪 dotnet test - Running: ' .. table.concat(test_cmd, ' '))
  end

  local function add_test_failure(file, lnum, msg)
    local key = table.concat({ file, lnum, msg }, '|')
    if seen[key] then
      return
    end

    seen[key] = true
    table.insert(qf_list, {
      filename = vim.fn.fnamemodify(file, ':p'),
      lnum = tonumber(lnum),
      col = 1,
      text = msg,
      type = 'E',
    })
  end

  local function add_test_failure_without_location(msg)
    local key = 'no-location|' .. msg
    if seen[key] then
      return
    end

    seen[key] = true
    table.insert(qf_list, {
      text = msg,
      type = 'E',
    })
  end

  local function trim_test_name(test_name)
    if not test_name then
      return nil
    end

    return vim.trim(test_name:gsub('%s*%[%d+%s*ms%]%s*$', ''))
  end

  local function current_failure_message(test_name, message)
    local failure = test_name and ('FAILED ' .. test_name) or 'FAILED test'
    if message then
      failure = failure .. ': ' .. message
    end

    return failure
  end

  local function test_name_matches_file(frame)
    if not current_test or not frame.file then
      return false
    end

    local class_name = current_test:match '%.([^%.]+)%.[^%.]+$'
    if not class_name then
      return false
    end

    return vim.fn.fnamemodify(frame.file, ':t:r') == class_name
  end

  local function is_test_project_file(frame)
    return frame.file and frame.file:match('%.Tests/')
  end

  local function best_failure_frame()
    for _, frame in ipairs(current_frames) do
      if test_name_matches_file(frame) then
        return frame
      end
    end

    for _, frame in ipairs(current_frames) do
      if is_test_project_file(frame) then
        return frame
      end
    end

    return current_frames[1]
  end

  local function flush_current_failure()
    if not current_test then
      current_frames = {}
      current_message = nil
      return
    end

    local frame = best_failure_frame()
    local message = current_failure_message(current_test, current_message)
    if frame then
      add_test_failure(frame.file, frame.lnum, message)
    else
      add_test_failure_without_location(message)
    end

    current_test = nil
    current_message = nil
    current_frames = {}
  end

  local function parse_line(line)
    line = strip_ansi(line)
    local file, lnum, col, type, code, msg = string.match(line, '^(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+(%w+)%s*:%s*(.+)$')
    if file and lnum and col and type and code and msg and (type == 'error' or type == 'warning') then
      add_dotnet_diagnostic(qf_list, seen, file, lnum, col, type, code, msg)
      return
    end

    local failed_test = trim_test_name(string.match(line, '^%s*Failed%s+(.+)$'))
    if failed_test then
      flush_current_failure()
      current_test = failed_test
      current_message = nil
      current_frames = {}
      in_error_message = false
      return
    end

    if string.match(line, 'The active test run was aborted') or string.match(line, 'Test Run Aborted') then
      run_error_message = vim.trim(line)
      return
    end

    if string.match(line, '^%s*Error Message:%s*$') then
      in_error_message = true
      return
    end

    if string.match(line, '^%s*Stack Trace:%s*$') then
      in_error_message = false
      return
    end

    if in_error_message and not current_message and string.match(line, '%S') then
      current_message = vim.trim(line)
      return
    end

    local stack_file, stack_lnum = string.match(line, '%s+at .- in (.-):line (%d+)')
    if stack_file and stack_lnum then
      table.insert(current_frames, { file = stack_file, lnum = stack_lnum })
    end
  end

  local function parse_lines(data)
    if not data then
      return
    end

    for _, line in ipairs(data) do
      parse_line(line)
    end
  end

  vim.fn.jobstart(test_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      parse_lines(data)
    end,

    on_stderr = function(_, data)
      parse_lines(data)
    end,

    on_exit = function(_, code)
      flush_current_failure()

      if run_error_message and #qf_list == 0 then
        add_test_failure_without_location(run_error_message)
      end

      if code ~= 0 and #qf_list == 0 then
        add_test_failure_without_location('dotnet test failed with exit code ' .. code)
      end

      if #qf_list > 0 then
        set_quickfix(qf_list, 'dotnet test')
        open_quickfix()
      end

      if code == 0 then
        print '✅ Tests passed.'
      else
        print('❌ Tests failed with exit code ' .. code)
      end
    end,
  })
end

_G.DotnetTestQuickfixRun = dotnet_test_quickfix_async

local function dotnet_restore_async()
  local sln = find_sln_file()
  if not sln then
    print '❌ No .sln file found'
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
        print '✅ Restore succeeded.'
      else
        print('❌ Restore failed with exit code ' .. code)
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
