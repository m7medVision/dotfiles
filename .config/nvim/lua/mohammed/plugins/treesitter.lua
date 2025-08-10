vim.pack.add { "https://github.com/nvim-treesitter/nvim-treesitter" }

-- Treesitter configuration
local ts_config = require('nvim-treesitter.configs')
ts_config.setup({
  ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = { 'ruby' },
  },
  indent = { enable = true, disable = { 'ruby' } },
})

-- Manual treesitter update command (since PackChanged isn't available)
vim.api.nvim_create_user_command('TSUpdateAll', function()
  require('nvim-treesitter.install').update()
end, { desc = 'Update all treesitter parsers' })