-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

local theme = require('themes.kanagawa')

-- This is where you actually apply your config choices

---------------------------------------------------------------
--- Config
---------------------------------------------------------------

local act = wezterm.action

local config = {
	-- Appearance
	-- colors = theme,
	color_scheme = 'tokyonight',
	animation_fps = 60,
	max_fps = 60,
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = false,
	adjust_window_size_when_changing_font_size = false,
	window_background_opacity = 0.99,
	webgpu_power_preference = 'HighPerformance',
	enable_kitty_graphics=true,
	window_padding = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 1,
	},
	inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.65,
	},

	-- Font
	font = wezterm.font 'JetBrains Mono',
	font_size = 13,

	-- Wayland
	 enable_wayland = false,

	-- General
	--exit_behavior = "CloseOnCleanExit",
	enable_tab_bar = false,
	window_decorations = "NONE",
	tab_bar_at_bottom = false,
	exit_behavior_messaging = 'Verbose',
	status_update_interval = 1000,
	scrollback_lines = 5000,
	hyperlink_rules = {
		-- Matches: a URL in parens: (URL)
		{
			regex = '\\((\\w+://\\S+)\\)',
			format = '$1',
			highlight = 1,
		},
		-- Matches: a URL in brackets: [URL]
		{
			regex = '\\[(\\w+://\\S+)\\]',
			format = '$1',
			highlight = 1,
		},
		-- Matches: a URL in curly braces: {URL}
		{
			regex = '\\{(\\w+://\\S+)\\}',
			format = '$1',
			highlight = 1,
		},
		-- Matches: a URL in angle brackets: <URL>
		{
			regex = '<(\\w+://\\S+)>',
			format = '$1',
			highlight = 1,
		},
		-- Then handle URLs not wrapped in brackets
		{
			regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
			format = '$0',
		},
		-- implicit mailto link
		{
			regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
			format = 'mailto:$0',
		},
	},

	-- Key-bindings
	keys = {
		-- Split Vertical
		{
			key = 'v',
			mods = 'CTRL|ALT',
			action = wezterm.action.SplitHorizontal {domain="CurrentPaneDomain"},
		},
		-- Split Horizontal
		{
			key = 'h',
			mods = 'CTRL|ALT',
			action = wezterm.action.SplitVertical {domain="CurrentPaneDomain"},
		},
		{ key = "h",     mods = "SHIFT|CTRL",      action = act({ ActivatePaneDirection = "Left" }) },
		{ key = "l",     mods = "SHIFT|CTRL",      action = act({ ActivatePaneDirection = "Right" }) },
		{ key = "k",     mods = "SHIFT|CTRL",      action = act({ ActivatePaneDirection = "Up" }) },
		{ key = "j",     mods = "SHIFT|CTRL",      action = act({ ActivatePaneDirection = "Down" }) },
		{ key = "h",     mods = "ALT|SHIFT|CTRL", action = act({ AdjustPaneSize = { "Left", 1 } }) },
		{ key = "l",     mods = "ALT|SHIFT|CTRL", action = act({ AdjustPaneSize = { "Right", 1 } }) },
		{ key = "k",     mods = "ALT|SHIFT|CTRL", action = act({ AdjustPaneSize = { "Up", 1 } }) },
		{ key = "j",     mods = "ALT|SHIFT|CTRL", action = act({ AdjustPaneSize = { "Down", 1 } }) },
	},
}

return config
