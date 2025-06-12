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
  -- {
  --   'CopilotC-Nvim/CopilotChat.nvim',
  --   branch = 'main',
  --   dependencies = {
  --     { 'zbirenbaum/copilot.lua' },
  --     { 'nvim-lua/plenary.nvim' },
  --   },
  --   event = 'InsertEnter',
  --   cmd = 'CopilotChat',
  --   config = function()
  --     require('CopilotChat').setup()
  --     vim.keymap.set('n', '<leader>cc', '<cmd>CopilotChat<CR>', { desc = 'Copilot Chat' })
  --     vim.keymap.set('v', '<leader>cc', '<cmd>CopilotChat<CR>', { desc = 'Copilot Chat (visual)' })
  --   end,
  -- },
  {
    'olimorris/codecompanion.nvim',
    config = function()
      require('codecompanion').setup {

        vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<CR>', { desc = '[C]odeCompanion [C]hat', noremap = true, silent = true }),
        vim.keymap.set('v', '<leader>cy', '<cmd>CodeCompanionChat Add<CR>', { desc = '[C]odeCompanion Chat [Y]ank (add)', noremap = true, silent = true }),
        vim.keymap.set({ 'n', 'v' }, '<C-a>', '<cmd>CodeCompanionActions<CR>', { desc = '[C]odeCompanion [A]ctions', noremap = true, silent = true }),

        -- Expand 'cc' into 'CodeCompanion' in the command line
        vim.cmd [[cab cc CodeCompanion]],

        strategies = {
          chat = {
            adapter = 'copilot',
          },
          inline = {
            adapter = 'copilot',
          },
        },
      }
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
