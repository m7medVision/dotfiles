return {
	"nvim-neo-tree/neo-tree.nvim",
  enabled = function()
    return not vim.g.vscode
  end,
	keys = { -- only load the plugin on these keymaps_help
		{ "<leader>`", "<CMD>Neotree toggle<CR>" },
		{ "<leader>nb", "<CMD>Neotree reveal float<CR>" },
	},
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
    "3rd/image.nvim",
  },
	config = function()
		require("neo-tree").setup({
			close_if_last_window = false,
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,
			source_selector = {
				winbar = false,
				statusline = false,
			},
			filesystem = {
				-- filtered_items = {
				-- 	visible = true,
				-- 	show_hidden_count = true,
				-- 	hide_dotfiles = false,
				-- 	hide_gitignored = true,
				-- 	hide_by_name = {
				-- 		-- '.git',
				-- 		-- '.DS_Store',
				-- 		-- 'thumbs.db',
				-- 	},
				-- 	never_show = {},
				-- },
			},
		})
	end,
}
