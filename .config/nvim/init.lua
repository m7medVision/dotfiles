-- Commaon setup for nvim
require 'mohammed.common'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  require 'mohammed.plugins.move',
  require 'mohammed.plugins.lualine',
  require 'mohammed.plugins.which_key',
  require 'mohammed.plugins.telescope',
  require 'mohammed.plugins.lazydev',
  require 'mohammed.plugins.luvit_meta',
  require 'mohammed.plugins.lsp',
  require 'mohammed.plugins.conform',
  require 'mohammed.plugins.cmp',
  require 'mohammed.plugins.todo_highlight',
  require 'mohammed.plugins.mini_nvim',
  require 'mohammed.plugins.theme',
  require 'mohammed.plugins.treesitter',
  -- require 'mohammed.plugins.debug',
  require 'mohammed.plugins.indent_line',
  -- require 'mohammed.plugins.lint',
  require 'mohammed.plugins.autopairs',
  require 'mohammed.plugins.neo-tree',
  require 'mohammed.plugins.copilot',
  require 'mohammed.plugins.oil',
  require 'mohammed.plugins.tailwind',
  require 'mohammed.plugins.vimtmux',
  require 'mohammed.plugins.harpoon',
  require 'mohammed.plugins.vimvisualmulti',
  require 'mohammed.plugins.lazygit',
  require 'mohammed.plugins.autoclose',
  require 'mohammed.plugins.gitsigns', -- adds gitsigns recommend keymaps
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
