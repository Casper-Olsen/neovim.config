return {
  'vim-test/vim-test',
  dependencies = { 'preservim/vimux' },

  config = function()
    vim.keymap.set('n', '<leader>te', function()
      vim.cmd 'TestNearest -strategy=sudo_vimux'
    end, { desc = '[T]est [N]earest [E]levated' })

    vim.keymap.set('n', '<leader>tn', '<cmd>TestNearest<CR>', { desc = '[T]est [N]earest' })
    vim.keymap.set('n', '<leader>tf', '<cmd>TestFile<CR>', { desc = '[T]est [F]ile' })
    vim.keymap.set('n', '<leader>ts', '<cmd>TestSuite<CR>', { desc = '[T]est [S]uite' })
    vim.keymap.set('n', '<leader>tl', '<cmd>TestLast<CR>', { desc = '[T]est [L]ast' })
    vim.keymap.set('n', '<leader>tv', '<cmd>TestVisit<CR>', { desc = '[T]est [V]isit' })

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
}
