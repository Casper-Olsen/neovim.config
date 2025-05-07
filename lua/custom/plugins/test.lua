return {
  'vim-test/vim-test',
  dependencies = {
    'preservim/vimux',
  },

  vim.keymap.set('n', '<leader>tn', '<cmd>TestNearest<CR>', { desc = '[T]est [N]earest' }),
  vim.keymap.set('n', '<leader>tf', '<cmd>TestFile<CR>', { desc = '[T]est [F]ile' }),
  vim.keymap.set('n', '<leader>ts', '<cmd>TestSuite<CR>', { desc = '[T]est [S]uite' }),
  vim.keymap.set('n', '<leader>tl', '<cmd>TestLast<CR>', { desc = '[T]est [L]ast' }),
  vim.keymap.set('n', '<leader>tv', '<cmd>TestVisit<CR>', { desc = '[T]est [V]isit' }),

  vim.cmd "let test#csharp#runner = 'dotnettest'",
  vim.cmd "let test#strategy = 'vimux'",

  -- Not tested if it works yet
  vim.g['test#custom_strategies']
    == {
      dap_debug = function(cmd)
        local dap = require 'dap'
        dap.run {
          type = 'cppdbg',
          request = 'launch',
          name = 'Debug Test',
          program = cmd[2],
          args = { unpack(cmd, 3) },
          cwd = vim.fn.getcwd(),
          stopOnEntry = false,
        }
      end,
    },

  vim.api.nvim_set_keymap('n', '<leader>tdn', ':TestNearest -strategy=dap_debug<CR>', { noremap = true, silent = true }),
}
