return {
  'seblyng/roslyn.nvim',
  commit = 'f64609e4ab21a4cc28af2f526974c961d6adacca', -- Works with Neovim 0.10
  ft = 'cs',
  opts = {},
  config = function()
    require('roslyn').setup {
      vim.keymap.set('n', '<leader>rr', '<cmd>Roslyn restart<CR>', { desc = '[R]oslyn [R]estart' }),
    }
  end,
}
