vim.opt.laststatus = 3
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.relativenumber = true
vim.g.have_nerd_font = false

vim.opt.number = true

vim.opt.mouse = 'a'

vim.opt.showmode = false

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true

vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 250

vim.opt.timeoutlen = 300

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true

vim.opt.inccommand = 'split'

vim.opt.cursorline = true

vim.opt.scrolloff = 10

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Enable update on insert mode for ts-autotag
vim.diagnostic.config {
  underline = true,
  virtual_text = {
    spacing = 5,
  },
  update_in_insert = true,
}
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- highlight yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- fix comment on new line
vim.api.nvim_create_autocmd({ 'bufenter', 'bufwinenter' }, {
  pattern = { '*' },
  callback = function()
    vim.cmd [[set formatoptions-=c formatoptions-=r formatoptions-=o]]
  end,
})
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'preview', 'noinsert' }
