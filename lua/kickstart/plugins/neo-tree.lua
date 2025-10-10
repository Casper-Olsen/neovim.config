return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    lazy = false, -- neo-tree will lazily load itself

    config = function()
      vim.keymap.set('n', '<leader>n', '<cmd>Neotree toggle<CR>', { desc = '[N]eotree' })
    end,
  },
}
