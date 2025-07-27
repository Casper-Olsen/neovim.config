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

-- .NET
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

local function dotnet_build_sync()
  local sln = find_sln_file()
  if not sln then
    print '❌ No .sln file found'
    return
  end

  local output = vim.fn.systemlist { 'dotnet', 'build', sln }

  if vim.v.shell_error ~= 0 then
    print('❌ dotnet build failed with exit code ' .. vim.v.shell_error)
  end

  local qf_list = {}
  local seen = {}

  for _, line in ipairs(output) do
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

  vim.fn.setqflist(qf_list, 'r')

  if #qf_list > 0 then
    vim.cmd 'Trouble quickfix'
  else
    print '✅ Build succeeded with no errors or warnings.'
  end
end

local function dotnet_restore_sync()
  local sln = find_sln_file()
  if not sln then
    print '❌ No .sln file found'
    return
  end

  local output = vim.fn.systemlist { 'dotnet', 'restore', sln }

  if vim.v.shell_error ~= 0 then
    print('❌ dotnet restore failed with exit code ' .. vim.v.shell_error)
    for _, line in ipairs(output) do
      print(line)
    end
  else
    print '✅ dotnet restore succeeded.'
  end
end

vim.api.nvim_create_user_command('DotnetBuild', dotnet_build_sync, {})
vim.api.nvim_create_user_command('DotnetRestore', dotnet_restore_sync, {})
