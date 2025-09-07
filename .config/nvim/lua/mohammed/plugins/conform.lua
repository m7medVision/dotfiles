return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>df',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = { 'n', 'v' },
      desc = '[F]ormat buffer',
    },
  },
  config = function()
    require('conform').setup {
      notify_on_error = false,
      notify_no_formatters = true,
      lsp_format = 'fallback',
      stop_after_first = false,
      format_on_save = function(bufnr)
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
        ['*'] = { 'trim_whitespace', 'trim_newlines' },
        cs = { 'csharpier' },
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
        javascript = { 'prettierd' },
        toml = { 'taplo' },
        php = { 'pint' },
        blade = { 'blade-formatter' },
        typescriptreact = { 'prettier' },
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
  end,
}
