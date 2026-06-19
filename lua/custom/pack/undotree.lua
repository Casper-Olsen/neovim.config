vim.keymap.set('n', '<leader>ut', function()
  vim.cmd.packadd 'nvim.undotree'
  require('undotree').open()
end, { desc = '[U]ndotree [T]oggle' })
