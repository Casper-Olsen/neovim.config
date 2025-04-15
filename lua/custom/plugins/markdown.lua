return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  config = function()
    require('render-markdown').setup {
      enabled = false,
      completions = { lsp = { enabled = true } },

      vim.keymap.set('n', '<leader>me', function()
        require('render-markdown').enable()
      end, { desc = '[M]arkdown [E]nable' }),

      vim.keymap.set('n', '<leader>md', function()
        require('render-markdown').disable()
      end, { desc = '[M]arkdown [D]isable' }),
    }
  end,
}
