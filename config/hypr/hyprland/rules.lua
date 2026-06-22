hl.layer_rule({
	match = { namespace = "notifications" },
	no_screen_share = true,
})

hl.layer_rule({
	match = { namespace = "selection" },
	no_anim = true,
})

hl.layer_rule({
	match = { namespace = "walker" },
	no_anim = true,
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
		class = "org.telegram.desktop",
	},
	no_screen_share = true,
})

hl.window_rule({
	match = {
		title = "playit",
	},
	float = true,
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
		class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)",
	},
	tag = "+chromium-based-browser",
})

hl.window_rule({
	match = {
		class = "([fF]irefox|zen|librewolf)",
	},
	tag = "+firefox-based-browser",
})

hl.window_rule({
	match = {
		tag = "chromium-based-browser",
	},
	float = false,
	opacity = "1 0.97",
})

hl.window_rule({
	match = {
		tag = "firefox-based-browser",
	},
	opacity = "1 0.97",
})

hl.window_rule({
	match = {
		initial_title = "((?i)(?:[a-z0-9-]+.)*youtube.com_/|app.zoom.us_/wc/home)",
	},
	opacity = "1.0 1.0",
})

hl.window_rule({
	match = {
		class = "^(jetbrains-.*)$",
		title = "^(splash)$",
		float = 1,
	},
	tag = "+jetbrains-splash",
})

hl.window_rule({
	match = {
		tag = "jetbrains-splash",
	},
	center = true,
	no_focus = true,
	border_size = 0,
})

hl.window_rule({
	match = {
		class = "^(jetbrains-.*)",
		title = "^()$",
		float = 1,
	},
	tag = "+jetbrains",
})

hl.window_rule({
	match = {
		tag = "jetbrains",
	},
	center = true,
	stay_focused = true,
	border_size = 0,
})

hl.window_rule({
	match = {
		class = "^(jetbrains-.*)",
		title = "^()$",
		float = 1,
	},
	min_size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
	match = {
		class = "^(jetbrains-.*)$",
		title = "^(win.*)$",
		float = 1,
	},
	no_initial_focus = true,
})

hl.window_rule({
	match = {
		class = "^(jetbrains-.*)$",
	},
	no_follow_mouse = true,
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
	opacity = "1 1",
	move = "(monitor_w-window_w-40) (monitor_h*0.04)",
})

hl.window_rule({
	match = {
		class = "qemu",
	},
	opacity = "1 1",
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
		class = "(org.fuzi.nmtui|org.fuzi.bluetui|org.fuzi.impala|org.fuzi.wiremix|org.fuzi.btop|org.fuzi.terminal|org.fuzi.bash|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|Omarchy|About|TUI.float|imv|mpv|org.kde.gwenview|org.fuzi.playit)",
	},
	tag = "+floating-window",
})

hl.window_rule({
	match = {
		class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
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
		class = "org.fuzi.screensaver",
	},
	fullscreen = true,
	float = true,
})

hl.window_rule({
	match = {
		class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
	},
	opacity = "1 1",
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

hl.window_rule({
	match = {
		class = "^steamwebhelper$",
		title = ".*Notification.*",
	},
	float = true,
	pin = true,
	no_focus = true,
})
