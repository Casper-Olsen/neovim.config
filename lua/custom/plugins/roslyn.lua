return {
  'seblyng/roslyn.nvim',
  ft = 'cs',
  config = function()
    require('roslyn').setup {
      filewatching = 'roslyn',
    }

    vim.keymap.set('n', '<leader>rr', '<cmd>Roslyn restart<CR>', { desc = '[R]oslyn [R]estart' })
  end,
}
