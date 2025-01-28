return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup({
      update_focused_file = {
        enable = true,
      },
      view = {
        adaptive_size = true,
      },
    })
    vim.api.nvim_set_keymap('n', '<C-h>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
  end,
}
