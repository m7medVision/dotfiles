-- File explorer that lets you edit your filesystem like a buffer
--  Enable `stevearc/oil.nvim`
--  See `:help oil.nvim`
vim.pack.add { 'https://github.com/stevearc/oil.nvim' }
require('oil').setup {
	vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
}

