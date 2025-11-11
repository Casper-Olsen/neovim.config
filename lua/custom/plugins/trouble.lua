return {
  'folke/trouble.nvim',
  commit = 'bd67efe408d4816e25e8491cc5ad4088e708a69a',
  opts = {
    focus = false,
    auto_close = false,
    auto_preview = false,
    preview = {
      type = 'main',
      -- Preview will always be a real loaded buffer
      scratch = false,
    },
  },
  cmd = 'Trouble',
  keys = {
    {
      '<leader>dt',
      '<cmd>Trouble diagnostics toggle filter = { severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN } }<cr>',
      desc = '[D]iagnostics [T]rouble',
    },
    {
      '<leader>dT',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = 'Buffer [D]iagnostics [T]rouble',
    },
    {
      '<leader>qt',
      '<cmd>Trouble quickfix toggle<cr>',
      desc = '[Q]uick[F]ix Trouble',
    },
    {
      '<leader>qT',
      '<cmd>Trouble quickfix toggle filter.buf=0<cr>',
      desc = 'Buffer [Q]uick[F]ix Trouble',
    },
  },
}
