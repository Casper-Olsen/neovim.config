return {
  'windwp/nvim-autopairs',
  version = '0.10.0',
  event = 'InsertEnter',
  -- Optional dependency
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    require('nvim-autopairs').setup {}
    -- If you want to automatically add `(` after selecting a function or method
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    local cmp = require 'cmp'

    local npairs = require 'nvim-autopairs'
    -- npairs.remove_rule '"'
    -- npairs.remove_rule "'"

    npairs.setup {
      check_ts = true,
      ts_config = {
        csharp = { 'string' },
      },
    }
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  end,
}
