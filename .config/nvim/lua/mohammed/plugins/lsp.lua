vim.pack.add {
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'master' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/folke/lazydev.nvim' },
  { src = 'https://github.com/chomosuke/typst-preview.nvim' },
}

vim.lsp.enable { 'lua_ls', 'biome', 'tinymist', 'emmetls', 'css-lsp', 'ruff' }

-- stylua: ignore: missing-fields
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'c', 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline' },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    -- disable = { 'c', 'rust' },
    -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
    disable = function(_, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup {
  ensure_installed = { 'lua_ls', 'biome', 'tinymist', 'emmet-ls', 'stylua', 'basedpyright', 'ruff', 'css-lsp' },
}

require('lazydev').setup {
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    { path = 'snacks.nvim', words = { 'Snacks' } },
  },
}

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

require('conform').setup {
  notify_on_error = false,
  notify_no_formatters = true,
  lsp_format = 'fallback', ---@type "first" | "last" | "fallback" | "never" | "prefer" | "only"
  stop_after_first = false,
  format_on_save = function(bufnr)
    -- Disable "format_on_save lsp_fallback" for languages that don't
    -- have a well standardized coding style. You can add additional
    -- languages here or re-enable it for the disabled ones.
    local disable_filetypes = { c = true, cpp = true, htmldjango = true }
    if disable_filetypes[vim.bo[bufnr].filetype] then
      return nil
    else
      return {
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end
  end,
  formatters = {
    typstyle = { args = { '-t', '4', '-l', '100' } },
    sqlfmt = {
      append_args = { '-d', 'clickhouse' },
    },
    latexindent = {
      append_args = { '-l' },
    },
  },
  formatters_by_ft = {
    -- The available `lsp_format` options are:
    -- - `"first"` - Try LSP first, then formatters
    -- - `"last"` - Try formatters first, then LSP
    -- - `"prefer"` - Use LSP if available, otherwise use formatters (current setting)
    -- - `"fallback"` - Use formatters if available, otherwise use LSP
    -- - `"only"` - Use only LSP formatting
    -- - `"never"` - Never use LSP formatting
    ['*'] = { 'trim_whitespace', 'trim_newlines' },
    lua = { 'stylua', lsp_format = 'prefer' },
    css = { 'prettierd' },
    html = { 'prettierd' },
    htmldjango = { 'prettierd' },
    json = { 'jq' },
    sh = { 'shfmt' },
    sql = { 'sqlfmt' },
    yaml = { 'yamlfmt' },
    zsh = { 'beautysh' },
    rust = { 'rustfmt' },
    tex = { 'latexindent' },
    typescript = { 'prettierd' },
    typst = { 'typstyle', lsp_format = 'fallback' },
    javascript = { 'biome', 'prettierd' },
    toml = { 'taplo' },
    python = function(bufnr)
      if require('conform').get_formatter_info('ruff_format', bufnr).available then
        return { 'ruff_organize_imports', 'ruff_format' }
      else
        return { 'isort', 'black' }
      end
    end,
  },
  default_format_opts = {
    lsp_format = 'fallback',
  },
}
