return {
  'nvim-treesitter/nvim-treesitter',
  opts = function(_, opts)
    opts.highlight = opts.highlight or {}
    opts.highlight.additional_vim_regex_highlighting = { 'markdown' }
  end,
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      group = vim.api.nvim_create_augroup('MarkdownSyntax', { clear = true }),
      callback = function()
        vim.cmd [[syn region markdownWikiLink matchgroup=markdownLinkDelimiter start="\[\[" end="\]\]" contains=markdownUrl keepend oneline concealends]]
        vim.cmd [[syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends]]
        vim.cmd [[syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal]]
      end,
    })
  end,
}
