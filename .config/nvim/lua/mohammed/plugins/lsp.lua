return {
  -- Treesitter for syntax highlighting and code understanding
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('nvim-treesitter.configs').setup {
        modules = {},
        sync_install = true,
        ensure_installed = {},
        ignore_install = {},
        auto_install = true,
        highlight = { enable = true, additional_vim_regex_highlighting = { 'markdown' } },
        indent = { enable = true },
      }
    end,
  },

  -- LSP default configurations
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'b0o/schemastore.nvim',
    },
    config = function()
      -- Setup mason-lspconfig to automatically enable all installed LSP servers
      require('mason-lspconfig').setup {
        automatic_enable = true, -- This is the default, automatically enables all installed servers
      }
    end,
  },

  -- JSON and YAML schemas
  {
    'b0o/schemastore.nvim',
    config = function()
      vim.lsp.config('jsonls', {
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      })
      vim.lsp.config('yamlls', {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = '' },
            schemas = vim.tbl_extend('error', require('schemastore').yaml.schemas(), {
              ['https://www.artillery.io/schema.json'] = {
                '*.load-test.yml',
                '*.test.yml',
                '*.load-test.yaml',
                '*.test.yaml',
              },
            }),
          },
        },
      })
    end,
  },

  -- LSP installation
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    config = function()
      require('mason').setup()
    end,
  },

  -- Automatic LSP server installation
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      require('mason-tool-installer').setup {
        ensure_installed = {
          'copilot-language-server',
          'lua-language-server',
          'tinymist',
          'emmet-ls',
          'stylua',
          'css-lsp',
          'tailwindcss-language-server',
          'html-lsp',
          'json-lsp',
        },
      }
    end,
  },

  -- Load Lua types lazily
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    config = function()
      require('lazydev').setup {
        library = {
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          { path = 'snacks.nvim', words = { 'Snacks' } },
        },
      }
    end,
  },

  -- Typst preview
  {
    'chomosuke/typst-preview.nvim',
    ft = 'typst',
    lazy = true,
  },

  -- Auto-indent detection
  {
    'tpope/vim-sleuth',
    event = { 'BufReadPre', 'BufNewFile' },
  },

  -- Plenary utilities
  {
    'nvim-lua/plenary.nvim',
    lazy = true,
  },

  -- Image support for Neovim (requires Kitty terminal with graphics protocol)
  {
    '3rd/image.nvim',
    build = false, -- so that it doesn't build the rock
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki' },
        },
        neorg = {
          enabled = true,
          filetypes = { 'norg' },
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
    },
  },

  -- Diagram rendering for markdown and neorg
  {
    '3rd/diagram.nvim',
    dependencies = { '3rd/image.nvim' },
    opts = {
      events = {
        render_buffer = { 'InsertLeave', 'BufWinEnter', 'TextChanged' },
        clear_buffer = { 'BufLeave' },
      },
      renderer_options = {
        mermaid = {
          theme = nil,
          scale = 1,
        },
        plantuml = {
          charset = nil,
        },
        d2 = {
          theme_id = nil,
        },
      },
    },
    keys = {
      {
        '<leader>dp',
        function()
          require('diagram').show_diagram_hover()
        end,
        mode = 'n',
        ft = { 'markdown', 'norg' },
        desc = 'Show diagram in new tab',
      },
    },
  },
}
