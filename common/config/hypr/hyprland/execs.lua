hl.on("hyprland.start", function()
	-- Session
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")

	-- Yozora
	hl.exec_cmd("quickshell")
	hl.exec_cmd("fuzi-powerprofiles-init")
	hl.exec_cmd("fuzi-portal-backend")

	-- Theme
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'")
end)
