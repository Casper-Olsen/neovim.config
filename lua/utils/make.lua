-- Make
local function SetReleaseBuild()
  vim.opt.makeprg = 'cmake --preset=release && cmake --build --preset=release'
  print 'Build type set to: Release with vcpkg'
end

local function SetDebugBuild()
  vim.opt.makeprg = 'cmake --preset=debug && cmake --build --preset=debug'
  print 'Build type set to: Debug with vcpkg'
end

vim.api.nvim_create_user_command('MakeRelease', SetReleaseBuild, {})
vim.api.nvim_create_user_command('MakeDebug', SetDebugBuild, {})
