return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    commit = 'f3df514fff2bdd4318127c40470984137f87b62e',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    lazy = false, -- neo-tree will lazily load itself

    config = function()
      require('neo-tree').setup {
        filesystem = {
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
            hijack_netrw_behavior = 'disabled',
          },
        },
        default_component_configs = {
          file_size = {
            enabled = false,
          },
        },
      }
      -- Use `e` to expand the neo-tree buffer

      vim.keymap.set('n', '<leader>n', '<cmd>Neotree toggle<CR>', { desc = '[N]eotree' })
    end,
  },
}
