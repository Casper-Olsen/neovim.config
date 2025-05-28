-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Quickfix
vim.keymap.set('n', '<M-j>', '<cmd>cnext<CR>', { desc = 'Quickfix Next' })
vim.keymap.set('n', '<M-k>', '<cmd>cprev<CR>', { desc = 'Quickfix Previous' })

-- Lua
vim.keymap.set('n', '<leader><leader>x', '<cmd>source %<CR>', { desc = 'Source file' })
vim.keymap.set('n', '<leader>x', ':.lua<CR>', { desc = 'Execute line' })
vim.keymap.set('v', '<leader>x', ':lua<CR>', { desc = 'Execute visual' })

--
vim.keymap.set('n', '<leader>va', 'GVgg', { desc = '[V]isual select [A]ll' })

-- NOTE: Some terminals have coliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Make
function SetReleaseBuild()
  vim.opt.makeprg = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build'
  print 'Build type set to: Release'
end

function SetDebugBuild()
  vim.opt.makeprg = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Debug && cmake --build build'
  print 'Build type set to: Debug'
end

vim.api.nvim_create_user_command('MakeRelease', SetReleaseBuild, {})
vim.api.nvim_create_user_command('MakeDebug', SetDebugBuild, {})

-- Dotnet build
local function find_sln_file(start_path)
  local uv = vim.loop
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
    path = uv.fs_realpath(path .. '/..') or ''
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
    vim.cmd 'copen'
  else
    print '✅ Build succeeded with no errors or warnings.'
  end
end

vim.api.nvim_create_user_command('DotnetBuild', dotnet_build_sync, {})

-- vim: ts=2 sts=2 sw=2 et
