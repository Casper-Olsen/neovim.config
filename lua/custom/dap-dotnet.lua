local M = {}

local dap = require 'dap'

-- Wrap dap.run only once to add logging
if not dap._original_run then
  dap._original_run = dap.run
  dap.run = function(config)
    print '[dap.run] called with:'
    for k, v in pairs(config) do
      print('  ' .. k .. ':', type(v) == 'table' and vim.inspect(v) or tostring(v))
    end
    dap._original_run(config)
  end
end

-- Find the root directory of a .NET project by searching for .csproj files
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

-- Find the highest version of the netX.Y folder within a given path.
function M.get_highest_net_folder(bin_debug_path)
  local dirs = vim.fn.glob(bin_debug_path .. '/net*', false, true) -- Get all folders starting with 'net' in bin_debug_path

  if dirs == 0 then
    error('No netX.Y folders found in ' .. bin_debug_path)
  end

  table.sort(dirs, function(a, b) -- Sort the directories based on their version numbers
    local ver_a = tonumber(a:match 'net(%d+)%.%d+')
    local ver_b = tonumber(b:match 'net(%d+)%.%d+')
    return ver_a > ver_b
  end)

  return dirs[1]
end

-- Build and return the full path to the .dll file for debugging.
function M.build_dll_path()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':p:h')

  local project_root = M.find_project_root_by_csproj(current_dir)
  if not project_root then
    error 'Could not find project root (no .csproj found)'
  end

  local csproj_files = vim.fn.glob(project_root .. '/*.csproj', false, true)
  if #csproj_files == 0 then
    error 'No .csproj file found in project root'
  end

  local project_name = vim.fn.fnamemodify(csproj_files[1], ':t:r')
  local bin_debug_path = project_root .. '/bin/Debug'
  local highest_net_folder = M.get_highest_net_folder(bin_debug_path)
  local dll_path = highest_net_folder .. '/' .. project_name .. '.dll'

  return dll_path
end

function M.find_nearest_xunit_test()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Regex to detect [Fact] or [Theory]
  local test_attr_pattern = '^%s*%[Fact%]%s*$'
  local theory_attr_pattern = '^%s*%[Theory%]%s*$'

  -- Matches 'public' method declarations and captures the method name.
  -- Allows modifiers like 'async' and return types before the method name.
  local method_pattern = '^%s*public%s+.*%s+([%w_]+)%s*%('

  -- We'll scan upward from cursor_line to 1
  for line_num = cursor_line, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

    if line and (line:match(test_attr_pattern) or line:match(theory_attr_pattern)) then
      -- Found test attribute, now find method signature below it (within next ~5 lines)
      for look_down = line_num + 1, math.min(line_num + 5, vim.api.nvim_buf_line_count(bufnr)) do
        local next_line = vim.api.nvim_buf_get_lines(bufnr, look_down - 1, look_down, false)[1]
        if next_line then
          local method_name = next_line:match(method_pattern)
          if method_name then
            return method_name
          end
        end
      end
    end
  end

  return nil -- not found
end

return M
