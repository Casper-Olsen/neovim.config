return {
  {
    'christoomey/vim-tmux-navigator',
    commit = 'c45243dc1f32ac6bcf6068e5300f3b2b237e576a',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<CR>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<CR>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<CR>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<CR>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<CR>' },
    },
  },
}
