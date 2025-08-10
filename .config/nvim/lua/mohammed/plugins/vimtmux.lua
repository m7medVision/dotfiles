vim.pack.add { "https://github.com/aserowy/tmux.nvim" }

local tmux = require 'tmux'
tmux.setup {
  navigation = { enable_default_keybindings = false },
  resize = { enable_default_keybindings = false },
}

local modes = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }

-- Resize mappings
vim.keymap.set(modes, '<M-left>', tmux.resize_left, { desc = 'tmux resize left' })
vim.keymap.set(modes, '<M-down>', tmux.resize_bottom, { desc = 'tmux resize down' })
vim.keymap.set(modes, '<M-up>', tmux.resize_top, { desc = 'tmux resize up' })
vim.keymap.set(modes, '<M-right>', tmux.resize_right, { desc = 'tmux resize right' })

-- Navigation mappings (note: use move_*, not navigate_*)
vim.keymap.set(modes, '<C-left>', tmux.move_left, { desc = 'tmux move left' })
vim.keymap.set(modes, '<C-down>', tmux.move_bottom, { desc = 'tmux move down' })
vim.keymap.set(modes, '<C-up>', tmux.move_top, { desc = 'tmux move up' })
vim.keymap.set(modes, '<C-right>', tmux.move_right, { desc = 'tmux move right' })