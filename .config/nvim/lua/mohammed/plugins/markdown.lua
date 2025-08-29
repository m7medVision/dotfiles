return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { "markdown", "copilot-chat" },
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  opts = {
    file_types = { 'markdown', 'copilot-chat' },
  },
}
