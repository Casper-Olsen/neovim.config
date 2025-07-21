return {
  'folke/trouble.nvim',
  opts = {
    focus = false,
    auto_close = false,
  },
  cmd = 'Trouble',
  keys = {
    {
      '<leader>dt',
      function()
        vim.cmd [[Trouble diagnostics toggle filter = { severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN }, filename_not = { "/tmp/", ".nuget" } }]]
      end,
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
