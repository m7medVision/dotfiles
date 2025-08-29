return {
  {
    'tpope/vim-dadbod',
    cmd = { 'DB' },
  },
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = { 'tpope/vim-dadbod' },
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      -- keymaps
      vim.keymap.set('n', '<leader>du', '<cmd>DBUI<cr>', { desc = 'Toggle DBUI' })
      vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<cr>', { desc = 'Find DB Buffer' })
      vim.keymap.set('n', '<leader>da', '<cmd>DBUIAddConnection<cr>', { desc = 'Add DB Connection' })
    end,
  },
}
