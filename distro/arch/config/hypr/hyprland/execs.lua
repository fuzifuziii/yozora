hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")

	hl.exec_cmd("qs")
	hl.exec_cmd("fuzi-powerprofiles-init")
	hl.exec_cmd("bitwarden")

	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'")
end)
