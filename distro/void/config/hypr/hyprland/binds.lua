hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"), { description = "Kitty" })
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"), { description = "Dolphin" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox"), { description = "Firefox" })
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("steam"), { description = "Steam" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("Telegram"), { description = "Telegram" })
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("discord"), { description = "Discord" })
hl.bind("SUPER + I", hl.dsp.exec_cmd("systemsettings"), { description = "Settings" })
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("fuzi-launch-tui btop"), { description = "Btop" })
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Split" })
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }), { description = "Float" })
hl.bind(
	"SUPER + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Fullscreen" }
)
hl.bind(
	"SUPER + SHIFT + F",
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "Fullscreen maximized" }
)
hl.bind("SUPER + O", hl.dsp.exec_cmd("fuzi-hyprland-window-pop"), { description = "Window pop" })
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + code:10", hl.dsp.focus({ workspace = 1 }))
hl.bind("SUPER + code:11", hl.dsp.focus({ workspace = 2 }))
hl.bind("SUPER + code:12", hl.dsp.focus({ workspace = 3 }))
hl.bind("SUPER + code:13", hl.dsp.focus({ workspace = 4 }))
hl.bind("SUPER + code:14", hl.dsp.focus({ workspace = 5 }))
hl.bind("SUPER + code:15", hl.dsp.focus({ workspace = 6 }))
hl.bind("SUPER + code:16", hl.dsp.focus({ workspace = 7 }))
hl.bind("SUPER + code:17", hl.dsp.focus({ workspace = 8 }))
hl.bind("SUPER + code:18", hl.dsp.focus({ workspace = 9 }))
hl.bind("SUPER + code:19", hl.dsp.focus({ workspace = 10 }))
hl.bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = 1, follow = false }))
hl.bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = 2, follow = false }))
hl.bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = 3, follow = false }))
hl.bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = 4, follow = false }))
hl.bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = 5, follow = false }))
hl.bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = 6, follow = false }))
hl.bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = 7, follow = false }))
hl.bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = 8, follow = false }))
hl.bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = 9, follow = false }))
hl.bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = 10, follow = false }))
hl.bind("SUPER + SHIFT + LEFT", hl.dsp.window.swap({ direction = "l" }))
hl.bind("SUPER + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }))
hl.bind("SUPER + SHIFT + UP", hl.dsp.window.swap({ direction = "u" }))
hl.bind("SUPER + SHIFT + DOWN", hl.dsp.window.swap({ direction = "d" }))
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("fuzi-launch-walker"), { description = "Apps" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("fuzi-menu"), { description = "Menu" })
hl.bind("SUPER + K", hl.dsp.exec_cmd("fuzi-menu-binds"), { description = "Binds" })
hl.bind("SUPER + Period", hl.dsp.exec_cmd("fuzi-launch-walker -m symbols"), { description = "Symbols" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("fuzi-launch-walker -m clipboard"), { description = "Clipboard" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("fuzi-cmd-screenshot smart clipboard"), { description = "Screenshot" })
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"), { description = "Hyprpicker" })

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --monitor eDP-1 --output-volume raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --monitor eDP-1 --output-volume lower"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("swayosd-client --monitor eDP-1 --output-volume mute-toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("swayosd-client --monitor eDP-1 --input-volume mute-toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("swayosd-client --monitor eDP-1 --brightness raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("swayosd-client --monitor eDP-1 --brightness lower"),
	{ locked = true, repeating = true }
)

hl.bind("SUPER + mouse:272", hl.dsp.window.drag())
hl.bind("SUPER + mouse:273", hl.dsp.window.resize())
