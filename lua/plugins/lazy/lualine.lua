return {
  'nvim-lualine/lualine.nvim',
  commit = '221ce6b2d999187044529f49da6554a92f740a96',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup {
      options = {
        theme = 'onedark', -- change to your preferred theme
      },

      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = {},
        lualine_z = { 'location' },
      },
    }
  end,
}
