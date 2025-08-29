return {
  "aznhe21/actions-preview.nvim",
  keys = {
    { "<leader>ca", function() require('actions-preview').code_actions() end, mode = { "v", "n" }, desc = "Code actions" },
  },
  opts = {
    backend = 'snacks',
  },
}