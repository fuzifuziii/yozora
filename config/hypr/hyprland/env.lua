-- Wayland --
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Hyprland --
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Theme --
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("XDG_MENU_PREFIX", "plasma-")
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
hl.env("GBM_BACKEND", "nvidia-drm")
