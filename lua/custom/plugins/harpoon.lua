return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup()

    -- basic telescope configuration
    local conf = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table {
            results = file_paths,
          },
          previewer = conf.file_previewer {},
          sorter = conf.generic_sorter {},
        })
        :find()
    end

    vim.keymap.set('n', '<leader>e', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = '[E]dit [P]inned Harpoon' })
    vim.keymap.set('n', '<leader>sp', function()
      toggle_telescope(harpoon:list())
    end, { desc = '[S]earch [P]inned Harpoon' })

    vim.keymap.set('n', '<leader>pa', function()
      harpoon:list():add()
    end, { desc = '[P]inned [A]dd Harpoon' })

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<leader>pn', function()
      harpoon:list():next()
    end, { desc = '[P]inned [N]ext Harpoon' })
    vim.keymap.set('n', '<leader>pp', function()
      harpoon:list():prev()
    end, { desc = '[P]inned [P]revious Harpoon' })

    -- vim.keymap.set('n', '<C-h>', function()
    --   harpoon:list():select(1)
    -- end)
    -- vim.keymap.set('n', '<C-t>', function()
    --   harpoon:list():select(2)
    -- end)
    -- vim.keymap.set('n', '<C-n>', function()
    --   harpoon:list():select(3)
    -- end)
    -- vim.keymap.set('n', '<C-s>', function()
    --   harpoon:list():select(4)
    -- end)
  end,
}
