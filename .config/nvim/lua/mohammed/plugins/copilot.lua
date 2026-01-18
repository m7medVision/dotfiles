local config = require 'blink.cmp.completion.brackets.config'
-- Copilot configuration with blink.cmp integration
return {
  {
    'github/copilot.vim',
    cmd = 'Copilot',
    event = 'BufWinEnter',
    init = function()
      vim.g.copilot_no_maps = true
    end,
    config = function()
      -- Block Copilot suggestions in brackets and quotes
      vim.api.nvim_create_augroup('github_copilot', { clear = true })
      vim.api.nvim_create_autocmd({ 'FileType', 'BufUnload' }, {
        group = 'github_copilot',
        callback = function(args)
          vim.fn['copilot#On' .. args.event]()
        end,
      })
      vim.fn['copilot#OnFileType']()
    end,
  },

  {
    'copilotlsp-nvim/copilot-lsp',
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable 'copilot_ls'
    end,
    opts = {
      nes = {
        move_count_threshold = 3, -- Clear after 3 cursor movements
      },
    },
  },
}
