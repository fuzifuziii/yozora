#!/bin/bash
# Installs the fuzi file-picker as an xdg-desktop-portal FileChooser backend.
#
# What this does:
#   1. Copies fuzi.portal into /usr/share/xdg-desktop-portal/portals/
#      (system-wide, needs root — this is how xdg-desktop-portal discovers
#      that a "fuzi" backend implementing FileChooser exists at all).
#   2. Generates a per-user D-Bus service activation file pointing at
#      portal-backend.py, so the session bus starts it on demand the first
#      time something calls org.freedesktop.impl.portal.desktop.fuzi —
#      no separate runit/systemd service needed. Generated fresh here
#      (not copied from a template) so the absolute path is always correct
#      for whoever runs this script, on whatever machine.
#   3. Restarts the session bus itself so it picks up the new service file
#      immediately. dbus-broker (the default on Arch) does not reliably
#      pick up new/changed service files via ReloadConfig alone — only a
#      restart of the bus guarantees it re-scans the service directories.
#
# Run as your normal user; it will ask for sudo only for step 1.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BACKEND_PATH="$PLUGIN_DIR/portal-backend.py"

PORTAL_DEST="/usr/share/xdg-desktop-portal/portals/fuzi.portal"
SERVICE_DEST_DIR="$HOME/.local/share/dbus-1/services"
SERVICE_DEST="$SERVICE_DEST_DIR/org.freedesktop.impl.portal.desktop.fuzi.service"

if [[ ! -f "$BACKEND_PATH" ]]; then
  echo "error: expected portal-backend.py at $BACKEND_PATH" >&2
  exit 1
fi

if ! python3 -c "import dbus_fast" 2>/dev/null; then
  echo "error: python module 'dbus_fast' not found for $(command -v python3)." >&2
  echo "  Void:  sudo xbps-install python3-dbus-fast   (or) pip install --user dbus-fast" >&2
  exit 1
fi

chmod +x "$BACKEND_PATH"

echo "-> installing portal declaration to $PORTAL_DEST (sudo)"
sudo install -Dm644 "$SCRIPT_DIR/fuzi.portal" "$PORTAL_DEST"

echo "-> generating D-Bus service activation file at $SERVICE_DEST"
mkdir -p "$SERVICE_DEST_DIR"
# No sudo here — this file lives entirely inside $HOME and must be owned by
# the user, not root. Unquoted heredoc so $BACKEND_PATH expands to a real
# absolute path right now, for this user, on this machine — Exec= itself
# cannot contain shell variables, it is exec'd directly, not via a shell.
tee "$SERVICE_DEST" > /dev/null << EOF
[D-BUS Service]
Name=org.freedesktop.impl.portal.desktop.fuzi
Exec=$BACKEND_PATH
EOF

echo "-> restarting the session bus so it re-scans service directories"
if systemctl --user list-units --all 2>/dev/null | grep -q dbus-broker.service; then
  systemctl --user restart dbus-broker.service
elif systemctl --user list-units --all 2>/dev/null | grep -q dbus.service; then
  systemctl --user restart dbus.service
else
  echo "   (no systemd user unit for the session bus found — falling back to ReloadConfig,"
  echo "    which may not pick up a brand-new service file; log out/in if verification fails)"
  dbus-send --session --dest=org.freedesktop.DBus --type=method_call \
    /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig >/dev/null 2>&1 || true
fi

echo "-> restarting xdg-desktop-portal so it re-reads installed portals"
if command -v systemctl >/dev/null && systemctl --user list-unit-files 2>/dev/null | grep -q xdg-desktop-portal; then
  systemctl --user restart xdg-desktop-portal.service
else
  pkill -u "$USER" -f 'xdg-desktop-portal$' 2>/dev/null || true
  echo "   (no systemd user unit found — killed any running xdg-desktop-portal;"
  echo "    it will be respawned by D-Bus activation on next portal request)"
fi

cat <<MSG

Done. Verify with:
  quickshell ipc call shell ping           # confirm quickshell IPC is up
  gdbus call --session \\
    --dest org.freedesktop.impl.portal.desktop.fuzi \\
    --object-path /org/freedesktop/portal/desktop \\
    --method org.freedesktop.DBus.Properties.Get \\
    org.freedesktop.impl.portal.FileChooser version

Then trigger a real file dialog from a sandboxed/portal-using app (Flatpak,
GTK4 app, firefox "Open File", etc.) and the fuzi FilePicker overlay should
appear. Watch backend logs live with:
  journalctl --user -f 2>/dev/null | grep fuzi-portal
or, if journald isn't capturing session-bus-activated processes on your
setup, run the backend once in foreground manually to see logs directly:
  python3 "$BACKEND_PATH"
MSG
