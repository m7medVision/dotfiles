vim.pack.add { { src = 'https://github.com/saghen/blink.cmp', version = 'v1.6.0' } }

vim.pack.add {
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/onsails/lspkind.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
}

require('blink.cmp').setup {
  fuzzy = {
    implementation = 'lua', -- or "prefer_rust"
  },
  keymap = {
    preset = 'super-tab',
  },
  appearance = {
    use_nvim_cmp_as_default = true,
  },
  completion = {
    trigger = {
      show_on_trigger_character = true,
      show_on_insert_on_trigger_character = true,
      show_on_x_blocked_trigger_characters = { "'", '"', '(', '{' },
    },
    menu = {
      border = 'rounded',
      draw = {
        treesitter = { 'lsp' },
        columns = { { 'label', 'label_description', gap = 1 }, { 'kind_icon', 'kind', gap = 1 } },
        components = {
          kind_icon = {
            text = function(ctx)
              local lspkind = require 'lspkind'
              local icon = ctx.kind_icon
              if vim.tbl_contains({ 'Path' }, ctx.source_name) then
                local dev_icon = require('nvim-web-devicons').get_icon(ctx.label)
                if dev_icon then
                  icon = dev_icon
                end
              else
                icon = lspkind.symbolic(ctx.kind, { mode = 'symbol' })
              end
              return icon .. ctx.icon_gap
            end,
            highlight = function(ctx)
              local hl = ctx.kind_hl
              if vim.tbl_contains({ 'Path' }, ctx.source_name) then
                local _, dev_hl = require('nvim-web-devicons').get_icon(ctx.label)
                if dev_hl then
                  hl = dev_hl
                end
              end
              return hl
            end,
          },
        },
      },
    },

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

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    per_filetype = {
      sql = { 'snippets', 'dadbod', 'buffer' },
    },
    providers = {
      dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' },
    },
  },
}
