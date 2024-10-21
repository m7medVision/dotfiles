return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'
    vim.keymap.set('n', '<leader>hh', function()
      harpoon:list():add()
    end, { noremap = true, silent = true, desc = 'Harpoon add' })
    vim.keymap.set('n', '<leader>hl', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { noremap = true, silent = true, desc = 'Harpoon list' })
  end,
}
