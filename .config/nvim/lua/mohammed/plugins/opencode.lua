return {
  "NickvanDyke/opencode.nvim",
  keys = {
    { "<leader>ot", function() require('opencode').toggle() end, desc = "Toggle embedded opencode" },
    { "<leader>oa", function() require('opencode').ask() end, mode = "n", desc = "Ask opencode" },
    { "<leader>oa", function() require('opencode').ask '@selection: ' end, mode = "v", desc = "Ask opencode about selection" },
    { "<leader>op", function() require('opencode').select_prompt() end, mode = { "n", "v" }, desc = "Select prompt" },
  },
  opts = {},
}
