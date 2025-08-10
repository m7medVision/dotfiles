vim.keymap.set({ 'v', 'n' }, '<leader>ca', require('actions-preview').code_actions)
require('actions-preview').setup {
  backend = 'snacks',
}