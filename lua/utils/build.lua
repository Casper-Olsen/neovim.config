local utils = require 'utils.dotnet-utils'

local build_rules = {
  {
    name = 'dotnet',
    find = utils.find_sln_file,
    run = function()
      vim.cmd 'DotnetBuildAsync'
    end,
  },
}

local function build_async()
  for _, rule in ipairs(build_rules) do
    if rule.find() then
      rule.run()
      return
    end
  end

  print(utils.command_icons.error .. ' No supported build target found')
end

vim.api.nvim_create_user_command('BuildAsync', build_async, {})
