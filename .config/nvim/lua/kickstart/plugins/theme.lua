vim.pack.add { 'https://github.com/ellisonleao/gruvbox.nvim' }
---@diagnostic disable-next-line: missing-fields
require('gruvbox').setup {
  italic = {
    strings = false,
    comments = false,
  },
  contrast = 'hard',
}
vim.cmd.colorscheme 'gruvbox'
