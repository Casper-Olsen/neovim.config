return {
  {
    'tpope/vim-fugitive',
    commit = '61b51c09b7c9ce04e821f6cf76ea4f6f903e3cf4',
    config = function()
      vim.keymap.set('n', '<leader>gs', '<cmd>Git<CR>', { desc = '[G]it [S]tatus' })
      vim.keymap.set('n', '<leader>gx', '<cmd>Git push<CR>', { desc = '[G]it [P]ush' })

      vim.keymap.set('n', '<leader>gm', '<cmd>Gvdiffsplit!<CR>', { desc = '[G]it 3-way [M]erge' })
      vim.keymap.set('n', '<leader>gh', '<cmd>diffget //2<CR>', { desc = '[G]it take CURRENT branch (//2)' })
      vim.keymap.set('n', '<leader>gl', '<cmd>diffget //3<CR>', { desc = '[G]it take INCOMING branch (//3)' })
      vim.keymap.set('n', '<leader>gn', '/\\v^[<|=]{7}( .*)?$<CR>', { desc = '[G]it NEXT conflict' })
      vim.keymap.set('n', '<leader>gp', '?\\v^[<|=]{7}( .*)?$<CR>', { desc = '[G]it PREV conflict' })
    end,
  },
  {
    'tpope/vim-rhubarb',
  },
}
