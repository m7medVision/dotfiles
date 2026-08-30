-- Render Markdown in Neovim
-- Repo: https://github.com/MeanderingProgrammer/render-markdown.nvim

local render_markdown_path

vim.pack.add({
  {
    src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
    name = 'render-markdown.nvim',
  },
}, {
  load = function(plugin) render_markdown_path = plugin.path end,
})

local loaded = false

local function load_render_markdown()
  if loaded then return end
  loaded = true

  if render_markdown_path then
    vim.cmd.packadd 'render-markdown.nvim'
  end

  require('render-markdown').setup {
    file_types = { 'markdown' },
  }

  vim.keymap.set('n', '<leader>mr', '<cmd>RenderMarkdown toggle<CR>', {
    desc = 'Toggle markdown rendering',
  })
end

vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  pattern = { '*.md', '*.markdown' },
  callback = load_render_markdown,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = load_render_markdown,
})
