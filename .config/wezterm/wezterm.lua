local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

local config = wezterm.config_builder()

local custom_colors = {
	green = "#9ece6a",
	yellow = "#e0af68",
	blue = "#7aa2f7",
	orange = "#ff9e64",
	aqua = "#7dcfff",
	gray = "#414868",
	fg_dim = "#a9b1d6",
}

config.color_scheme = "tokyonight_night"

local function basename(path)
	if not path or path == "" then
		return "shell"
	end

	return path:gsub(".*[/\\]", "")
end

local function pane_cwd(pane)
	local cwd = pane:get_current_working_dir()
	if not cwd then
		return nil
	end

	if type(cwd) == "userdata" or type(cwd) == "table" then
		return cwd.file_path or nil
	end

	if type(cwd) == "string" and cwd:match("^%a[%w+.-]*://") then
		if wezterm.url and wezterm.url.parse then
			local ok, parsed = pcall(wezterm.url.parse, cwd)
			if ok and parsed then
				return parsed.file_path or nil
			end
		end
	end

	return tostring(cwd)
end

local function cwd_label(pane)
	local cwd = pane_cwd(pane)
	if not cwd then
		return "~"
	end

	local file_path = cwd.file_path or tostring(cwd)
	if not file_path or file_path == "" then
		return "~"
	end

	return basename(file_path)
end

local function process_name(pane)
	return basename(pane:get_foreground_process_name())
end

local function split_pane(direction)
	return act.SplitPane({
		direction = direction,
		size = { Percent = 50 },
	})
end

local function spawn_tab_with_cwd(window, pane, command)
	window:perform_action(
		act.SpawnCommandInNewTab({
			domain = "CurrentPaneDomain",
			cwd = pane_cwd(pane),
			args = command,
		}),
		pane
	)
end

local agent_deck = nil
do
	local ok, plugin = pcall(wezterm.plugin.require, "https://github.com/Eric162/wezterm-agent-deck")
	if ok then
		agent_deck = plugin
		agent_deck.apply_to_config(config, {
			right_status = { enabled = false },
			icons = { style = "unicode" },
			colors = {
				working = custom_colors.green,
				waiting = custom_colors.yellow,
				idle = custom_colors.blue,
				inactive = custom_colors.gray,
			},
			notifications = {
				enabled = true,
				on_waiting = true,
			},
		})
	end
end

local ai_commander = nil
local anthropic_api_key = os.getenv("ANTHROPIC_API_KEY")
local openai_api_key = os.getenv("OPENAI_API_KEY")

if anthropic_api_key or openai_api_key then
	local ok, plugin = pcall(wezterm.plugin.require, "https://github.com/dimao/ai-commander.wezterm")
	if ok then
		ai_commander = plugin
		ai_commander.apply_to_config(config, {
			provider = anthropic_api_key and "anthropic" or "openai",
			api_key = {
				anthropic = anthropic_api_key,
				openai = openai_api_key,
			},
			command_count = 5,
			temperature = 0.1,
		})
	end
end

wezterm.on("update-right-status", function(window, pane)
	local cells = {}

	if agent_deck then
		local counts = agent_deck.count_agents_by_status()
		if counts.waiting > 0 then
			table.insert(cells, { Foreground = { Color = custom_colors.yellow } })
			table.insert(cells, { Text = " AI:" .. counts.waiting .. " waiting " })
		elseif counts.working > 0 then
			table.insert(cells, { Foreground = { Color = custom_colors.green } })
			table.insert(cells, { Text = " AI:" .. counts.working .. " working " })
		end
	end

	if window:leader_is_active() then
		table.insert(cells, { Foreground = { Color = custom_colors.orange } })
		table.insert(cells, { Text = " PREFIX " })
	end

	table.insert(cells, { Foreground = { Color = custom_colors.blue } })
	table.insert(cells, { Text = " " .. window:active_workspace() .. " " })
	table.insert(cells, { Foreground = { Color = custom_colors.aqua } })
	table.insert(cells, { Text = " " .. cwd_label(pane) .. " " })
	table.insert(cells, { Foreground = { Color = custom_colors.fg_dim } })
	table.insert(cells, { Text = " " .. process_name(pane) .. " " })

	window:set_right_status(wezterm.format(cells))
end)

config.automatically_reload_config = true
config.check_for_updates = false
config.animation_fps = 120
config.max_fps = 120

config.term = "xterm-256color"
config.enable_kitty_keyboard = true
config.enable_csi_u_key_encoding = true
config.disable_default_key_bindings = true

config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
config.scrollback_lines = 10000
config.tab_and_split_indices_are_zero_based = false
config.status_update_interval = 1000
config.window_close_confirmation = "NeverPrompt"
config.skip_close_confirmation_for_processes_named = {
	"bash",
	"zsh",
	"fish",
	"nu",
	"nvim",
	"vim",
}

config.initial_cols = 140
config.initial_rows = 36
config.adjust_window_size_when_changing_font_size = false

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"FiraCode Nerd Font",
	"Symbols Nerd Font Mono",
	"Noto Color Emoji",
})
config.font_size = 12.5
config.line_height = 1.06

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.show_tab_index_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

config.window_padding = {
	left = 6,
	right = 6,
	top = 4,
	bottom = 2,
}

config.window_background_opacity = 0.96
config.text_background_opacity = 1.0

config.launch_menu = {
	{
		label = "OpenCode",
		args = { "opencode" },
	},
	{
		label = "Claude Code",
		args = { "claude" },
	},
	{
		label = "Aider",
		args = { "aider" },
	},
	{
		label = "LazyGit",
		args = { "lazygit" },
	},
	{
		label = "Btop",
		args = { "btop" },
	},
}

local keys = {
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
	{ key = "f", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
	{ key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
	{ key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	{ key = "x", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
	{ key = "z", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },
	{ key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },
	{ key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "_", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	{ key = "s", mods = "LEADER", action = act.SendKey({ key = "s", mods = "CTRL" }) },
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },

	{ key = "\\", mods = "LEADER", action = split_pane("Right") },
	{ key = "-", mods = "LEADER", action = split_pane("Down") },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			spawn_tab_with_cwd(window, pane)
		end),
	},
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1) },

	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename current tab",
			action = wezterm.action_callback(function(_, pane, line)
				if line and line ~= "" then
					pane:tab():set_title(line)
				end
			end),
		}),
	},
	{
		key = "w",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES|TABS|LAUNCH_MENU_ITEMS" }),
	},
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "f", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
	{ key = "Space", mods = "LEADER", action = act.ShowLauncher },
	{
		key = "g",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			spawn_tab_with_cwd(window, pane, { "lazygit" })
		end),
	},
}

for i = 1, 9 do
	table.insert(keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

table.insert(keys, {
	key = "Backspace",
	mods = "ALT",
	action = act.SendKey({ key = "w", mods = "CTRL" }),
})

if ai_commander then
	table.insert(keys, {
		key = "X",
		mods = "ALT|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			ai_commander.show_prompt(window, pane)
		end),
	})

	table.insert(keys, {
		key = "H",
		mods = "ALT|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			ai_commander.show_history(window, pane)
		end),
	})
end

config.keys = keys

smart_splits.apply_to_config(config, {
	direction_keys = { "h", "j", "k", "l" },
	modifiers = {
		move = "CTRL",
		resize = "ALT",
	},
})

wezterm.on("augment-command-palette", function(window, pane)
	return {
		{
			brief = "Rename workspace",
			icon = "md_rename_box",
			action = act.PromptInputLine({
				description = "Rename active workspace",
				initial_value = window:active_workspace(),
				action = wezterm.action_callback(function(_, _, line)
					if line and line ~= "" then
						mux.rename_workspace(window:active_workspace(), line)
					end
				end),
			}),
		},
		{
			brief = "Open OpenCode in new tab",
			icon = "md_robot",
			action = wezterm.action_callback(function(inner_window, inner_pane)
				spawn_tab_with_cwd(inner_window, inner_pane, { "opencode" })
			end),
		},
		{
			brief = "Open LazyGit in new tab",
			icon = "md_source_repository",
			action = wezterm.action_callback(function(inner_window, inner_pane)
				spawn_tab_with_cwd(inner_window, inner_pane, { "lazygit" })
			end),
		},
	}
end)

return config
