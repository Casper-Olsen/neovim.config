local utils = require 'utils.dotnet-utils'

local function dotnet_build_async()
  local sln = utils.find_sln_file()
  if not sln then
    print(utils.command_icons.error .. ' No .sln file found')
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
        table.sort(qf_list, function(a, b)
          local a_file = a.filename or ''
          local b_file = b.filename or ''

          if a_file ~= b_file then
            return a_file < b_file
          end

          return (a.lnum or 0) < (b.lnum or 0)
        end)

        vim.fn.setqflist({}, 'r', {
          title = 'dotnet build',
          items = qf_list,
        })

        vim.cmd 'Trouble quickfix'
      end
      if code == 0 then
        if #qf_list == 0 then
          print(utils.command_icons.success .. ' Build succeeded with no errors or warnings.')
        else
          print(utils.command_icons.success .. ' Build succeeded with warnings.')
        end
      else
        print(utils.command_icons.error .. ' Build failed with exit code ' .. code)
      end
    end,
  })
end

vim.api.nvim_create_user_command('DotnetBuildAsync', dotnet_build_async, {})
