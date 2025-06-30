return {
  'aznhe21/actions-preview.nvim',
  event = 'VeryLazy',
  config = function()
    vim.keymap.set({ 'v', 'n' }, '<leader>ca', require('actions-preview').code_actions)
    require('actions-preview').setup {
      backend = 'snacks',
    }
  end,
}
