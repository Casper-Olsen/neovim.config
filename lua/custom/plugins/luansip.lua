return {
  'L3MON4D3/LuaSnip',
  version = 'v2.4.1',
  build = 'make install_jsregexp',
  config = function()
    local snippet_path = vim.fn.stdpath 'config' .. '/snippets'
    print('LuaSnip loading snippets from: ' .. snippet_path)
    require('luasnip.loaders.from_vscode').lazy_load { paths = { snippet_path } }
    -- require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snippets' } }
  end,
}
