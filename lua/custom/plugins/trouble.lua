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
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = '[D]iagnostics [T]rouble',
    },
    {
      '<leader>dT',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = 'Buffer [D]iagnostics [T]rouble',
    },
  },
}
