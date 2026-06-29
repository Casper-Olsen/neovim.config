return {
  {
    'vim-test/vim-test',
    commit = '2676d84c6901e484df00b5d728bd6a345d47ee12',
    dependencies = { 'preservim/vimux' },

    config = function()
      vim.keymap.set('n', '<leader>tte', function()
        vim.cmd 'TestNearest -strategy=sudo_vimux'
      end, { desc = '[T]est Nearest [T]mux [E]levated' })

      vim.keymap.set('n', '<leader>tn', '<cmd>TestNearest -strategy=quickfix_dotnet<CR>', { desc = '[T]est [N]earest' })
      vim.keymap.set('n', '<leader>ttn', '<cmd>TestNearest<CR>', { desc = '[T]est [T]mux [N]earest' })
      vim.keymap.set('n', '<leader>ttf', '<cmd>TestFile<CR>', { desc = '[T]est [T]mux [F]ile' })
      vim.keymap.set('n', '<leader>tl', '<cmd>TestLast<CR>', { desc = '[T]est [L]ast' })

      vim.g['test#csharp#runner'] = 'dotnettest'
      vim.g['test#strategy'] = 'vimux'

      vim.g['test#custom_strategies'] = {
        quickfix_dotnet = function(cmd)
          require('utils.dotnet-test').run(cmd)
        end,
        sudo_vimux = function(cmd)
          if type(cmd) == 'string' then
            cmd = { cmd }
          end

          vim.fn['VimuxRunCommand']('sudo ' .. table.concat(cmd, ' '))
        end,
      }
    end,
  },
}
