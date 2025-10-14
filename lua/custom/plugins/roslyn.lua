return {
  'seblyng/roslyn.nvim',
  -- Important! Don't lazy load roslyn.nvim since it can lead to "weird things" happening. E.g. timing issues
  config = function()
    require('roslyn').setup {
      filewatching = 'roslyn',

      -- Use `:Roslyn target` to change the target .sln
      lock_target = false,

      ignore_target = function(target)
        return string.match(target, '%.CI%.sln$') ~= nil
      end,
    }

    vim.keymap.set('n', '<leader>rr', '<cmd>Roslyn restart<CR>', { desc = '[R]oslyn [R]estart' })

    vim.keymap.set('n', '<leader>rt', '<cmd>Roslyn target<CR>', { desc = '[R]oslyn [T]arget' })
  end,
}
