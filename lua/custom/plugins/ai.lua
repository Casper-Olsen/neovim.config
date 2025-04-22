return {
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    cmd = 'Copilot',
    build = ':Copilot auth',
    config = function()
      require('copilot').setup {
        suggestion = { enabled = false },
        panel = { enabled = false },
      }
    end,
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    dependencies = {
      { 'zbirenbaum/copilot.lua' },
      { 'nvim-lua/plenary.nvim' },
    },
    event = 'InsertEnter',
    cmd = 'CopilotChat',
    config = function()
      require('CopilotChat').setup()
      vim.keymap.set('n', '<leader>cc', '<cmd>CopilotChat<CR>', { desc = 'Copilot Chat' })
      vim.keymap.set('v', '<leader>cc', '<cmd>CopilotChat<CR>', { desc = 'Copilot Chat (visual)' })
    end,
  },
}
