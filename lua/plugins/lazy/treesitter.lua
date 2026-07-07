return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local parsers = {
        'bash',
        'c',
        'rust',
        'c_sharp',
        'diff',
        'gitcommit',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'terraform',
        'vim',
        'vimdoc',
        'yaml',
      }

      require('nvim-treesitter').install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'sh',
          'c',
          'rust',
          'cs',
          'diff',
          'gitcommit',
          'html',
          'lua',
          'markdown',
          'python',
          'query',
          'terraform',
          'terraform-vars',
          'vim',
          'help',
          'yaml',
          'yaml.*',
        },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
