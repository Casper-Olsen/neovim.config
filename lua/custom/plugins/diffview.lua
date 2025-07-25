return {
  'sindrets/diffview.nvim',

  config = function()
    require('diffview').setup {
      use_icons = false,

      vim.keymap.set('n', '<leader>dw', '<cmd>DiffviewOpen<CR>', { desc = '[D]iff[V]iew' }),
      vim.keymap.set('n', '<leader>df', '<cmd>DiffviewFileHistory %<CR>', { desc = '[D]iffview [F]ile history' }),
      vim.keymap.set('n', '<leader>dc', '<cmd>DiffviewClose<CR>', { desc = '[D]iffview [C]lose' }),
    }
  end,
}
