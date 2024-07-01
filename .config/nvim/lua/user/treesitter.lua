local M = {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
  { "windwp/nvim-ts-autotag" },
}
}

function M.config()
  require("nvim-treesitter.configs").setup {
    auto_install = true,
    autotag = { enable = true },
    highlight = { enable = true },
    indent = { enable = true },
  }
end

return M
