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
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken',
    opts = {
      -- model = 'gpt-4.1',
      model = 'claude-3.7-sonnet',
    },
    vim.keymap.set('n', '<leader>cc', '<cmd>CopilotChatToggle<CR>', { desc = 'Copilot Chat' }),

    -- To use the picker with CopilotChat, type a a command (ex. "#file:") and press TAB
    -- TAB = Trigger/accept completion menu for tokens
  },
}
