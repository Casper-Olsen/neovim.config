return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  -- Optional dependency
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    require('nvim-autopairs').setup {}
    -- If you want to automatically add `(` after selecting a function or method
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    local cmp = require 'cmp'

    cmp.event:on('confirm_done', function(event)
      local entry = event.entry:get_completion_item()
      local bufnr = vim.api.nvim_get_current_buf()

      if vim.bo[bufnr].filetype == 'cs' and entry.label and entry.label:match '<.*>' then
        -- Generic method: replace () with <>
        vim.schedule(function()
          local col = vim.fn.col '.'
          local line = vim.fn.getline '.'

          -- remove () if autopairs inserted it
          if line:sub(col, col) == ')' then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<BS><BS>', true, false, true), 'n', true)
          end

          -- insert <> and place cursor inside
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<><Left>', true, false, true), 'i', true)
        end)
      else
        -- Normal functions → fallback to autopairs
        cmp_autopairs.on_confirm_done()(event)
      end
    end)
  end,
}
