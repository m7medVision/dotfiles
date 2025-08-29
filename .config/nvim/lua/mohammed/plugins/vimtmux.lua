return {
  "aserowy/tmux.nvim",
  keys = {
    { "<M-left>", function() require('tmux').resize_left() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize left" },
    { "<M-down>", function() require('tmux').resize_bottom() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize down" },
    { "<M-up>", function() require('tmux').resize_top() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize up" },
    { "<M-right>", function() require('tmux').resize_right() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize right" },
    { "<C-left>", function() require('tmux').move_left() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move left" },
    { "<C-down>", function() require('tmux').move_bottom() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move down" },
    { "<C-up>", function() require('tmux').move_top() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move up" },
    { "<C-right>", function() require('tmux').move_right() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move right" },
  },
  config = function()
    require('tmux').setup {
      navigation = { enable_default_keybindings = false },
      resize = { enable_default_keybindings = false },
    }
  end,
}