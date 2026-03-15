return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    { "<M-h>", function() require("smart-splits").resize_left() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "resize left" },
    { "<M-j>", function() require("smart-splits").resize_down() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "resize down" },
    { "<M-k>", function() require("smart-splits").resize_up() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "resize up" },
    { "<M-l>", function() require("smart-splits").resize_right() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "resize right" },
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "move left" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "move down" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "move up" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "i", "t", "v", "s", "x", "o", "c" }, desc = "move right" },
  },
  config = function()
    vim.g.smart_splits_multiplexer_integration = "wezterm"

    require("smart-splits").setup {
      multiplexer_integration = "wezterm",
      disable_multiplexer_nav_when_zoomed = false,
    }
  end,
}
