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
        vim.cmd 'Trouble quickfix' -- or use ':copen' if you don't use Trouble
      end

      if code == 0 and #qf_list == 0 then
        print '✅ Build succeeded with no errors or warnings.'
      elseif code ~= 0 then
        print('❌ Build failed with exit code ' .. code)
      end
    end,
  })
end

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
vim.api.nvim_create_user_command('DotnetRestoreAsync', dotnet_restore_async, {})
