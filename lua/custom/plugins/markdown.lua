return {
  -- Fix to the following error: "Can not open browse by using cmd.exe command"
  -- cp /mnt/c/WINDOWS/system32/cmd.exe $HOME/.local/bin/

  'iamcco/markdown-preview.nvim',
  commit = 'a923f5fc5ba36a3b17e289dc35dc17f66d0548ee',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  build = 'cd app && yarn install',
  init = function()
    vim.g.mkdp_filetypes = { 'markdown' }
  end,
  ft = { 'markdown', 'codecompanion' },
  config = function()
    vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreview<CR>', { desc = '[M]arkdown [P]review' })
  end,
}
