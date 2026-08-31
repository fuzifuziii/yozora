#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../common/lib.sh
source "$REPO_ROOT/common/lib.sh"

# Packages
BASE_PKGS=(python-dbus-fast inotify-tools python-gobject power-profiles-daemon wl-clipboard wl-clip-persist cava gum imagemagick base-devel)
NVIDIA_PKGS=(dkms nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils libva-nvidia-driver opencl-nvidia libxnvctrl)
PIPEWIRE_PKGS=(pipewire lib32-pipewire pipewire-alsa pipewire-pulse wireplumber)
OTHER_PKGS=(xone-dkms)

# Packages for Yozora
PACMAN_PKGS=(ly dolphin fastfetch fish hyprland hyprpicker xdg-desktop-portal-hyprland kitty plasma-workspace quickshell slurp grim systemsettings libnotify jq)
FONTS_PKGS=(noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-jetbrains-mono-nerd)
AUR_PKGS=(hyprland-preview-share-picker-git wayfreeze-git tokyonight-gtk-theme-git xdg-terminal-exec)

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

run_menu
