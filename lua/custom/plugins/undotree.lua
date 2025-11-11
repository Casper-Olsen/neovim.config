return {
  'mbbill/undotree',
  commit = '0f1c9816975b5d7f87d5003a19c53c6fd2ff6f7f',
  config = function()
    vim.keymap.set('n', '<leader>ut', vim.cmd.UndotreeToggle, { desc = '[U]ndotree [T]oggle' })
  end,
}
