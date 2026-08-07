#!/bin/bash

set -e

# Packages
BASE_PKGS=(imagemagick base-devel)
CUPS_PKGS=(cups gutenprint ghostscript)
NVIDIA_PKGS=(dkms nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils libva-nvidia-driver opencl-nvidia libxnvctrl)
PIPEWIRE_PKGS=(pipewire lib32-pipewire pipewire-alsa pipewire-pulse wireplumber)
OTHER_PKGS=(xone-dkms)

# Packages for Yozora
PACMAN_PKGS=(sddm dolphin fastfetch fish hyprland hyprpicker xdg-desktop-portal-hyprland kitty plasma-workspace quickshell slurp grim systemsettings libnotify jq)
FONTS_PKGS=(noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-jetbrains-mono-nerd)
AUR_PKGS=(mihomo hyprland-preview-share-picker-git wayfreeze-git tokyonight-gtk-theme-git xdg-terminal-exec)

# Helper functions
e_repos() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling multilib repository...${NC}"
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
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

# Optional functions
e_candy() {
  if ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling ILoveCandy progress bar...${NC}"
    sudo sed -i '/^# Misc options/a ILoveCandy' /etc/pacman.conf
  fi
}

# Installation functions
i_yozora() {
  echo -e "${BLUE}=== Starting Yozora installation ===${NC}"

  echo -e "\n${BLUE}[1/3] Creating directories...${NC}"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

  CONFIG_APPS=(fastfetch fish hypr hyprland-preview-share-picker kitty quickshell xdg-desktop-portal)
  LOCAL_SHARE_APPS=(fuzi)

  BACKUP_DIR="$HOME/yozora-backup"
  mkdir -p "$BACKUP_DIR/config"
  mkdir -p "$BACKUP_DIR/local"

  echo -e "\n${BLUE}[2/3] Copying selected configuration files and data...${NC}"

  for app in "${CONFIG_APPS[@]}"; do
    SRC_CONFIG="$SCRIPT_DIR/config/$app"
    if [ -d "$SRC_CONFIG" ]; then
      if [ -d "$HOME/.config/$app" ]; then
        echo -e "${YELLOW}Backing up old config/$app...${NC}"
        rm -rf "$BACKUP_DIR/config/$app"
        mv "$HOME/.config/$app" "$BACKUP_DIR/config/"
      fi
      cp -r "$SRC_CONFIG" "$HOME/.config/"
      echo -e "${GREEN}✓ Updated config for: $app${NC}"
    else
      echo -e "${RED}Warning: folder config/$app not found at $SRC_CONFIG, skipping.${NC}"
    fi
  done

  for app in "${LOCAL_SHARE_APPS[@]}"; do
    SRC_LOCAL="$REPO_ROOT/share/$app"
    if [ -d "$SRC_LOCAL" ]; then
      if [ -d "$HOME/.local/share/$app" ]; then
        echo -e "${YELLOW}Backing up old local/share/$app...${NC}"
        rm -rf "$BACKUP_DIR/local/$app"
        mv "$HOME/.local/share/$app" "$BACKUP_DIR/local/"
      fi
      cp -r "$SRC_LOCAL" "$HOME/.local/share/"
      echo -e "${GREEN}✓ Updated local/share for: $app${NC}"
    else
      echo -e "${RED}Warning: folder for $app not found in $SRC_LOCAL, skipping.${NC}"
    fi
  done

  mkdir -p "$HOME/.local/share/color-schemes"
  if [ -f "$SCRIPT_DIR/TokyoNight.colors" ]; then
    cp "$SCRIPT_DIR/TokyoNight.colors" "$HOME/.local/share/color-schemes/TokyoNight.colors"
    echo -e "${GREEN}✓ Color theme copied successfully${NC}"
  fi

  echo -e "\n${BLUE}[3/3] Installing packages...${NC}"
  e_repos
  e_candy
  sudo true

  echo -e "${BLUE}Updating system...${NC}"
  sudo pacman -Syu --noconfirm

  echo -e "${BLUE}Installing base packages...${NC}"
  sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}"

  if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing dots...${NC}"
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
  fi

  if [ ${#FONTS_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing fonts...${NC}"
    sudo pacman -S --needed --noconfirm "${FONTS_PKGS[@]}"
  fi

  if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    i_yay
    echo -e "${BLUE}Installing AUR packages...${NC}"
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
  gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true

  sudo systemctl enable --now power-profiles-daemon
  sudo systemctl enable --now mihomo

  if command -v elephant &>/dev/null; then
    elephant service enable || true
  fi

  echo -e "\n${GREEN}=== Installation completed successfully! ===${NC}"
}

i_nvidia() {
  echo -e "\n${BLUE}Preparing to install NVIDIA drivers...${NC}"
  e_repos
  sudo true
  sudo pacman -S --needed --noconfirm "${NVIDIA_PKGS[@]}"
  echo -e "${GREEN}✓ NVIDIA drivers installed successfully!${NC}"
}

i_pipewire() {
  echo -e "\n${BLUE}Preparing to install Pipewire...${NC}"
  e_repos
  sudo true
  sudo pacman -S --needed --noconfirm "${PIPEWIRE_PKGS[@]}"
  echo -e "${BLUE}Enabling Pipewire services...${NC}"
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  echo -e "${GREEN}✓ Pipewire installed successfully!${NC}"
}

i_cups() {
  echo -e "\n${BLUE}Preparing to install CUPS...${NC}"
  sudo true
  sudo pacman -S --needed --noconfirm "${CUPS_PKGS[@]}"
  echo -e "${BLUE}Enabling and starting CUPS services...${NC}"
  sudo systemctl enable --now cups
  echo -e "${GREEN}✓ CUPS drivers installed successfully!${NC}"
}

i_xone() {
  echo -e "\n${BLUE}Preparing to install other drivers/packages...${NC}"
  sudo true
  sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}"
  i_yay
  yay -S --needed --noconfirm "${OTHER_PKGS[@]}"
  echo -e "${GREEN}✓ Other packages installed successfully!${NC}"
}

# Menu
s_menu() {
  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}           CONFIGURATION MENU            ${NC}"
  echo -e "${BLUE}=======================================${NC}"
  echo -e "1) Install Yozora"
  echo -e "2) Install latest NVIDIA drivers"
  echo -e "3) Install PipeWire"
  echo -e "4) Install CUPS"
  echo -e "5) Install Xone drivers"
  echo -e "6) Exit"
  echo -e "${BLUE}=================V2.4==================${NC}"
}

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
    echo -e "\n${GREEN}Exiting. Bye!${NC}"
    exit 0
    ;;
  *) echo -e "\n${YELLOW}Invalid option. Please choose between 1 and 6.${NC}" ;;
  esac
done
