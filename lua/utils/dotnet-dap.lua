local M = {}

local current_debug_test = {
  bufnr = nil,
  job_id = nil,
}

-- Keep only one pending "dotnet test" debug run alive at a time.
local function cleanup_debug_test(stop_job)
  if stop_job and current_debug_test.job_id then
    local status = vim.fn.jobwait({ current_debug_test.job_id }, 0)[1]
    if status == -1 then
      vim.fn.jobstop(current_debug_test.job_id)
    end
  end

  if current_debug_test.bufnr and vim.api.nvim_buf_is_valid(current_debug_test.bufnr) then
    vim.api.nvim_buf_delete(current_debug_test.bufnr, { force = true })
  end

  current_debug_test.bufnr = nil
  current_debug_test.job_id = nil
end

-- Walk upward until the nearest directory containing a .csproj is found.
function M.find_project_root_by_csproj(start_path)
  local Path = require 'plenary.path'
  local path = Path:new(start_path)

  while true do
    local csproj_files = vim.fn.glob(path:absolute() .. '/*.csproj', false, true)
    if #csproj_files > 0 then
      return path:absolute()
    end

    local parent = path:parent()
    if parent:absolute() == path:absolute() then
      return nil
    end

    path = parent
  end
end

function M.find_csproj_path(start_path)
  local project_root = M.find_project_root_by_csproj(start_path)
  if not project_root then
    return nil, nil
  end

  local csproj_files = vim.fn.glob(project_root .. '/*.csproj', false, true)
  if #csproj_files == 0 then
    return nil, project_root
  end

  return csproj_files[1], project_root
end

-- Pick the highest target framework folder from bin/Debug.
function M.get_highest_net_folder(bin_debug_path)
  local dirs = vim.fn.glob(bin_debug_path .. '/net*', false, true)

  if #dirs == 0 then
    error('No netX.Y folders found in ' .. bin_debug_path)
  end

  table.sort(dirs, function(a, b)
    local ver_a = tonumber(a:match 'net(%d+)%.%d+')
    local ver_b = tonumber(b:match 'net(%d+)%.%d+')
    return ver_a > ver_b
  end)

  return dirs[1]
end

-- Build the current project's Debug DLL path for normal launch debugging.
function M.build_dll_path()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':p:h')

  local csproj_path, project_root = M.find_csproj_path(current_dir)
  if not csproj_path or not project_root then
    error 'Could not find project root (no .csproj found)'
  end

  local project_name = vim.fn.fnamemodify(csproj_path, ':t:r')
  local bin_debug_path = project_root .. '/bin/Debug'
  local highest_net_folder = M.get_highest_net_folder(bin_debug_path)
  local dll_path = highest_net_folder .. '/' .. project_name .. '.dll'

  return dll_path
end

local function get_line(bufnr, line_num)
  return vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
end

local function find_namespace(bufnr, method_line)
  for line_num = method_line, 1, -1 do
    local line = get_line(bufnr, line_num)
    if line then
      local file_scoped_namespace = line:match '^%s*namespace%s+([%w_%.]+)%s*;'
      if file_scoped_namespace then
        return file_scoped_namespace
      end

      local block_scoped_namespace = line:match '^%s*namespace%s+([%w_%.]+)%s*{?%s*$'
      if block_scoped_namespace then
        return block_scoped_namespace
      end
    end
  end

  return nil
end

local function find_class(bufnr, method_line)
  for line_num = method_line, 1, -1 do
    local line = get_line(bufnr, line_num)
    if line then
      local class_name = line:match '^%s*[%w%s]*class%s+([%w_]+)'
      if class_name then
        return class_name
      end
    end
  end

  return nil
end

local function is_test_attribute(line)
  if not line:match '^%s*%[' then
    return false
  end

  return line:match '%f[%w]Fact%f[%W]'
    or line:match '%f[%w]Theory%f[%W]'
    or line:match '%f[%w]Test%f[%W]'
    or line:match '%f[%w]TestCase%f[%W]'
    or line:match '%f[%w]TestMethod%f[%W]'
    or line:match '%f[%w]DataTestMethod%f[%W]'
end

function M.find_nearest_xunit_test()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local method_pattern = '([%a_][%w_]*)%s*%('

  -- Search upward for the closest supported test attribute, then read the
  -- following method declaration to build an exact FullyQualifiedName filter.
  for line_num = cursor_line, 1, -1 do
    local line = get_line(bufnr, line_num)

    if line and is_test_attribute(line) then
      for look_down = line_num + 1, math.min(line_num + 8, vim.api.nvim_buf_line_count(bufnr)) do
        local next_line = get_line(bufnr, look_down)
        if next_line then
          if not next_line:match '^%s*%[' then
            local method_name = next_line:match(method_pattern)
            if method_name then
              local namespace = find_namespace(bufnr, look_down)
              local class_name = find_class(bufnr, look_down)
              local full_name = class_name and (class_name .. '.' .. method_name) or method_name

              if namespace then
                full_name = namespace .. '.' .. full_name
              end

              return {
                method = method_name,
                class = class_name,
                namespace = namespace,
                full_name = full_name,
              }
            end
          end
        end
      end
    end
  end

  return nil
end

function M.debug_nearest_test()
  local dotnet_executable = vim.fn.exepath 'dotnet'
  if dotnet_executable == '' then
    vim.notify('Could not find dotnet executable', vim.log.levels.ERROR)
    return
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':p:h')
  local csproj_path, project_root = M.find_csproj_path(current_dir)

  if not csproj_path or not project_root then
    vim.notify('Could not find .csproj for current buffer', vim.log.levels.ERROR)
    return
  end

  local test = M.find_nearest_xunit_test()
  if not test then
    vim.notify('Could not find a test above the cursor', vim.log.levels.ERROR)
    return
  end

  local command = {
    dotnet_executable,
    'test',
    csproj_path,
    '--configuration',
    'Debug',
    '--filter',
    'FullyQualifiedName=' .. test.full_name,
  }

  -- VSTEST_HOST_DEBUG makes dotnet test print the testhost PID and wait for a
  -- debugger; once the PID appears in the output, nvim-dap can attach to it.
  cleanup_debug_test(true)

  local bufnr = vim.api.nvim_create_buf(false, true)
  current_debug_test.bufnr = bufnr

  vim.bo[bufnr].bufhidden = 'wipe'
  vim.bo[bufnr].buftype = 'nofile'
  vim.bo[bufnr].filetype = 'dotnet-test'

  local function append(lines)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    local output = {}
    for _, line in ipairs(lines) do
      if line ~= '' then
        table.insert(output, line)
      end
    end

    if #output == 0 then
      return
    end

    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, output)
  end

  append {
    'Running: ' .. table.concat(command, ' '),
    'Waiting for VSTest testhost PID...',
    '',
  }

  local attached = false
  local output_buffer = ''

  local function handle_output(_, data)
    if not data then
      return
    end

    -- PID output can be split across stdout/stderr chunks, so keep the full
    -- stream seen so far instead of matching only the latest callback data.
    output_buffer = output_buffer .. table.concat(data, '\n')
    local pid = output_buffer:match '[Pp]rocess%s+[Ii]d:%s*(%d+)'

    vim.schedule(function()
      append(data)

      if pid and not attached then
        attached = true
        append { '', 'Attaching debugger to testhost process ' .. pid .. '...' }
        require('dap').run {
          type = 'coreclr',
          name = 'Debug nearest test: ' .. test.method,
          request = 'attach',
          processId = tonumber(pid),
          justMyCode = false,
        }
      end
    end)
  end

  local job_id = vim.fn.jobstart(command, {
    cwd = project_root,
    env = {
      DOTNET_CLI_TELEMETRY_OPTOUT = '1',
      DOTNET_CLI_TELEMETRY_OUTPUT = '0',
      VSTEST_HOST_DEBUG = '1',
    },
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = handle_output,
    on_stderr = handle_output,
    on_exit = function(_, code)
      vim.schedule(function()
        if not attached then
          append { '', 'dotnet test exited before a testhost PID was found.' }
        end

        append { '', 'dotnet test exited with code ' .. code }
        cleanup_debug_test(false)
      end)
    end,
  })

  if job_id <= 0 then
    cleanup_debug_test(false)
    vim.notify('Failed to start dotnet test', vim.log.levels.ERROR)
    return
  end

  current_debug_test.job_id = job_id
end

return M
