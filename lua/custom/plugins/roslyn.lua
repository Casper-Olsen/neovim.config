return {
  'seblyng/roslyn.nvim',
  ft = 'cs',
  opts = {},
  config = function()
    require('roslyn').setup {
      vim.keymap.set('n', '<leader>rr', '<cmd>Roslyn restart<CR>', { desc = '[R]oslyn [R]estart' }),
    }
  end,
}
