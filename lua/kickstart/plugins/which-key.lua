-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
--
-- This is often very useful to both group configuration, as well as handle
-- lazy loading plugins that don't need to be loaded immediately at startup.
--
-- For example, in the following configuration, we use:
--  event = 'VimEnter'
--
-- which loads which-key before all the UI elements are loaded. Events can be
-- normal autocommands events (`:help autocmd-events`).
--
-- Then, because we use the `opts` key (recommended), the configuration runs
-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.opt.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode & [C]odeCompanion & [C]opilot', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument & [D]ebug & [D]iagnostic & [D]iff' },
        { '<leader>r', group = '[R]ename & [R]oslyn' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle & [T]est' },
        { '<leader>h', group = 'Git [H]unk & [H]over', mode = { 'n', 'v' } },
        { '<leader>m', group = '[M]arkdown' },
        { '<leader>p', group = '[P]inned' },
        { '<leader>v', group = '[V]isual' },
        { '<leader>e', group = '[E]dit pinned' },
        { '<leader>g', group = '[G]it' },
        { '<leader>q', group = '[Q]uickfix' },
        { '<leader>y', group = '[Y]ank' },
        { '<leader>a', group = '[A]lternate file' },
        { '<leader>u', group = '[U]ndo' },
        { '<leader>z', group = '[Z]en mode' },
        { '<leader>b', group = '[B]uild' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
