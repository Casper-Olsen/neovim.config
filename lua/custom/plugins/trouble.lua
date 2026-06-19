local function quickfix_mode()
  local qf = vim.fn.getqflist { title = 1 }
  -- Dotnet test failures need a plain-text Trouble formatter.
  return qf.title == 'dotnet test' and 'dotnet_test' or 'quickfix'
end

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
    modes = {
      -- Normal quickfix uses Treesitter highlighting for item text. Dotnet test
      -- output points at .cs files, but the output itself is not valid C#.
      dotnet_test = {
        desc = 'dotnet test failures',
        source = 'qf.qflist',
        events = {
          'QuickFixCmdPost',
          { event = 'TextChanged', main = true },
        },
        groups = {
          { 'filename', format = '{file_icon} {filename} {count}' },
        },
        sort = { 'severity', 'filename', 'pos', 'message' },
        -- Use {text}, not {text:ts}; test output is not valid C#.
        format = '{severity_icon|item.type:DiagnosticSignWarn} {text} {pos}',
      },
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
      function()
        local trouble = require 'trouble'
        local opts = { mode = quickfix_mode() }
        if trouble.is_open(opts) then
          trouble.close(opts)
          return
        end

        trouble.open(opts)
        vim.defer_fn(function()
          trouble.fold_close_all(opts)
        end, 50)
      end,
      desc = '[Q]uick[F]ix Trouble',
    },
    {
      '<leader>qT',
      '<cmd>Trouble quickfix toggle filter.buf=0<cr>',
      desc = 'Buffer [Q]uick[F]ix Trouble',
    },
  },
}
