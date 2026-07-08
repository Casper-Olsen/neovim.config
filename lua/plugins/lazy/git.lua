return {
  {
    'tpope/vim-fugitive',
    commit = '3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0',
    config = function()
      vim.keymap.set('n', '<leader>gs', '<cmd>Git<CR>', { desc = '[G]it [S]tatus' })
      vim.keymap.set('n', '<leader>gx', '<cmd>Git push<CR>', { desc = '[G]it [P]ush' })

      vim.keymap.set('n', '<leader>gm', '<cmd>Gvdiffsplit!<CR>', { desc = '[G]it 3-way [M]erge' })

      vim.keymap.set('n', '<leader>gh', 'd2o', { remap = true, desc = '[G]it take CURRENT hunk (ours)' })
      vim.keymap.set('n', '<leader>gl', 'd3o', { remap = true, desc = '[G]it take INCOMING hunk (theirs)' })
      vim.keymap.set('n', '<leader>gH', '<cmd>Gread :2<CR>', { desc = '[G]it take entire CURRENT conflict (ours)' })
      vim.keymap.set('n', '<leader>gL', '<cmd>Gread :3<CR>', { desc = '[G]it take entire INCOMING conflict (theirs)' })

      vim.keymap.set('n', '<leader>gn', '/\\v^[<|=]{7}( .*)?$<CR>', { desc = '[G]it NEXT conflict' })
      vim.keymap.set('n', '<leader>gp', '?\\v^[<|=]{7}( .*)?$<CR>', { desc = '[G]it PREV conflict' })
    end,
  },
  {
    'tpope/vim-rhubarb',
  },
}
