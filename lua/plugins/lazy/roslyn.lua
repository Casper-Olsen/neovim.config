return {
  'seblyng/roslyn.nvim',
  commit = '9c5da79216e5776e020dcc6c157983f5352f3f11',
  -- Important! Don't lazy load roslyn.nvim since it can lead to "weird things" happening. E.g. timing issues
  config = function()
    require('roslyn').setup {
      filewatching = 'roslyn',

      -- Use `:Roslyn target` to change the target .sln
      lock_target = false,

      ignore_target = function(target)
        return string.match(target, '%.CI%.sln$') ~= nil
      end,
    }

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('dotnet-keymaps', { clear = true }),
      pattern = 'cs',
      callback = function(event)
        vim.keymap.set('n', '<leader>b', '<cmd>DotnetBuildAsync<CR>', { buffer = event.buf, desc = '[B]uild dotnet project' })
        vim.keymap.set('n', '<leader>rt', '<cmd>Roslyn target<CR>', { buffer = event.buf, desc = '[R]oslyn [T]arget' })
        vim.keymap.set('n', '<leader>tn', '<cmd>TestNearest -strategy=quickfix_dotnet<CR>', { buffer = event.buf, desc = '[T]est [N]earest' })
        vim.keymap.set('n', '<leader>tdn', function()
          require('utils.dotnet-dap').debug_nearest_test()
        end, { buffer = event.buf, desc = '[T]est [D]ebug [N]earest' })
      end,
    })

    -- Roslyn uses LSP pull diagnostics (`textDocument/diagnostic`). After changing
    -- a C# symbol in one buffer, other already-open buffers can keep stale
    -- diagnostics until Neovim asks Roslyn for them again. In Neovim 0.12, use
    -- `vim.lsp.diagnostic._refresh` to refresh those diagnostics when
    -- entering/leaving insert mode in C# files.
    vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufEnter' }, {
      group = vim.api.nvim_create_augroup('roslyn-refresh-diagnostics', { clear = true }),
      pattern = '*.cs',
      callback = function()
        local refresh = vim.lsp.diagnostic and vim.lsp.diagnostic._refresh
        if type(refresh) ~= 'function' then
          vim.notify('Roslyn diagnostic refresh is unavailable in this Neovim version', vim.log.levels.WARN)
          return
        end

        for _, client in ipairs(vim.lsp.get_clients { name = 'roslyn' }) do
          for bufnr in pairs(client.attached_buffers) do
            refresh(bufnr, client.id)
          end
        end
      end,
    })
  end,
}
