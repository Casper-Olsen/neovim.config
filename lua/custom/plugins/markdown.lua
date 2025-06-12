return {
  {
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
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    ft = { 'markdown', 'codecompanion' },
    config = function()
      vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { desc = '[M]arkdown [P]review' })
    end,
  },
}
