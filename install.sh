#!/bin/bash

##################################
# Configuration and package list #
##################################

set -e

PACMAN_PKGS=(
  "sddm"
  "base-devel"
  "dolphin"
  "fastfetch"
  "btop"
  "fish"
  "hyprland"
  "hyprpicker"
  "xdg-desktop-portal-hyprland"
  "kitty"
  "mako"
  "swayosd"
  "plasma-workspace"
  "uwsm"
  "waybar"
  "slurp"
  "grim"
  "polkit-kde-agent"
  "systemsettings"
  "swaybg"
  "libnotify"
  "bluetui"
  "wiremix"
)

FONTS_PKGS=(
  "noto-fonts"
  "noto-fonts-cjk"
  "noto-fonts-emoji"
  "noto-fonts-extra"
  "ttf-jetbrains-mono-nerd"
)

AUR_PKGS=(
  "walker"
  "elephant-all"
  "hyprland-preview-share-picker-git"
  "wayfreeze-git"
  "tokyonight-gtk-theme-git"
  "xdg-terminal-exec"
)

NVIDIA_PKGS=(
  "dkms"
  "nvidia-open-dkms"
  "nvidia-utils"
  "nvidia-settings"
  "lib32-nvidia-utils"
)

PIPEWIRE_PKGS=(
  "pipewire"
  "lib32-pipewire"
  "pipewire-alsa"
  "pipewire-pulse"
  "wireplumber"
)

CUPS_PKGS=(
  "cups"
  "gutenprint"
  "ghostscript"
)

OTHER_PKGS=(
  "xone-dkms"
)

# Terminal colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

##############
# Validation #
##############

# Sudo
if [ "$EUID" -eq 0 ]; then
  echo "Do not run this script with sudo"
  exit 1
fi

# Distro
if ! command -v pacman >/dev/null 2>&1; then
  echo "This script is for Arch Linux only"
  exit 1
fi

####################
# Helper functions #
####################

enable_multilib() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling multilib repository...${NC}"
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
  fi
}

init_sudo() {
  echo -e "${BLUE}Requesting administrator privileges...${NC}"
  sudo true
}

################
# Core install #
################

install_core() {
  echo -e "${BLUE}=== Starting Yozora installation ===${NC}"

  # Create directories
  echo -e "\n${BLUE}[1/3] Creating directories...${NC}"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"

  # Create backup directories
  APPS_TO_CONFIG=(btop elephant fastfetch fish hypr hyprland-preview-share-picker kitty mako swayosd uwsm walker waybar)

  BACKUP_DIR="$HOME/hypr-backup"
  mkdir -p "$BACKUP_DIR/config"
  mkdir -p "$BACKUP_DIR/local"

  echo -e "\n${BLUE}[2/3] Copying selected configuration files and data...${NC}"

  for app in "${APPS_TO_CONFIG[@]}"; do
    if [ -d "config/$app" ]; then
      if [ -d "$HOME/.config/$app" ]; then
        echo -e "${YELLOW}Backing up old config/$app...${NC}"
        rm -rf "$BACKUP_DIR/config/$app"
        mv "$HOME/.config/$app" "$BACKUP_DIR/config/"
      fi

      cp -r "config/$app" "$HOME/.config/"
      echo -e "${GREEN}✓ Updated config for: $app${NC}"
    else
      echo -e "${RED}Warning: folder config/$app not found, skipping.${NC}"
    fi

    if [ -d "local/$app" ]; then
      if [ -d "$HOME/.local/share/$app" ]; then
        echo -e "${YELLOW}Backing up old local/share/$app...${NC}"
        rm -rf "$BACKUP_DIR/local/$app"
        mv "$HOME/.local/share/$app" "$BACKUP_DIR/local/"
      fi

      cp -r "local/$app" "$HOME/.local/share/"
      echo -e "${GREEN}✓ Updated local/share for: $app${NC}"
    fi
  done

  # Install theme for plasma
  mkdir -p "$HOME/.local/share/color-schemes"
  if [ -f "TokyoNight.colors" ]; then
    cp "TokyoNight.colors" "$HOME/.local/share/color-schemes/TokyoNight.colors"
    echo -e "${GREEN}✓ Color theme copied successfully${NC}"
  fi

  # Install packages
  echo -e "\n${BLUE}[3/3] Installing packages...${NC}"

  enable_multilib
  init_sudo

  echo -e "${BLUE}Updating system...${NC}"
  sudo pacman -Syu --noconfirm

  if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing packages via pacman...${NC}"
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
    sudo pacman -S --needed --noconfirm "${FONTS_PKGS[@]}"
  fi

  if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    if ! command -v yay >/dev/null 2>&1; then
      echo -e "${BLUE}yay not found. Installing...${NC}"

      rm -rf /tmp/yay-build
      mkdir -p /tmp/yay-build

      git clone https://aur.archlinux.org/yay.git /tmp/yay-build/yay

      pushd /tmp/yay-build/yay >/dev/null
      makepkg -si --noconfirm
      popd >/dev/null

      rm -rf /tmp/yay-build

      if ! command -v yay >/dev/null 2>&1; then
        echo "Error: Failed to install yay."
        exit 1
      fi

      echo -e "${GREEN}✓ yay installed successfully!${NC}"
    fi

    echo -e "${BLUE}Installing AUR packages via yay...${NC}"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
  fi

  # Set fish as the default shell
  if command -v fish >/dev/null 2>&1; then
    echo -e "\n${BLUE}Setting fish as the default shell...${NC}"
    FISH_PATH=$(command -v fish)

    if [ "$SHELL" != "$FISH_PATH" ]; then
      if ! grep -q "^$FISH_PATH$" /etc/shells; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
      fi

      if chsh -s "$FISH_PATH"; then
        echo -e "${GREEN}✓ Default shell changed to fish${NC}"
        echo -e "${YELLOW}⚠ Changes will take effect after logging out or rebooting${NC}"
      else
        echo -e "${YELLOW}⚠ Failed to change shell. You may need to enter your password manually${NC}"
        echo -e "${YELLOW}   Or run manually: chsh -s $FISH_PATH${NC}"
      fi
    else
      echo -e "${GREEN}✓ Fish is already the default shell${NC}"
    fi
  fi

  # Apply the colorscheme if the utility is available
  if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme TokyoNight || true
  else
    # Fallback for headless environments/Plasma 6 configs
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "Tokyo Night" || true
  fi

  # Enable display manager
  echo -e "\n${BLUE}Enabling SDDM display manager...${NC}"
  sudo systemctl enable sddm

  # Disable gtk buttons
  gsettings set org.gnome.desktop.wm.preferences button-layout ":"

  # Enable elephant service
  elephant service enable

  echo -e "\n${GREEN}=== Core installation completed successfully! ===${NC}"
  echo -e "${BLUE}Please reboot your system when ready.${NC}\n"
}

####################
# Interactive menu #
####################

show_menu() {
  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}         CONFIGURATION MENU            ${NC}"
  echo -e "${BLUE}=======================================${NC}"
  echo -e "1) Install Yozora"
  echo -e "2) Install latest NVIDIA drivers"
  echo -e "3) Install pipewire"
  echo -e "4) Install CUPS"
  echo -e "5) Install other packages"
  echo -e "6) Exit"
  echo -e "${BLUE}=================V1.9===================${NC}"
}

while true; do
  show_menu
  read -r -p "Enter your choice [1-6]: " choice
  case $choice in
  1)
    install_core
    ;;
  2)
    echo -e "\n${BLUE}Preparing to install NVIDIA drivers...${NC}"
    enable_multilib
    init_sudo
    sudo pacman -Sy --needed --noconfirm "${NVIDIA_PKGS[@]}"
    echo -e "${GREEN}✓ NVIDIA drivers installed successfully!${NC}"
    ;;
  3)
    echo -e "\n${BLUE}Preparing to install Pipewire...${NC}"
    enable_multilib
    init_sudo
    sudo pacman -Sy --needed --noconfirm "${PIPEWIRE_PKGS[@]}"
    echo -e "${BLUE}Enabling and starting Pipewire user services...${NC}"
    systemctl --user enable --now pipewire pipewire-pulse wireplumber
    echo -e "${GREEN}✓ Pipewire installed successfully!${NC}"
    ;;
  4)
    echo -e "\n${BLUE}Preparing to install CUPS drivers...${NC}"
    init_sudo
    sudo pacman -Sy --needed --noconfirm "${CUPS_PKGS[@]}"
    echo -e "${BLUE}Enabling and starting CUPS services...${NC}"
    init_sudo
    sudo systemctl enable --now cups
    echo -e "${GREEN}✓ CUPS drivers installed successfully!${NC}"
    ;;
  5)
    echo -e "\n${BLUE}Preparing to install xone drivers...${NC}"
    yay -S --needed --noconfirm "${OTHER_PKGS[@]}"
    echo -e "${GREEN}✓ Xone drivers installed successfully!${NC}"
    ;;
  6)
    echo -e "\n${GREEN}Exiting. Bye!${NC}"
    exit 0
    ;;
  *)
    echo -e "\n${YELLOW}Invalid option. Please choose between 1 and 6.${NC}"
    ;;
  esac
done

```
