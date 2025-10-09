return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'Issafalcon/neotest-dotnet',
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require 'neotest-dotnet' {
            dap = {
              args = { justMyCode = false },
              adapter_name = 'netcoredbg',
            },
          },
        },
      }

      vim.keymap.set('n', '<leader>tn', function()
        require('neotest').run.run()
      end, { desc = '[T]est [N]earest' })

      vim.keymap.set('n', '<leader>tf', function()
        require('neotest').run.run(vim.fn.expand '%')
      end, { desc = '[T]est [F]ile' })

      vim.keymap.set('n', '<leader>td', function()
        require('neotest').run.run { strategy = 'dap', suite = false }
      end, { desc = '[T]est [D]ebug' })

      vim.keymap.set('n', '<leader>te', function()
        require('neotest').run.stop()
      end, { desc = '[T]est [E]nd' })

      vim.keymap.set('n', '<leader>tp', function()
        require('neotest').output_panel.toggle()
      end, { desc = '[T]est Output [P]anel' })

      -- Exit the output window by moving to another window (ctrl + h/j/k/l)
      vim.keymap.set('n', '<leader>to', function()
        require('neotest').output.open { enter = true, last_run = true, auto_close = true }
      end, { desc = '[T]est [O]utput' })

      vim.keymap.set('n', '<leader>ts', function()
        require('neotest').summary.toggle()
      end, { desc = '[T]est [S]ummary' })
    end,
  },
  {
    'vim-test/vim-test',
    dependencies = { 'preservim/vimux' },

    config = function()
      vim.keymap.set('n', '<leader>tte', function()
        vim.cmd 'TestNearest -strategy=sudo_vimux'
      end, { desc = '[T]est Nearest [T]mux [E]levated' })

      vim.keymap.set('n', '<leader>ttn', '<cmd>TestNearest<CR>', { desc = '[T]est [T]mux [N]earest' })
      vim.keymap.set('n', '<leader>ttf', '<cmd>TestFile<CR>', { desc = '[T]est [T]mux [F]ile' })
      vim.keymap.set('n', '<leader>ttl', '<cmd>TestLast<CR>', { desc = '[T]est [T]mux [L]ast' })

      vim.g['test#csharp#runner'] = 'dotnettest'
      vim.g['test#strategy'] = 'vimux'

      vim.g['test#custom_strategies'] = {
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
