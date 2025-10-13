---@type LazySpec
return {
  -- Treesitter for syntax highlighting and code understanding
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('nvim-treesitter.configs').setup {
        auto_install = true,
        highlight = { enable = true },
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
          'lua-language-server',
          'tinymist',
          'emmet-ls',
          'stylua',
          'basedpyright',
          'ruff',
          'css-lsp',
          'tailwindcss-language-server',
          'typescript-language-server',
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
}
