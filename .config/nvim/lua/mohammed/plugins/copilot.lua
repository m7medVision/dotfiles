vim.pack.add { "https://github.com/zbirenbaum/copilot.lua" }
vim.pack.add { "https://github.com/AndreM222/copilot-lualine" }

require('copilot').setup {
  suggestion = {
    enabled = true,
    auto_trigger = true,
    keymap = {
      accept = '<M-a>',
      accept_word = '<M-w>',
      accept_line = '<M-l>',
      dismiss = '<M-e>',
      next = '<M-[>',
      prev = '<M-]>',
    },
  },
  filetypes = {
    ['.'] = false,
    markdown = true,
    tex = true,
  },
  copilot_node_command = 'node',
}

-- Also setup copilot-lualine
require('copilot-lualine')