#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../common/lib.sh
source "$REPO_ROOT/common/lib.sh"

# Void's config differs from the shared common/config in exactly one file
# (hypr/hyprland/execs.lua — systemd vs runit/pipewire startup). Everything
# else is copied as-is from common/config; this dir is layered on top.
CONFIG_OVERRIDE_DIR="$SCRIPT_DIR/overrides/config"

# Packages
BASE_PKGS=(inotify-tools cava gum ImageMagick python3-dbus-next wl-clipboard wl-clip-persist ark unzip unrar zip 7zip 7zip-unrar curl kde-cli-tools)
NVIDIA_PKGS=(nvidia nvidia-libs nvidia-libs-32bit nvidia-vaapi-driver nvidia-opencl)
PIPEWIRE_PKGS=(pipewire wireplumber)
OTHER_PKGS=(xone)

XBPS_PKGS=(NetworkManager elogind xtools-minimal ly dolphin fastfetch fish-shell hyprland hyprpicker kitty plasma-workspace quickshell slurp grim systemsettings libnotify jq power-profiles-daemon)
XREPO_PKGS=(xlibre hyprland hyprpicker xdg-desktop-portal-hyprland hyprland-guiutils hyprland-protocols)
FONTS_PKGS=(noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf-extra noto-fonts-ttf)
SRC_PKGS=(tokyonight-gtk-theme wayfreeze xdg-terminal-exec hyprland-preview-share-picker)

# Runit service helpers
enable_service() {
  local name="$1"
  local dir="${2:-/etc/sv/$name}"

  if [[ ! -d "$dir" ]]; then
    log_warn "$name service dir not found ($dir), skipping"
    return 0
  fi

  if [[ -L "/var/service/$name" ]]; then
    log_warn "$name is already enabled, skipping"
    return 0
  fi

  if sudo ln -sf "$dir" /var/service/; then
    log_ok "$name service enabled"
  else
    log_err "Failed to enable $name service"
    return 1
  fi
}

remove_service_dir() {
  local name="$1"
  local dir="/etc/sv/$name"

  if [[ -d "$dir" ]]; then
    log_info "Removing $name service..."
    sudo rm -rf "$dir"
  else
    log_warn "$name service dir not found, skipping"
  fi
}

# Helper functions
e_repos() {
  log_info "Enabling nonfree and multilib repositories..."
  sudo xbps-install void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
  sudo xbps-install -S
}

e_xrepos() {
  log_info "Enabling hyprland and xlibre repositories..."
  sudo mkdir -p /etc/xbps.d
  local mirror_line="repository=https://mirror.black-hole.dev/$(xbps-uhelper arch)"
  if [[ ! -f /etc/xbps.d/00-repository-main.conf ]] || ! grep -qF "$mirror_line" /etc/xbps.d/00-repository-main.conf; then
    sudo cp /usr/share/xbps.d/00-repository-main.conf /etc/xbps.d/
    sudo sed -i "1i $mirror_line" /etc/xbps.d/00-repository-main.conf
  fi
  printf "repository=https://github.com/xlibre-void/xlibre/releases/latest/download/" | sudo tee /etc/xbps.d/99-repository-xlibre.conf >/dev/null
  sudo xbps-install -S
}

i_src() {
  echo
  log_info "=== Building and installing custom packages via xbps-src ==="
  if [[ ${#SRC_PKGS[@]} -eq 0 ]]; then
    log_err "SRC_PKGS is empty"
    return 1
  fi

  local work_dir="/tmp/void-packages-fuzi"
  local force_rebuild="${FORCE_REBUILD:-0}"

  if [[ -d "$work_dir" ]]; then
    log_info "Updating void-packages-fuzi repository..."
    git -C "$work_dir" pull || return 1
  else
    log_info "Cloning void-packages-fuzi repository..."
    git clone https://github.com/fuzifuziii/void-packages-fuzi.git "$work_dir" || return 1
  fi

  pushd "$work_dir" >/dev/null || return 1

  if [[ ! -d masterdir ]]; then
    log_info "Bootstrapping xbps-src environment..."
    ./xbps-src binary-bootstrap || {
      popd >/dev/null
      return 1
    }
  fi

  is_pkg_built() {
    local pkg="$1"
    local hit
    hit=$(find hostdir/binpkgs hostdir/binpkgs/dev -maxdepth 1 -type f \
      -name "${pkg}-[0-9]*.xbps" 2>/dev/null | head -n1)
    [[ -n "$hit" ]]
  }

  echo
  log_info "Building packages one by one: ${SRC_PKGS[*]}"
  local built=()
  local failed=()
  local skipped=()

  for pkg in "${SRC_PKGS[@]}"; do
    if [[ "$force_rebuild" -ne 1 ]] && is_pkg_built "$pkg"; then
      log_warn "⏭ $pkg already built, skipping (set FORCE_REBUILD=1 to rebuild)"
      skipped+=("$pkg")
      built+=("$pkg")
      continue
    fi

    echo
    log_info ">>> Building $pkg ..."
    if ./xbps-src pkg "$pkg"; then
      built+=("$pkg")
      log_ok "$pkg built successfully"
    else
      failed+=("$pkg")
      log_err "✗ Failed to build $pkg"
    fi
  done

  if [[ ${#built[@]} -eq 0 ]]; then
    log_err "No packages were built successfully"
    popd >/dev/null
    return 1
  fi

  echo
  log_info "Successfully built: ${built[*]}"
  [[ ${#skipped[@]} -gt 0 ]] && log_warn "Skipped (already built): ${skipped[*]}"
  [[ ${#failed[@]} -gt 0 ]] && log_warn "Failed: ${failed[*]}"

  echo
  log_info "Installing successfully built packages..."
  sudo xbps-install -y \
    --repository=hostdir/binpkgs \
    --repository=hostdir/binpkgs/dev \
    -f "${built[@]}" || {
    popd >/dev/null
    return 1
  }

  popd >/dev/null
  log_ok "Custom packages installed"
}

e_nm() {
  log_info "Enabling NetworkManager..."

  if [[ ! -d /etc/sv/NetworkManager ]]; then
    log_err "NetworkManager service not found in /etc/sv, is it installed?"
    return 1
  fi

  enable_service NetworkManager

  remove_service_dir dhcpcd
  remove_service_dir iwd

  local pkgs_to_remove=()
  for pkg in dhcpcd iwd; do
    if xbps-query -p pkgver "$pkg" &>/dev/null; then
      pkgs_to_remove+=("$pkg")
    fi
  done

  if [[ ${#pkgs_to_remove[@]} -gt 0 ]]; then
    log_info "Removing packages: ${pkgs_to_remove[*]}"
    sudo xbps-remove -yF "${pkgs_to_remove[@]}" || {
      log_err "Failed to remove packages"
      return 1
    }
  else
    log_warn "dhcpcd/iwd packages not installed, nothing to remove"
  fi

  log_ok "NetworkManager setup complete"
}

i_dbus() {
  local orig="/usr/share/wayland-sessions/hyprland.desktop"
  local target="/usr/share/wayland-sessions/hyprland-dbus.desktop"

  if [[ ! -f "$orig" ]]; then
    log_err "Original session file not found: $orig"
    return 1
  fi

  if [[ -f "$target" ]]; then
    log_warn "$target already exists, skipping."
    return 0
  fi

  if ! command -v /usr/bin/start-hyprland &>/dev/null && [[ ! -x /usr/bin/start-hyprland ]]; then
    log_warn "Warning: /usr/bin/start-hyprland not found, proceeding anyway"
  fi

  sudo cp "$orig" "$target" || {
    log_err "Failed to copy $orig to $target"
    return 1
  }

  sudo sed -i 's|^Name=.*|Name=Hyprland (D-Bus)|' "$target" || {
    log_err "Failed to update Name in $target"
    sudo rm -f "$target"
    return 1
  }

  sudo sed -i 's|^Exec=.*|Exec=dbus-run-session /usr/bin/start-hyprland|' "$target" || {
    log_err "Failed to update Exec in $target"
    sudo rm -f "$target"
    return 1
  }

  log_ok "Created $target"
}

i_fonts() {
  echo
  log_info "Preparing to install JetBrainsMono Nerd..."
  local font_dir="/usr/share/fonts/JetBrainsMonoNerd"
  local zip="/tmp/JetBrainsMono.zip"

  if fc-list | grep -qi "JetBrainsMonoNerdFont"; then
    log_warn "Already installed. Skipping."
    return 0
  fi

  log_info "Downloading JetBrainsMono Nerd Font..."
  if ! curl -fLo "$zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
    log_err "Failed to download font archive"
    rm -f "$zip"
    return 1
  fi

  sudo mkdir -p "$font_dir" || {
    log_err "Failed to create $font_dir"
    rm -f "$zip"
    return 1
  }

  if ! sudo unzip -o "$zip" -d "$font_dir"; then
    log_err "Failed to unzip font archive"
    rm -f "$zip"
    return 1
  fi

  rm -f "$zip"
  sudo fc-cache -fv

  if fc-list | grep -qi "JetBrainsMonoNerdFont"; then
    log_ok "JetBrainsMono Nerd Font installed"
  else
    log_warn "Warning: font installed but not found in fc-list, check manually"
  fi
}

link_icon_theme() {
  if [[ ! -d /usr/share/icons/Adwaita ]]; then
    log_warn "Adwaita icons not found, skipping"
    return 0
  fi

  mkdir -p ~/.icons
  if [[ -L ~/.icons/default ]]; then
    log_warn "default icon theme already linked, skipping"
  else
    ln -sf /usr/share/icons/Adwaita ~/.icons/default || log_err "Failed to link default icon theme"
  fi
}

# Installation functions
i_yozora() {
  log_info "=== Starting Yozora installation ==="

  echo
  log_info "[1/3] Creating directories..."
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"

  echo
  log_info "[2/3] Copying selected configuration files and data..."
  install_yozora_dotfiles "$REPO_ROOT"

  echo
  log_info "[3/3] Installing packages..."
  e_repos
  e_xrepos
  sudo true

  log_info "Updating system..."
  sudo xbps-install -Syu

  log_info "Installing base packages..."
  sudo xbps-install -y "${BASE_PKGS[@]}"

  if [[ ${#XBPS_PKGS[@]} -gt 0 ]]; then
    log_info "Installing dots..."
    sudo xbps-install -y "${XBPS_PKGS[@]}"
    sudo xbps-install -y "${XREPO_PKGS[@]}"
    sudo ln -sf /etc/sv/iwd /var/service/
  fi

  if [[ ${#SRC_PKGS[@]} -gt 0 ]]; then
    i_src
  fi

  if [[ ${#FONTS_PKGS[@]} -gt 0 ]]; then
    log_info "Installing fonts..."
    sudo xbps-install -y "${FONTS_PKGS[@]}"
    i_fonts
  fi

  set_fish_default_shell
  apply_tokyonight_colorscheme

  echo
  log_info "Enabling LY display manager..."
  enable_service ly
  enable_service dbus

  i_dbus
  e_nm

  enable_service power-profiles-daemon
  enable_service mihomo

  link_icon_theme

  gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true

  echo
  log_ok "=== Installation completed successfully! ==="
}

i_nvidia() {
  echo
  log_info "Preparing to install NVIDIA drivers..."
  e_repos
  sudo true
  sudo xbps-install -y "${NVIDIA_PKGS[@]}"
  log_ok "NVIDIA drivers installed successfully!"
}

i_pipewire() {
  echo
  log_info "Preparing to install Pipewire..."
  sudo true
  sudo xbps-install -y "${PIPEWIRE_PKGS[@]}"
  log_info "Enabling Pipewire services..."
  sudo mkdir -p /etc/pipewire/pipewire.conf.d
  sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
  sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
  log_ok "Pipewire installed successfully!"
}

i_cups() {
  echo
  log_info "Preparing to install CUPS..."
  sudo true
  sudo xbps-install -y "${CUPS_PKGS[@]}"
  log_info "Enabling CUPS service..."
  enable_service cupsd
  log_ok "CUPS drivers installed successfully!"
}

i_xone() {
  echo
  log_info "Preparing to install other drivers/packages..."
  sudo true
  sudo xbps-install -y "${OTHER_PKGS[@]}"
  log_ok "Other packages installed successfully!"
}

run_menu
