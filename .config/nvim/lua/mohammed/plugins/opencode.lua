vim.pack.add { 'https://github.com/NickvanDyke/opencode.nvim' }

-- Setup opencode.nvim
require('opencode').setup {
  -- Your configuration, if any
}

-- Keymaps
local function map(key, fn, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, key, fn, { desc = desc })
end

map('<leader>ot', function()
  require('opencode').toggle()
end, 'Toggle embedded opencode')

map('<leader>oa', function()
  require('opencode').ask()
end, 'Ask opencode', 'n')

map('<leader>oa', function()
  require('opencode').ask '@selection: '
end, 'Ask opencode about selection', 'v')

map('<leader>op', function()
  require('opencode').select_prompt()
end, 'Select prompt', { 'n', 'v' })
