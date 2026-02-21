return {
  {
    'zbirenbaum/copilot.lua',
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

  {
    'copilotlsp-nvim/copilot-lsp',
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable 'copilot_ls'
      vim.keymap.set('i', '<Esc>', function()
        require('copilot-lsp.nes').clear()
        return '<Esc>'
      end, { desc = 'Dismiss Copilot NES suggestion', expr = true })
    end,
    opts = {
      nes = {
        move_count_threshold = 3, -- Clear after 3 cursor movements
      },
    },
  },
}
