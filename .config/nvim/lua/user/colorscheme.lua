return {
  {
    "Shatur/neovim-ayu",
  },
  {
    "EdenEast/nightfox.nvim",
  },
  {
    "projekt0n/github-nvim-theme",
  },
  {
    "folke/tokyonight.nvim",
    config = function()
      vim.cmd("colorscheme tokyonight-night")
    end,
  }
}
