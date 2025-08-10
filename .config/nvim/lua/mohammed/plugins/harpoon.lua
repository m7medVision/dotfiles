vim.pack.add { "https://github.com/ThePrimeagen/harpoon" }

-- Harpoon v1 configuration
local harpoon = require('harpoon')

-- Setup harpoon
harpoon.setup({})

-- Keymaps for harpoon v1
vim.keymap.set('n', '<leader>hh', function()
  require('harpoon.mark').add_file()
end, { noremap = true, silent = true, desc = 'Harpoon add' })

vim.keymap.set('n', '<leader>hl', function()
  require('harpoon.ui').toggle_quick_menu()
end, { noremap = true, silent = true, desc = 'Harpoon list' })

-- Navigation shortcuts
vim.keymap.set('n', '<leader>h1', function()
  require('harpoon.ui').nav_file(1)
end, { noremap = true, silent = true, desc = 'Harpoon file 1' })

vim.keymap.set('n', '<leader>h2', function()
  require('harpoon.ui').nav_file(2)
end, { noremap = true, silent = true, desc = 'Harpoon file 2' })

vim.keymap.set('n', '<leader>h3', function()
  require('harpoon.ui').nav_file(3)
end, { noremap = true, silent = true, desc = 'Harpoon file 3' })

vim.keymap.set('n', '<leader>h4', function()
  require('harpoon.ui').nav_file(4)
end, { noremap = true, silent = true, desc = 'Harpoon file 4' })