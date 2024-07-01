local M = {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  dependencies = {
    "zbirenbaum/copilot-cmp",
  },
}

function M.config()
  require("copilot").setup {
    panel = {
      keymap = {
        jump_next = "<M-[>",
        jump_prev = "<M-]>",
        accept = "<M-a>",
        refresh = "r",
        open = "<S-CR>",
      },
    },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = "<M-a>",
        next = "<M-[>",
        prev = "<M-]>",
        dismiss = "<M-x>",
        accept_word = "<M-w>",
        accept_line = "<M-e>",
      },
    },
    filetypes = {
      ["."] = false,
    },
    copilot_node_command = "node",
  }

  local opts = { noremap = true, silent = true }
  vim.api.nvim_set_keymap("n", "<M-b>", "<cmd>Copilot panel<CR>", opts)

  -- require("copilot_cmp").setup()
end

return M
