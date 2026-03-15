return {
  {
    'zbirenbaum/copilot.lua',
    dependencies = {
      'copilotlsp-nvim/copilot-lsp',
    },
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      nes = {
        enabled = true,
        keymap = {
          accept_and_goto = '<S-Tab>',
          accept = false,
          dismiss = '<Esc>',
        },
      },
    },
  },
}
