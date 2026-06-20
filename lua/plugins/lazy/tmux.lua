return {
  {
    'christoomey/vim-tmux-navigator',
    commit = 'e41c431a0c7b7388ae7ba341f01a0d217eb3a432',
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
