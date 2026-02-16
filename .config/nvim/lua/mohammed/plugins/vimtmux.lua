return {
  "aserowy/tmux.nvim",
  keys = {
    { "<M-h>", function() require('tmux').resize_left() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize left" },
    { "<M-j>", function() require('tmux').resize_bottom() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize down" },
    { "<M-k>", function() require('tmux').resize_top() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize up" },
    { "<M-l>", function() require('tmux').resize_right() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux resize right" },
    { "<C-h>", function() require('tmux').move_left() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move left" },
    { "<C-j>", function() require('tmux').move_bottom() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move down" },
    { "<C-k>", function() require('tmux').move_top() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move up" },
    { "<C-l>", function() require('tmux').move_right() end, mode = { 'n', 'i', 't', 'v', 's', 'x', 'o', 'c' }, desc = "tmux move right" },
  },
  config = function()
    require('tmux').setup {
      navigation = { enable_default_keybindings = false },
      resize = { enable_default_keybindings = false },
    }
  end,
}
