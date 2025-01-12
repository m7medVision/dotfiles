return {
  'saghen/blink.cmp',
  dependencies = {
    'rafamadriz/friendly-snippets',
  },

  version = '*',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = nil,
      ['<C-y>'] = { 'select_and_accept' },
      ['<C-space>'] = { 'show', 'accept' },
      ['<C-c>'] = { 'hide' },
      ['<up>'] = { 'select_prev' },
      ['<down>'] = { 'select_next' },
    },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },
    completion = {
      ghost_text = {
        enabled = true,
      },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  },
  opts_extend = { 'sources.default' },
}
