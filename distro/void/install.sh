#!/bin/bash

set -e

# Packages
BASE_PKGS=(inotify-tools cava gum ImageMagick python3-dbus-next wl-clipboard wl-clip-persist ark unzip unrar zip 7zip 7zip-unrar curl kde-cli-tools)
CUPS_PKGS=(cups gutenprint ghostscript)
NVIDIA_PKGS=(nvidia nvidia-libs nvidia-libs-32bit nvidia-vaapi-driver nvidia-opencl)
PIPEWIRE_PKGS=(pipewire wireplumber)
OTHER_PKGS=(xone)

XBPS_PKGS=(NetworkManager elogind xtools-minimal ly dolphin fastfetch fish-shell hyprland hyprpicker kitty plasma-workspace quickshell slurp grim systemsettings libnotify jq power-profiles-daemon)
XREPO_PKGS=(xlibre hyprland hyprpicker xdg-desktop-portal-hyprland hyprland-guiutils hyprland-protocols)
FONTS_PKGS=(noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf-extra noto-fonts-ttf)
SRC_PKGS=(tokyonight-gtk-theme wayfreeze xdg-terminal-exec hyprland-preview-share-picker)

# Logging helpers
log_info() { echo -e "${BLUE}$*${NC}"; }
log_ok() { echo -e "${GREEN}✓ $*${NC}"; }
log_warn() { echo -e "${YELLOW}$*${NC}"; }
log_err() { echo -e "${RED}$*${NC}"; }

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

set_fish_default_shell() {
  command -v fish >/dev/null 2>&1 || return 0

  echo
  log_info "Setting fish as the default shell..."
  local fish_path
  fish_path=$(command -v fish)

  if [[ "$SHELL" == "$fish_path" ]]; then
    log_ok "Fish is already the default shell"
    return 0
  fi

  if ! grep -q "^$fish_path$" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if chsh -s "$fish_path"; then
    log_ok "Default shell changed to fish"
    log_warn "⚠ Changes will take effect after logging out or rebooting"
  else
    log_warn "⚠ Failed to change shell. chsh -s $fish_path"
  fi
}

apply_tokyonight_colorscheme() {
  if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme TokyoNight || true
  else
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "Tokyo Night" || true
  fi
}

# Installation functions
i_yozora() {
  log_info "=== Starting Yozora installation ==="

  echo
  log_info "[1/3] Creating directories..."
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"

  local script_dir repo_root
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/../.." && pwd)"

  local config_apps=(fastfetch fish hypr hyprland-preview-share-picker kitty quickshell xdg-desktop-portal)
  local local_share_apps=(fuzi)

  local backup_dir="$HOME/yozora-backup"
  mkdir -p "$backup_dir/config"
  mkdir -p "$backup_dir/local"

  echo
  log_info "[2/3] Copying selected configuration files and data..."

  for app in "${config_apps[@]}"; do
    local src_config="$script_dir/config/$app"
    if [[ -d "$src_config" ]]; then
      if [[ -d "$HOME/.config/$app" ]]; then
        log_warn "Backing up old config/$app..."
        rm -rf "$backup_dir/config/$app"
        mv "$HOME/.config/$app" "$backup_dir/config/"
      fi
      cp -r "$src_config" "$HOME/.config/"
      log_ok "Updated config for: $app"
    else
      log_err "Warning: folder config/$app not found at $src_config, skipping."
    fi
  done

  for app in "${local_share_apps[@]}"; do
    local src_local="$repo_root/share/$app"
    if [[ -d "$src_local" ]]; then
      if [[ -d "$HOME/.local/share/$app" ]]; then
        log_warn "Backing up old local/share/$app..."
        rm -rf "$backup_dir/local/$app"
        mv "$HOME/.local/share/$app" "$backup_dir/local/"
      fi
      cp -r "$src_local" "$HOME/.local/share/"
      log_ok "Updated local/share for: $app"
    else
      log_err "Warning: folder for $app not found in $src_local, skipping."
    fi
  done

  mkdir -p "$HOME/.local/share/color-schemes"
  if [[ -f "$script_dir/TokyoNight.colors" ]]; then
    cp "$script_dir/TokyoNight.colors" "$HOME/.local/share/color-schemes/"
    log_ok "Color theme copied successfully"
  fi

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

# Menu
s_menu() {
  echo
  log_info "======================================="
  log_info "           CONFIGURATION MENU            "
  log_info "======================================="
  echo "1) Install Yozora"
  echo "2) Install latest NVIDIA drivers"
  echo "3) Install PipeWire"
  echo "4) Install CUPS"
  echo "5) Install Xone drivers"
  echo "6) Exit"
  log_info "=================V2.5=================="
}

main() {
  while true; do
    s_menu
    read -r -p "Enter your choice [1-6]: " choice
    case $choice in
    1) i_yozora ;;
    2) i_nvidia ;;
    3) i_pipewire ;;
    4) i_cups ;;
    5) i_xone ;;
    6)
      echo
      log_ok "Exiting. Bye!"
      exit 0
      ;;
    *) log_warn "Invalid option. Please choose between 1 and 6." ;;
    esac
  done
}

main "$@"
