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
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
      }

      require('nvim-treesitter').install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'sh', 'c', 'rust', 'cs', 'diff', 'html', 'lua', 'markdown', 'query', 'vim', 'help' },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
