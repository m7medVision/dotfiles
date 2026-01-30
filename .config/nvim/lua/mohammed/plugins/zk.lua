return {
  'zk-org/zk-nvim',
  config = function()
    require('zk').setup {
      picker = 'snacks_picker',
      lsp = {
        config = {
          name = 'zk',
          cmd = { 'zk', 'lsp' },
          filetypes = { 'markdown' },
        },
        auto_attach = {
          enabled = true,
        },
      },
    }
  end,
}
