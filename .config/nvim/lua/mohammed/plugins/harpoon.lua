return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>hh",
      function()
        require("harpoon"):list():append()
      end,
      desc = "Harpoon add",
    },
    {
      "<leader>hl",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon list",
    },
  },
  config = function()
    require("harpoon"):setup()
  end,
}
