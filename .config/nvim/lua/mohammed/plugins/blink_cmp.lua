return {
  {
    'saghen/blink.compat',
    -- use the latest release, via version = '*', if you also use the latest release for blink.cmp
    version = '*',
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },

    version = '*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'super-tab',
      },
      appearance = {
        use_nvim_cmp_as_default = true,
      },
      completion = {
        trigger = {
          -- When true, will show the completion window after typing a trigger character
          show_on_trigger_character = true,
          -- When both this and show_on_trigger_character are true, will show the completion window
          -- when the cursor comes after a trigger character when entering insert mode
          show_on_insert_on_trigger_character = true,
          -- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
          -- the completion window when the cursor comes after a trigger character when
          -- entering insert mode/accepting an item
          show_on_x_blocked_trigger_characters = { "'", '"', '(', '{' },
          -- or a function, similar to show_on_blocked_trigger_character
        },
        menu = {
          border = 'rounded',
          draw = {
            columns = { { 'label', 'label_description', gap = 1 }, { 'kind_icon', 'kind', gap = 1 } },
            treesitter = {},
          },
        },

        -- experimental auto-brackets support
        accept = {
          auto_brackets = { enabled = false },
        },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          treesitter_highlighting = true,
          window = {
            border = 'rounded',
          },
        },

        ghost_text = {
          enabled = false,
        },
      },

      signature = {
        enabled = true,
        window = {
          border = 'rounded',
        },
      },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    opts_extend = { 'sources.default' },
  },
}
