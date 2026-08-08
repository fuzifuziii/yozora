hl.layer_rule({
	match = { namespace = "fuzi-notifications" },
	no_screen_share = true,
})

hl.window_rule({
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

hl.window_rule({
	match = {
		class = "^$",
		title = "^$",
		xwayland = 1,
		float = 1,
		fullscreen = 0,
		pin = 0,
	},
	no_focus = true,
})

hl.window_rule({
	match = {
		class = "(org.telegram.desktop|AyuGram)",
	},
	no_screen_share = true,
})

hl.window_rule({
	match = {
		class = "Bitwarden",
	},
	no_screen_share = true,
})

hl.window_rule({
	match = {
		class = "^(1[p|P]assword)$",
	},
	no_screen_share = true,
	tag = "+floating-window",
})

hl.window_rule({
	match = {
		title = "(Picture.?in.?[Pp]icture)",
	},
	tag = "+pip",
})

hl.window_rule({
	match = {
		tag = "pip",
	},
	float = true,
	pin = true,
	size = "600 338",
	keep_aspect_ratio = true,
	border_size = 0,
	move = "(monitor_w-window_w-40) (monitor_h*0.04)",
})

hl.window_rule({
	match = {
		tag = "floating-window",
	},
	float = true,
	center = true,
	size = "875 600",
})

hl.window_rule({
	match = {
		class = "(org.fuzi.terminal|org.fuzi.bash|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|About|TUI.float|imv|mpv|org.kde.gwenview)",
	},
	tag = "+floating-window",
})

hl.window_rule({
	match = {
		class = "(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|sublime_text|DesktopEditors|org.gnome.Nautilus|org.kde.dolphin)",
		title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
	},
	tag = "+floating-window",
})

hl.window_rule({
	match = {
		class = "org.gnome.Calculator",
	},
	float = true,
})

hl.window_rule({
	match = {
		tag = "pop",
	},
	rounding = 8,
})

hl.window_rule({
	match = {
		tag = "noidle",
	},
	idle_inhibit = "always",
})

hl.window_rule({
	match = {
		class = "(Alacritty|kitty|com.mitchellh.ghostty)",
	},
	tag = "+terminal",
})

hl.window_rule({
	match = {
		class = "(Alactritty|kitty)",
	},
	scroll_touchpad = 1.5,
})

hl.window_rule({
	match = {
		class = "com.mitchellh.ghostty",
	},
	scroll_touchpad = 0.2,
})
