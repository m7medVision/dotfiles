return {
  "nguyenvukhang/nvim-toggler",
  event = {"BufReadPre","BufNewFile"},
  config = function()
    -- init.lua
    require("nvim-toggler").setup({
      -- removes the default <leader>i keymap
      remove_default_keybinds = true,
      -- removes the default set of inverses
    })
    vim.keymap.set({ "n", "v" }, "<leader>ci", require("nvim-toggler").toggle, { desc = "Invert word" })
    vim.keymap.set({ "n", "v" }, "<leader>cc", "~", { desc = "Toggle character case (~)" })
  end,
}
