return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    build = ':Copilot auth',
    config = function()
      require('copilot').setup {
        suggestion = { enabled = false },
        panel = { enabled = false },
        auto_trigger = { enabled = false },
      }
    end,
    vim.keymap.set({ 'n' }, '<leader>ce', '<cmd>Copilot enable<CR>', { desc = '[C]opilot [E]nable', noremap = true, silent = true }),
    vim.keymap.set({ 'n' }, '<leader>cd', '<cmd>Copilot disable<CR>', { desc = '[C]opilot [D]isable', noremap = true, silent = true }),
  },
  {
    'zbirenbaum/copilot-cmp',
    config = function()
      require('copilot_cmp').setup()
    end,
  },
  {
    'olimorris/codecompanion.nvim',
    version = 'v16.3.0',
    config = function()
      require('codecompanion').setup {

        vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<CR>', { desc = '[C]odeCompanion [C]hat', noremap = true, silent = true }),
        vim.keymap.set('v', '<leader>cy', '<cmd>CodeCompanionChat<CR>', { desc = '[C]odeCompanion Chat [Y]ank (add)', noremap = true, silent = true }),
        vim.keymap.set({ 'n', 'v' }, '<leader>cA', '<cmd>CodeCompanionActions<CR>', { desc = '[C]odeCompanion [A]ctions', noremap = true, silent = true }),

        -- Expand 'cc' into 'CodeCompanion' in the command line
        vim.cmd [[cab cc CodeCompanion]],

        strategies = {
          chat = {
            adapter = {
              name = 'copilot',
              -- model = 'gpt-4.1',
              model = 'claude-3.7-sonnet',
            },
          },
          inline = {
            adapter = {
              name = 'copilot',
              -- model = 'gpt-4.1',
              model = 'claude-3.7-sonnet',
            },
          },
        },
        display = {
          action_palette = {
            show_default_prompt_library = true,
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
