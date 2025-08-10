vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require('snacks').setup {
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    preset = {
      header = [[
 ████████    ██████   ██████  █████ █████ ████  █████████████
░░███░░███  ███░░███ ███░░███░░███ ░░███ ░░███ ░░███░░███░░███
 ░███ ░███ ░███████ ░███ ░███ ░███  ░███  ░███  ░███ ░███ ░███
 ░███ ░███ ░███░░░  ░███ ░███ ░░███ ███   ░███  ░███ ░███ ░███
 ████ █████░░██████ ░░██████   ░░█████    █████ █████░███ █████
░░░░ ░░░░░  ░░░░░░   ░░░░░░     ░░░░░    ░░░░░ ░░░░░ ░░░ ░░░░░ ]],
      keys = {
        { icon = ' ', key = 'e', desc = 'Explorer', action = ':lua Snacks.explorer()' },
        { icon = ' ', key = 'f', desc = 'Find file', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = ' ', key = 'n', desc = 'New file', action = ':ene | startinsert' },
        { icon = ' ', key = '/', desc = 'Find text', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
    sections = {
      { section = 'header', padding = 3 },
      { section = 'keys', padding = 2, gap = 1 },
      { section = 'recent_files', padding = 1, limit = 6, cwd = true },
    },
  },
  explorer = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  picker = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  styles = {
    notification = {
      -- wo = { wrap = true } -- Wrap notifications
    },
  },
}

-- Keymaps
local function map(key, fn, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, key, fn, { desc = desc })
end

-- Top Pickers & Explorer
map('<leader><space>', function()
  Snacks.picker.smart()
end, 'Smart Find Files')

map('<leader>,', function()
  Snacks.picker.buffers()
end, 'Buffers')

map('<leader>/', function()
  Snacks.picker.grep()
end, 'Grep')

map('<leader>:', function()
  Snacks.picker.command_history()
end, 'Command History')

map('<leader>n', function()
  Snacks.picker.notifications()
end, 'Notification History')

-- Explorer
map('<leader>e', function()
  Snacks.explorer()
end, 'File Explorer')

map('<leader>fc', function()
  Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
end, 'Find Config File')

map('<leader>ff', function()
  Snacks.picker.files()
end, 'Find Files')

map('<leader>fg', function()
  Snacks.picker.git_files()
end, 'Find Git Files')

map('<leader>fp', function()
  Snacks.picker.projects()
end, 'Projects')

map('<leader>fr', function()
  Snacks.picker.recent()
end, 'Recent')

-- Git
map('<leader>gb', function()
  Snacks.picker.git_branches()
end, 'Git Branches')

map('<leader>gl', function()
  Snacks.picker.git_log()
end, 'Git Log')

map('<leader>gL', function()
  Snacks.picker.git_log_line()
end, 'Git Log Line')

map('<leader>gs', function()
  Snacks.picker.git_status()
end, 'Git Status')

map('<leader>gS', function()
  Snacks.picker.git_stash()
end, 'Git Stash')

map('<leader>gd', function()
  Snacks.picker.git_diff()
end, 'Git Diff (Hunks)')

map('<leader>gf', function()
  Snacks.picker.git_log_file()
end, 'Git Log File')

-- Grep
map('<leader>sb', function()
  Snacks.picker.lines()
end, 'Buffer Lines')

map('<leader>sB', function()
  Snacks.picker.grep_buffers()
end, 'Grep Open Buffers')

map('<leader>sg', function()
  Snacks.picker.grep()
end, 'Grep')

map('<leader>sw', function()
  Snacks.picker.grep_word()
end, 'Visual selection or word', { 'n', 'x' })

-- Search
map('<leader>s"', function()
  Snacks.picker.registers()
end, 'Registers')

map('<leader>s/', function()
  Snacks.picker.search_history()
end, 'Search History')

map('<leader>sa', function()
  Snacks.picker.autocmds()
end, 'Autocmds')

map('<leader>sd', function()
  Snacks.picker.diagnostics()
end, 'Diagnostics')

map('<leader>sD', function()
  Snacks.picker.diagnostics_buffer()
end, 'Buffer Diagnostics')

map('<leader>sh', function()
  Snacks.picker.help()
end, 'Help Pages')

map('<leader>sH', function()
  Snacks.picker.highlights()
end, 'Highlights')

map('<leader>si', function()
  Snacks.picker.icons()
end, 'Icons')

map('<leader>sj', function()
  Snacks.picker.jumps()
end, 'Jumps')

map('<leader>sk', function()
  Snacks.picker.keymaps()
end, 'Keymaps')

map('<leader>sl', function()
  Snacks.picker.loclist()
end, 'Location List')

map('<leader>sm', function()
  Snacks.picker.marks()
end, 'Marks')

map('<leader>sM', function()
  Snacks.picker.man()
end, 'Man Pages')

map('<leader>sp', function()
  Snacks.picker.lazy()
end, 'Search for Plugin Spec')

map('<leader>sq', function()
  Snacks.picker.qflist()
end, 'Quickfix List')

map('<leader>sR', function()
  Snacks.picker.resume()
end, 'Resume')

map('<leader>su', function()
  Snacks.picker.undo()
end, 'Undo History')

map('<leader>uC', function()
  Snacks.picker.colorschemes()
end, 'Colorschemes')

-- LSP
map('gd', function()
  Snacks.picker.lsp_definitions()
end, 'Goto Definition')

map('gD', function()
  Snacks.picker.lsp_declarations()
end, 'Goto Declaration')

map('gr', function()
  Snacks.picker.lsp_references()
end, 'References')

map('gI', function()
  Snacks.picker.lsp_implementations()
end, 'Goto Implementation')

map('gy', function()
  Snacks.picker.lsp_type_definitions()
end, 'Goto T[y]pe Definition')

map('<leader>ss', function()
  Snacks.picker.lsp_symbols()
end, 'LSP Symbols')

map('<leader>sS', function()
  Snacks.picker.lsp_workspace_symbols()
end, 'LSP Workspace Symbols')

-- Other
map('<leader>z', function()
  Snacks.zen()
end, 'Toggle Zen Mode')
map('<leader>Z', function()
  Snacks.zen.zoom()
end, 'Toggle Zoom')

map('<leader>.', function()
  Snacks.scratch()
end, 'Toggle Scratch Buffer')

map('<leader>S', function()
  Snacks.scratch.select()
end, 'Select Scratch Buffer')

map('<leader>n', function()
  Snacks.notifier.show_history()
end, 'Notification History')

map('<leader>bd', function()
  Snacks.bufdelete()
end, 'Delete Buffer')

map('<leader>cR', function()
  Snacks.rename.rename_file()
end, 'Rename File')

map('<leader>gB', function()
  Snacks.gitbrowse()
end, 'Git Browse', { 'n', 'v' })

map('<leader>gg', function()
  Snacks.lazygit()
end, 'Lazygit')

map('<leader>un', function()
  Snacks.notifier.hide()
end, 'Dismiss All Notifications')

map('<c-/>', function()
  Snacks.terminal()
end, 'Toggle Terminal')

map('<c-_>', function()
  Snacks.terminal()
end, 'which_key_ignore')

map(']]', function()
  Snacks.words.jump(vim.v.count1)
end, 'Next Reference', { 'n', 't' })

map('[[', function()
  Snacks.words.jump(-vim.v.count1)
end, 'Prev Reference', { 'n', 't' })

map('<leader>N', function()
  Snacks.win {
    file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
    width = 0.6,
    height = 0.6,
    wo = {
      spell = false,
      wrap = false,
      signcolumn = 'yes',
      statuscolumn = ' ',
      conceallevel = 3,
    },
  }
end, 'Neovim News')

-- Setup autocmd for debugging and toggles
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    -- Setup some globals for debugging (lazy-loaded)
    _G.dd = function(...)
      Snacks.debug.inspect(...)
    end
    _G.bt = function()
      Snacks.debug.backtrace()
    end
    vim.print = _G.dd -- Override print to use snacks for `:=` command

    -- Create some toggle mappings
    Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
    Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
    Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
    Snacks.toggle.diagnostics():map '<leader>ud'
    Snacks.toggle.line_number():map '<leader>ul'
    Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
    Snacks.toggle.treesitter():map '<leader>uT'
    Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
    Snacks.toggle.inlay_hints():map '<leader>uh'
    Snacks.toggle.indent():map '<leader>ug'
    Snacks.toggle.dim():map '<leader>uD'
  end,
})
