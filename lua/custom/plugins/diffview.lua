return {
  'sindrets/diffview.nvim',
  commit = '4516612fe98ff56ae0415a259ff6361a89419b0a',
  config = function()
    require('diffview').setup {
      use_icons = false,

      vim.keymap.set('n', '<leader>dw', '<cmd>DiffviewOpen<CR>', { desc = '[D]iff[V]iew' }),
      vim.keymap.set('n', '<leader>df', '<cmd>DiffviewFileHistory %<CR>', { desc = '[D]iffview [F]ile history' }),
      vim.keymap.set('n', '<leader>dc', '<cmd>DiffviewClose<CR>', { desc = '[D]iffview [C]lose' }),
    }
  end,
}
