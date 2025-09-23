return {
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
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'b0o/schemastore.nvim',
      'neovim/nvim-lspconfig',
    },
    config = function()
      -- Enable LSP servers
      vim.lsp.enable {
        'lua_ls',
        'tailwindcss',
        'ts_ls',
      }
    end,
  },
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    config = function()
      require('mason').setup()
    end,
  },
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
  {
    'chomosuke/typst-preview.nvim',
    ft = 'typst',
    lazy = true,
  },
  {
    'tpope/vim-sleuth',
    event = { 'BufReadPre', 'BufNewFile' },
  },
  {
    'nvim-lua/plenary.nvim',
    lazy = true,
  },
}
