return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gm', '<cmd>Gvdiffsplit!<CR>', { desc = '[G]it 3-way [M]erge' })
    vim.keymap.set('n', '<leader>gh', '<cmd>diffget //2<CR>', { desc = '[G]it take OURS (//2)' })
    vim.keymap.set('n', '<leader>gl', '<cmd>diffget //3<CR>', { desc = '[G]it take THEIRS (//3)' })
  end,
}
