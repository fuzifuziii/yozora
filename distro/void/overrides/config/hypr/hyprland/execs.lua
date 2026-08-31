hl.on("hyprland.start", function()
	hl.exec_cmd("pipewire")
	hl.exec_cmd("dbus-update-activation-environment --all")

	hl.exec_cmd("quickshell")
	hl.exec_cmd("fuzi-powerprofiles-init")
	hl.exec_cmd("fuzi-portal-backend")

	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'")
end)
