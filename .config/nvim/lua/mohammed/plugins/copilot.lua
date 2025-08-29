return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
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
    end,
  },
  {
    "AndreM222/copilot-lualine",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      require('copilot-lualine')
    end,
  },
}