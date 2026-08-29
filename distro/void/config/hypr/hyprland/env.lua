-- Wayland --
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Hyprland --
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Theme --
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("SAL_USE_VCLPLUGIN", "kf6")

-- Cursor
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_THEME", "Adwaita")

-- Gum --
hl.env("GUM_CONFIRM_PROMPT_FOREGROUND", "6;")
hl.env("GUM_CONFIRM_SELECTED_FOREGROUND", "0;")
hl.env("GUM_CONFIRM_SELECTED_BACKGROUND", "2;")
hl.env("GUM_CONFIRM_UNSELECTED_FOREGROUND", "0;")
hl.env("GUM_CONFIRM_UNSELECTED_BACKGROUND", "8")

-- NVIDIA --
hl.env("NVD_BACKEND", "direct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Yozora --
hl.env("GTK_USE_PORTAL", "1")
hl.env("TERMINAL", "xdg-terminal-exec")
hl.env("EDITOR", "nvim")

local fuzi_path = os.getenv("HOME") .. "/.local/share/fuzi"
hl.env("FUZI_PATH", fuzi_path)
hl.env("PATH", fuzi_path .. "/bin:" .. fuzi_path .. "/pg:" .. os.getenv("PATH"))
