return {
  "ellisonleao/gruvbox.nvim",
  name = "gruvbox",
  lazy = false,
  priority = 1000,
  config = function()
    require('gruvbox').setup({
      terminal_colors = true,
      transparent_mode = true,
      italics = {
        comments = true,
        strings = false,
        operators = false,
        folds = true,
      },
      overrides = {},
    })
    vim.o.background = 'dark'
    vim.cmd.colorscheme 'gruvbox'
  end,
}
