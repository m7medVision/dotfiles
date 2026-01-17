return {
  'zk-org/zk-nvim',
  keys = {
    -- Create a new note after asking for its title
    {
      '<leader>zn',
      "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>",
      desc = 'Zk New note',
    },
    -- Open notes
    {
      '<leader>zo',
      "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",
      desc = 'Zk Open notes',
    },
    -- Open notes associated with the selected tags
    {
      '<leader>zt',
      '<Cmd>ZkTags<CR>',
      desc = 'Zk Tags',
    },
    -- Search for the notes matching a given query
    {
      '<leader>zf',
      "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
      desc = 'Zk Search notes',
    },
    -- Search for the notes matching the current visual selection
    {
      '<leader>zf',
      ":'<,'>ZkMatch<CR>",
      mode = 'v',
      desc = 'Zk Match selection',
    },
  },
  config = function()
    require('zk').setup {
      picker = 'snacks_picker',

      lsp = {
        -- `config` is passed to `vim.lsp.start(config)`
        config = {
          name = 'zk',
          cmd = { 'zk', 'lsp' },
          filetypes = { 'markdown' },
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start()`
        },

        -- automatically attach buffers in a zk notebook that match the given filetypes
        auto_attach = {
          enabled = true,
        },
      },
    }

    -- Set up markdown-specific keymaps for zk notebooks
    local zk_util = require('zk.util')
    local augroup = vim.api.nvim_create_augroup('ZkMarkdown', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      group = augroup,
      callback = function(ev)
        -- Enable conceallevel for all markdown files
        vim.opt_local.conceallevel = 2

        -- Check if this buffer is in a zk notebook
        local notebook_root = zk_util.notebook_root(vim.fn.expand(ev.file .. ':p'))
        if notebook_root == nil then
          return
        end

        -- Buffer-local keymaps for zk notebooks
        local function map(mode, lhs, rhs, opts)
          vim.api.nvim_buf_set_keymap(ev.buf, mode, lhs, rhs, opts or {})
        end

        local opts = { noremap = true, silent = false }

        -- Open the link under the caret
        map('n', '<CR>', "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)

        -- Create a new note in the same directory as the current buffer
        map('n', '<leader>zn',
          "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)

        -- Create a new note using the current selection for title
        map('v', '<leader>znt', ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",
          opts)

        -- Create a new note using the current selection for content
        map('v', '<leader>znc',
          ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
          opts)

        -- Open notes linking to the current buffer
        map('n', '<leader>zb', '<Cmd>ZkBacklinks<CR>', opts)

        -- Open notes linked by the current buffer
        map('n', '<leader>zl', '<Cmd>ZkLinks<CR>', opts)

        -- Preview a linked note
        map('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)

        -- Code actions for visual selection
        map('v', '<leader>za', ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
      end,
    })
  end,
}
