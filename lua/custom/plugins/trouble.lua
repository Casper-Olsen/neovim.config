local function quickfix_mode()
  local qf = vim.fn.getqflist { title = 1 }
  -- Dotnet test failures need a plain-text Trouble formatter.
  return qf.title == 'dotnet test' and 'dotnet_test' or 'quickfix'
end

--- Patch Trouble's follow behavior so dotnet test quickfix entries track the
--- current file group or failing line in the custom plain-text formatter.
local function patch_dotnet_test_follow()
  local view = require 'trouble.view'
  local original_follow = view.follow

  view.follow = function(self)
    if self.opts.mode ~= 'dotnet_test' then
      return original_follow(self)
    end

    if not self.win:valid() or self.moving:is_active() or vim.api.nvim_get_current_win() == self.win.win then
      return
    end

    local filter = require 'trouble.filter'
    local ctx = { opts = self.opts, main = self:main() }
    local fname = vim.api.nvim_buf_get_name(ctx.main.buf or 0)
    local loc = self:at()
    local in_group = loc.node and loc.node.item and loc.node.item.filename == fname
    local cursor_item = nil
    local cursor_group = nil

    for row, location in pairs(self.renderer._locations) do
      local is_group = not in_group and location.node and location.node.group and location.node.item and location.node.item.filename == fname
      if is_group then
        cursor_group = { row, 1 }
      end

      if location.first_line and location.item and filter.is(location.item, { range = true }, ctx) then
        cursor_item = { row, 1 }
      end
    end

    local cursor = cursor_item or cursor_group
    if cursor then
      vim.wo[self.win.win].cursorline = true
      vim.api.nvim_win_set_cursor(self.win.win, cursor)
      return true
    end
  end
end

return {
  'folke/trouble.nvim',
  commit = 'bd67efe408d4816e25e8491cc5ad4088e708a69a',
  config = function(_, opts)
    require('trouble').setup(opts)
    patch_dotnet_test_follow()
  end,
  opts = {
    focus = false,
    auto_close = false,
    auto_preview = false,
    preview = {
      type = 'main',
      -- Preview will always be a real loaded buffer
      scratch = false,
    },
    modes = {
      -- Normal quickfix uses Treesitter highlighting for item text. Dotnet test
      -- output points at .cs files, but the output itself is not valid C#.
      dotnet_test = {
        desc = 'dotnet test failures',
        source = 'qf.qflist',
        events = {
          'QuickFixCmdPost',
          { event = 'TextChanged', main = true },
        },
        groups = {
          { 'filename', format = '{file_icon} {filename} {count}' },
        },
        sort = { 'severity', 'filename', 'pos', 'message' },
        -- Use {text}, not {text:ts}; test output is not valid C#.
        format = '{severity_icon|item.type:DiagnosticSignWarn} {pos} {text}',
      },
    },
  },
  cmd = 'Trouble',
  keys = {
    {
      '<leader>dt',
      '<cmd>Trouble diagnostics toggle filter = { severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN } }<cr>',
      desc = '[D]iagnostics [T]rouble',
    },
    {
      '<leader>dT',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = 'Buffer [D]iagnostics [T]rouble',
    },
    {
      '<leader>qt',
      function()
        local trouble = require 'trouble'
        local opts = { mode = quickfix_mode() }
        if trouble.is_open(opts) then
          trouble.close(opts)
          return
        end

        trouble.open(opts)
        vim.defer_fn(function()
          trouble.fold_close_all(opts)
        end, 50)
      end,
      desc = '[Q]uick[F]ix Trouble',
    },
    {
      '<leader>qT',
      '<cmd>Trouble quickfix toggle filter.buf=0<cr>',
      desc = 'Buffer [Q]uick[F]ix Trouble',
    },
  },
}
