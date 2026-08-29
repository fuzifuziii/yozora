#!/bin/bash

set -e

# Packages
BASE_PKGS=(python-dbus-fast inotify-tools python-gobject power-profiles-daemon wl-clipboard wl-clip-persist cava gum imagemagick base-devel)
CUPS_PKGS=(cups gutenprint ghostscript)
NVIDIA_PKGS=(dkms nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils libva-nvidia-driver opencl-nvidia libxnvctrl)
PIPEWIRE_PKGS=(pipewire lib32-pipewire pipewire-alsa pipewire-pulse wireplumber)
OTHER_PKGS=(xone-dkms)

# Packages for Yozora
PACMAN_PKGS=(ly dolphin fastfetch fish hyprland hyprpicker xdg-desktop-portal-hyprland kitty plasma-workspace quickshell slurp grim systemsettings libnotify jq)
FONTS_PKGS=(noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-jetbrains-mono-nerd)
AUR_PKGS=(hyprland-preview-share-picker-git wayfreeze-git tokyonight-gtk-theme-git xdg-terminal-exec)

# Logging helpers
log_info() { echo -e "${BLUE}$*${NC}"; }
log_ok() { echo -e "${GREEN}✓ $*${NC}"; }
log_warn() { echo -e "${YELLOW}$*${NC}"; }
log_err() { echo -e "${RED}$*${NC}"; }

# Systemd service helper
enable_service() {
  local unit="$1.service"
  local start="${2:-true}"

  if ! systemctl cat "$unit" &>/dev/null; then
    log_warn "$unit not found, skipping"
    return 0
  fi

  if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
    log_warn "$1 is already enabled, skipping"
    return 0
  fi

  if [[ "$start" == "true" ]]; then
    sudo systemctl enable --now "$unit" && log_ok "$1 service enabled and started" || {
      log_err "Failed to enable $1 service"
      return 1
    }
  else
    sudo systemctl enable "$unit" && log_ok "$1 service enabled" || {
      log_err "Failed to enable $1 service"
      return 1
    }
  fi
}

# Helper functions
e_repos() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    log_info "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
  fi
}

i_yay() {
  command -v yay >/dev/null 2>&1 && return 0

  log_info "yay not found. Installing..."
  rm -rf /tmp/yay-build && mkdir -p /tmp/yay-build
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build/yay
  pushd /tmp/yay-build/yay >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf /tmp/yay-build

  if ! command -v yay >/dev/null 2>&1; then
    log_err "Error: Failed to install yay."
    exit 1
  fi
  log_ok "yay installed successfully!"
}

e_candy() {
  if ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    log_info "Enabling ILoveCandy progress bar..."
    sudo sed -i '/^# Misc options/a ILoveCandy' /etc/pacman.conf
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
  mkdir -p "$HOME/.local/share/color-schemes"
  cp TokyoNight.colors $HOME/.local/share/color-schemes/

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
    cp "$script_dir/TokyoNight.colors" "$HOME/.local/share/color-schemes/TokyoNight.colors"
    log_ok "Color theme copied successfully"
  fi

  echo
  log_info "[3/3] Installing packages..."
  e_repos
  e_candy
  sudo true

  log_info "Updating system..."
  sudo pacman -Syu --noconfirm

  log_info "Installing base packages..."
  sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}"

  if [[ ${#PACMAN_PKGS[@]} -gt 0 ]]; then
    log_info "Installing dots..."
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
  fi

  if [[ ${#FONTS_PKGS[@]} -gt 0 ]]; then
    log_info "Installing fonts..."
    sudo pacman -S --needed --noconfirm "${FONTS_PKGS[@]}"
  fi

  if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
    i_yay
    log_info "Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
  fi

  set_fish_default_shell
  apply_tokyonight_colorscheme

  echo
  log_info "Enabling LY display manager..."
  enable_service ly@tty2.service

  gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true
  enable_service power-profiles-daemon

  echo
  log_ok "=== Installation completed successfully! ==="
}

i_nvidia() {
  echo
  log_info "Preparing to install NVIDIA drivers..."
  e_repos
  sudo true
  sudo pacman -S --needed --noconfirm "${NVIDIA_PKGS[@]}"
  log_ok "NVIDIA drivers installed successfully!"
}

i_pipewire() {
  echo
  log_info "Preparing to install Pipewire..."
  e_repos
  sudo true
  sudo pacman -S --needed --noconfirm "${PIPEWIRE_PKGS[@]}"
  log_info "Enabling Pipewire services..."
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  log_ok "Pipewire installed successfully!"
}

i_cups() {
  echo
  log_info "Preparing to install CUPS..."
  sudo true
  sudo pacman -S --needed --noconfirm "${CUPS_PKGS[@]}"
  log_info "Enabling and starting CUPS services..."
  enable_service cups
  log_ok "CUPS drivers installed successfully!"
}

i_xone() {
  echo
  log_info "Preparing to install other drivers/packages..."
  sudo true
  sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}"
  i_yay
  yay -S --needed --noconfirm "${OTHER_PKGS[@]}"
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
