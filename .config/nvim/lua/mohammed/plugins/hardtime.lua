return {
  'm4xshen/hardtime.nvim',
  lazy = false,
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = {},
  config = function(_, opts)
    require('hardtime').setup(opts)
  end,
}
