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
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config = function()
      vim.lsp.enable { 'lua_ls', 'tinymist', 'emmetls', 'css-lsp', 'ruff' }

      require('lspconfig').lua_ls.setup {
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = { 'vim', 'require' },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file('', true),
            },
            telemetry = {
              enable = false,
            },
          },
        },
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
    'williamboman/mason-lspconfig.nvim',
    config = function()
      require('mason-lspconfig').setup()
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      require('mason-tool-installer').setup {
        ensure_installed = { 'lua_ls', 'tinymist', 'emmet-ls', 'stylua', 'basedpyright', 'ruff', 'css-lsp' },
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
