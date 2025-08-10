require('opencode-context').setup({
  tmux_target = nil, -- Manual override: "session:window.pane"
  auto_detect_pane = true, -- Auto-detect opencode pane in current window
})

-- Keymaps
vim.keymap.set('n', '<leader>oc', '<cmd>OpencodeSend<cr>', { desc = 'Send prompt to opencode' })
vim.keymap.set('v', '<leader>oc', '<cmd>OpencodeSend<cr>', { desc = 'Send prompt to opencode' })
vim.keymap.set('n', '<leader>ot', '<cmd>OpencodeSwitchMode<cr>', { desc = 'Toggle opencode mode' })
vim.keymap.set('n', '<leader>op', '<cmd>OpencodePrompt<cr>', { desc = 'Open opencode persistent prompt' })