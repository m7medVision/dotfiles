vim.pack.add { "https://github.com/stevearc/oil.nvim" }

require('oil').setup {
  columns = {
    'icon',
  },
}
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })