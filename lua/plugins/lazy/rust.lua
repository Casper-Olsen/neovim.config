return {
  'mrcjkb/rustaceanvim',
  version = '9.0.5',
  lazy = false,

  config = function()
    vim.g.rustaceanvim = {
      tools = {
        test_executor = 'background',
      },
      server = {
        on_attach = function(_, bufnr)
          -- Code action menu (quick fixes, refactors, etc.)
          vim.keymap.set('n', '<leader>ca', function()
            vim.cmd.RustLsp 'codeAction'
          end, { buffer = bufnr, desc = '[C]ode [A]ction' })

          -- Pick a debuggable target with optional CLI args
          vim.keymap.set('n', '<leader>dp', function()
            vim.ui.input({ prompt = 'Debug args: ' }, function(input)
              -- Esc / cancel → do nothing
              if input == nil then
                return
              end

              local args = {}

              -- split input into args (space-separated)
              if input ~= '' then
                for word in input:gmatch '%S+' do
                  table.insert(args, word)
                end
              end

              vim.cmd.RustLsp(vim.list_extend({ 'debuggables' }, args))
            end)
          end, { buffer = bufnr, desc = '[D]ebug [P]ick (with args)' })

          -- Debug the previously selected debuggable target
          vim.keymap.set('n', '<leader>dP', function()
            vim.cmd.RustLsp { 'debuggables', bang = true }
          end, { buffer = bufnr, desc = '[D]ebug [P]revious Pick' })

          -- Run testables in current context (file/module)
          vim.keymap.set('n', '<leader>tn', function()
            vim.cmd.RustLsp 'testables'
          end, { buffer = bufnr, desc = '[T]est [N]earest' })

          -- Re-run the last executed testables
          vim.keymap.set('n', '<leader>tl', function()
            vim.cmd.RustLsp { 'testables', bang = true }
          end, { buffer = bufnr, desc = '[T]est [L]ast' })
        end,
      },
    }
  end,
}
