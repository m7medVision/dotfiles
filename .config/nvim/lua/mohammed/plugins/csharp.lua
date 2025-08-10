return {

  'iabdelkareem/csharp.nvim',
  dependencies = {
    'mfussenegger/nvim-dap',
    'Tastyep/structlog.nvim', -- Optional, but highly recommended for debugging
  },
  config = function()
    require('csharp').setup()
  end,
}
