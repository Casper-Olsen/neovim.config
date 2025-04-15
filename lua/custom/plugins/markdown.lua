return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  config = function()
    require('render-markdown').setup {
      enabled = false,
      completions = { lsp = { enabled = true } },
    }
  end,
}
