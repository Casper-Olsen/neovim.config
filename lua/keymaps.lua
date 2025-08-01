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

-- Select all
vim.keymap.set('n', '<leader>va', 'GVgg', { desc = '[V]isual select [A]ll' })

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

-- Copy most recent yank ("0) to system clipboard ("+ and "*)
local function yank_to_clipboard()
  local yanked = vim.fn.getreg '0'
  vim.fn.setreg('+', yanked)
end

vim.keymap.set('n', '<leader>yc', yank_to_clipboard, { desc = 'Copy [Y]anked to [C]lipboard' })

-- Alternate file
vim.keymap.set('n', '<leader>a', '<C-^>', { desc = '[A]lternate file' })

-- Delete line to black hole register
vim.keymap.set('n', '<leader>dd', '"_dd', { desc = '[D]elete line to black hole register' })

-- Build
vim.keymap.set('n', '<leader>bd', function()
  vim.cmd 'echo "🛠️ dotnet build - Running"'
  vim.cmd 'DotnetBuildAsync'
end, { desc = '[B]uild [D]otnet' })
