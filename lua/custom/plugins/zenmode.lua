return {
  'folke/zen-mode.nvim',

  config = function()
    require('zen-mode').setup {
      window = {
        width = 150,
      },
    }
    vim.keymap.set('n', '<leader>zm', '<cmd>ZenMode<CR>', { desc = '[Z]en [M]ode' })
  end,
}
