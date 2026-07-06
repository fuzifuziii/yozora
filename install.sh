#!/bin/bash

set -e

# Packages
CUPS_PKGS=(cups gutenprint ghostscript)
NVIDIA_LATEST_PKGS=(dkms nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils libva-nvidia-driver opencl-nvidia libxnvctrl)
NVIDIA_580_PKGS=(dkms lib32-nvidia-580xx-utils nvidia-580xx-open-dkms nvidia-580xx-settings nvidia-580xx-utils opencl-nvidia-580xx libxnvctrl-580xx lib32-opencl-nvidia-580xx)
PIPEWIRE_PKGS=(pipewire lib32-pipewire pipewire-alsa pipewire-pulse wireplumber)
OTHER_PKGS=(xone-dkms)

# Packages for Yozora
PACMAN_PKGS=(base-devel sddm dolphin fastfetch btop fish hyprland hyprpicker xdg-desktop-portal-hyprland kitty mako swayosd plasma-workspace uwsm waybar slurp grim polkit-kde-agent systemsettings swaybg libnotify bluetui wiremix pamixer)
FONTS_PKGS=(noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-jetbrains-mono-nerd)
AUR_PKGS=(walker elephant-all hyprland-preview-share-picker-git wayfreeze-git tokyonight-gtk-theme-git xdg-terminal-exec)

# Terminal colors
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# System checks
if [ "$EUID" -eq 0 ]; then
  echo "Do not run this script with sudo"
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
  export DISTRO=$ID
else
  echo "Cannot determine OS distribution."
  exit 1
fi

if [[ "$DISTRO" != "arch" ]]; then
  echo "This consolidated script currently supports Arch Linux only (due to pacman/yay logic)."
  exit 1
fi

# 3. Helper functions
e_multilib() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling multilib repository...${NC}"
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
  fi
}

e_candy() {
  if ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling ILoveCandy progress bar...${NC}"
    sudo sed -i '/^# Misc options/a ILoveCandy' /etc/pacman.conf
  fi
}

i_yay() {
  if ! command -v yay >/dev/null 2>&1; then
    echo -e "${BLUE}yay not found. Installing...${NC}"
    rm -rf /tmp/yay-build && mkdir -p /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build/yay
    pushd /tmp/yay-build/yay >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf /tmp/yay-build

    if ! command -v yay >/dev/null 2>&1; then
      echo -e "${RED}Error: Failed to install yay.${NC}"
      exit 1
    fi
    echo -e "${GREEN}✓ yay installed successfully!${NC}"
  fi
}

# Installation functions

i_yozora() {
  echo -e "${BLUE}=== Starting Yozora installation ===${NC}"

  echo -e "\n${BLUE}[1/3] Creating directories...${NC}"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"

  CONFIG_APPS=(btop elephant fastfetch fish hypr hyprland-preview-share-picker kitty mako swayosd uwsm walker waybar xdg-desktop-portal)
  LOCAL_SHARE_APPS=(fuzi)

  BACKUP_DIR="$HOME/yozora-backup"
  mkdir -p "$BACKUP_DIR/config"
  mkdir -p "$BACKUP_DIR/local"

  echo -e "\n${BLUE}[2/3] Copying selected configuration files and data...${NC}"

  for app in "${CONFIG_APPS[@]}"; do
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
  done

  for app in "${LOCAL_SHARE_APPS[@]}"; do
    if [ -d "local/$app" ]; then
      if [ -d "$HOME/.local/share/$app" ]; then
        echo -e "${YELLOW}Backing up old local/share/$app...${NC}"
        rm -rf "$BACKUP_DIR/local/$app"
        mv "$HOME/.local/share/$app" "$BACKUP_DIR/local/"
      fi
      cp -r "local/$app" "$HOME/.local/share/"
      echo -e "${GREEN}✓ Updated local/share for: $app${NC}"
    else
      echo -e "${RED}Warning: folder local/$app not found, skipping.${NC}"
    fi
  done

  mkdir -p "$HOME/.local/share/color-schemes"
  if [ -f "TokyoNight.colors" ]; then
    cp "TokyoNight.colors" "$HOME/.local/share/color-schemes/TokyoNight.colors"
    echo -e "${GREEN}✓ Color theme copied successfully${NC}"
  fi

  echo -e "\n${BLUE}[3/3] Installing packages...${NC}"
  e_multilib
  e_candy
  sudo true

  echo -e "${BLUE}Updating system...${NC}"
  sudo pacman -Syu --noconfirm

  if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing packages via pacman...${NC}"
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
  fi

  if [ ${#FONTS_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing fonts via pacman...${NC}"
    sudo pacman -S --needed --noconfirm "${FONTS_PKGS[@]}"
  fi

  if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    i_yay
    echo -e "${BLUE}Installing AUR packages via yay...${NC}"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
  fi

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
        echo -e "${YELLOW}⚠ Failed to change shell. chsh -s $FISH_PATH${NC}"
      fi
    else
      echo -e "${GREEN}✓ Fish is already the default shell${NC}"
    fi
  fi

  if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme TokyoNight || true
  else
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "Tokyo Night" || true
  fi

  echo -e "\n${BLUE}Enabling SDDM display manager...${NC}"
  sudo systemctl enable sddm
  gsettings set org.gnome.desktop.wm.preferences button-layout ":"

  if command -v elephant &>/dev/null; then
    elephant service enable || true
  fi

  echo -e "\n${GREEN}=== Installation completed successfully! ===${NC}"
}

i_nvidiaL() {
  echo -e "\n${BLUE}Preparing to install NVIDIA drivers...${NC}"
  e_multilib
  sudo true
  sudo pacman -Syu --needed --noconfirm "${NVIDIA_LATEST_PKGS[@]}"
  echo -e "${GREEN}✓ NVIDIA drivers installed successfully!${NC}"
}

i_pipewire() {
  echo -e "\n${BLUE}Preparing to install Pipewire...${NC}"
  e_multilib
  sudo true
  sudo pacman -Syu --needed --noconfirm "${PIPEWIRE_PKGS[@]}"
  echo -e "${BLUE}Enabling and starting Pipewire user services...${NC}"
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  echo -e "${GREEN}✓ Pipewire installed successfully!${NC}"
}

i_cups() {
  echo -e "\n${BLUE}Preparing to install CUPS drivers...${NC}"
  sudo true
  sudo pacman -Syu --needed --noconfirm "${CUPS_PKGS[@]}"
  echo -e "${BLUE}Enabling and starting CUPS services...${NC}"
  sudo systemctl enable --now cups
  echo -e "${GREEN}✓ CUPS drivers installed successfully!${NC}"
}

i_xone() {
  echo -e "\n${BLUE}Preparing to install other drivers/packages...${NC}"
  i_yay
  yay -S --needed --noconfirm "${OTHER_PKGS[@]}"
  echo -e "${GREEN}✓ Other packages installed successfully!${NC}"
}

# CachyOS repository
c_menu() {
  while true; do
    s_cachy
    read -rp "Enter your choice [1-3]: " choice

    case "$choice" in
    1)
      i_cachy
      ;;
    2)
      i_nvidia580
      ;;
    3)
      break
      ;;
    *)
      echo -e "${YELLOW}Invalid option. Please choose between 1 and 3.${NC}"
      ;;
    esac
  done
}

i_cachy() {
  echo -e "\n${BLUE}Checking CachyOS repository...${NC}"

  TMP_DIR=$(mktemp -d)

  curl -Ls https://mirror.cachyos.org/cachyos-repo.tar.xz -o "$TMP_DIR/cachyos-repo.tar.xz"
  tar -xf "$TMP_DIR/cachyos-repo.tar.xz" -C "$TMP_DIR"

  pushd "$TMP_DIR/cachyos-repo" >/dev/null

  if grep -q "^\[cachyos" /etc/pacman.conf; then
    echo -e "${YELLOW}CachyOS repository detected. Removing...${NC}"
    sudo ./cachyos-repo.sh --remove
    echo -e "${GREEN}✓ CachyOS repository removed successfully!${NC}"
  else
    echo -e "${BLUE}CachyOS repository not found. Installing...${NC}"
    sudo ./cachyos-repo.sh
    echo -e "${GREEN}✓ CachyOS repository installed successfully!${NC}"
  fi

  popd >/dev/null
  rm -rf "$TMP_DIR"
}

i_nvidia580() {
  echo -e "\n${BLUE}Preparing to install NVIDIA drivers...${NC}"
  e_multilib
  sudo true
  sudo pacman -Syu --needed --noconfirm "${NVIDIA_580_PKGS[@]}"
  echo -e "${GREEN}✓ NVIDIA drivers installed successfully!${NC}"
}

# Main menu
s_menu() {
  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}           CONFIGURATION MENU            ${NC}"
  echo -e "${BLUE}=======================================${NC}"
  echo -e "1) Install Yozora"
  echo -e "2) CachyOS menu"
  echo -e "3) Install latest NVIDIA drivers"
  echo -e "4) Install PipeWire"
  echo -e "5) Install CUPS"
  echo -e "6) Install Xone drivers"
  echo -e "7) Exit"
  echo -e "${BLUE}=================V2.0==================${NC}"
}

s_cachy() {
  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}        CACHYOS REPOSITORY MENU         ${NC}"
  echo -e "${BLUE}=======================================${NC}"

  if pacman -Qq cachyos-keyring &>/dev/null; then
    echo -e "1) Uninstall CachyOS repository"
  else
    echo -e "1) Install CachyOS repository"
  fi

  echo -e "2) Install 580x NVIDIA drivers"
  echo -e "3) Back"
  echo -e "${BLUE}=================V2.0==================${NC}"
}

while true; do
  s_menu
  read -r -p "Enter your choice [1-7]: " choice
  case $choice in
  1) i_yozora ;;
  2) c_menu ;;
  3) i_nvidiaL ;;
  4) i_pipewire ;;
  5) i_cups ;;
  6) i_xone ;;
  7)
    echo -e "\n${GREEN}Exiting. Bye!${NC}"
    exit 0
    ;;
  *) echo -e "\n${YELLOW}Invalid option. Please choose between 1 and 7.${NC}" ;;
  esac
done
