return {
  {
    'github/copilot.vim',
    branch = 'release',
    cmd = 'Copilot',
    event = 'BufReadPost',
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.keymap.set('i', '<M-a>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
      })
    end,
  },
  {
    'folke/sidekick.nvim',
    opts = {
      cli = {
        mux = {
          backend = 'tmux',
          enabled = true,
        },
      },
    },
    keys = {
      {
        '<Leader>aa',
        function()
          require('sidekick.cli').focus()
        end,
        mode = { 'n', 'x', 'i', 't' },
        desc = 'Sidekick Switch Focus',
      },
      {
        '<Leader>ac',
        function()
          require('sidekick.cli').toggle { focus = true }
        end,
        desc = 'Sidekick Toggle CLI',
        mode = { 'n', 'v' },
      },
      {
        '<Leader>ap',
        function()
          require('sidekick.cli').prompt()
        end,
        desc = 'Sidekick Ask Prompt',
        mode = { 'n', 'v' },
      },
      {
        '<leader>as',
        function()
          require('sidekick.cli').select()
        end,
        desc = 'Select CLI',
      },
      {
        '<leader>at',
        function()
          require('sidekick.cli').send { msg = '{this}' }
        end,
        mode = { 'x', 'n' },
        desc = 'Send This',
      },
      {
        '<leader>av',
        function()
          require('sidekick.cli').send { msg = '{selection}' }
        end,
        mode = { 'x' },
        desc = 'Send Visual Selection',
      },
      {
        '<c-.>',
        function()
          require('sidekick.cli').focus()
        end,
        mode = { 'n', 'x', 'i', 't' },
        desc = 'Sidekick Switch Focus',
      },
    },
  },
  {
    'sourcegraph/sg.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  },
}
