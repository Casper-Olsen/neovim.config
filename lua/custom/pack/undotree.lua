vim.cmd.packadd 'nvim.undotree'

vim.keymap.set('n', '<leader>ut', function()
  vim.cmd.Undotree()
end, { desc = '[U]ndotree [T]oggle' })
