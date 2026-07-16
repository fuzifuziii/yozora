hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
	hl.exec_cmd("uwsm-app -- /usr/lib/polkit-kde-authentication-agent-1")

	hl.exec_cmd("uwsm-app -- mako")
	hl.exec_cmd("uwsm-app -- waybar --config ~/.config/waybar/config --style ~/.config/waybar/theme/waybar.css")
	hl.exec_cmd("uwsm-app -- awww-daemon")
	hl.exec_cmd("bash -c 'sleep 0.5 && awww img ~/.local/share/fuzi/background'")
	hl.exec_cmd("uwsm-app -- bitwarden-desktop")

	hl.exec_cmd("uwsm-app -- swayosd-server")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'")
end)
