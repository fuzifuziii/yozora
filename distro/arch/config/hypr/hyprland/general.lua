hl.config({
	animations = {
		enabled = true,
	},
	cursor = {
		hide_on_key_press = false,
		no_hardware_cursors = true,
		no_warps = false,
	},
	decoration = {
		blur = {
			enabled = false,
		},
		shadow = {
			enabled = false,
		},
		rounding = 0,
	},
	dwindle = {
		force_split = 2,
		preserve_split = true,
	},
	ecosystem = {
		no_update_news = true,
	},
	general = {
		allow_tearing = false,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},
		gaps_in = 3,
		gaps_out = 6,
		layout = "dwindle",
		resize_on_border = false,
	},
	input = {
		touchpad = {
			natural_scroll = false,
			scroll_factor = 0.400000,
		},
		follow_mouse = 1,
		force_no_accel = true,
		kb_layout = "us,ru",
		kb_options = "grp:alt_shift_toggle",
		numlock_by_default = false,
		repeat_delay = 250,
		repeat_rate = 25,
		sensitivity = 0,
	},
	master = {
		new_status = "master",
	},
	misc = {
		anr_missed_pings = 3,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
		key_press_enables_dpms = true,
		mouse_move_enables_dpms = true,
		on_focus_under_fullscreen = 1,
	},
	xwayland = {
		force_zero_scaling = true,
	},
})
