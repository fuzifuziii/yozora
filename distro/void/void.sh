#!/bin/bash

set -e

# Packages
### BASE_PKGS=()
CUPS_PKGS=(cups gutenprint ghostscript)
NVIDIA_PKGS=(nvidia nvidia-libs nvidia-libs-32bit nvidia-vaapi-driver nvidia-opencl)
PIPEWIRE_PKGS=(pipewire wireplumber)
OTHER_PKGS=(xone)

# Packages for Yozora
XBPS_PKGS=(sddm dolphin fastfetch btop fish hyprland hyprpicker xdg-desktop-portal-hyprland kitty mako swayosd plasma-workspace waybar slurp grim polkit-kde-agent systemsettings libnotify bluetui pamixer)
FONTS_PKGS=(noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf-extra noto-fonts-ttf)

# Helper functions
e_repos() {
  echo -e "${BLUE}Enabling nonfree and multilib repositories...${NC}"
  sudo xbps-install void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
  sudo xbps-install -y
}

# Installation functions
i_yozora() {
  echo -e "${BLUE}=== Starting Yozora installation ===${NC}"

  echo -e "\n${BLUE}[1/3] Creating directories...${NC}"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/share"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

  CONFIG_APPS=(btop elephant fastfetch fish hypr hyprland-preview-share-picker kitty mako swayosd walker waybar xdg-desktop-portal)
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
    if [ -n "$SRC_LOCAL" ]; then
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
  sudo true

  echo -e "${BLUE}Updating system...${NC}"
  sudo xbps-install -Syu

  echo -e "${BLUE}Installing base packages...${NC}"
  sudo xbps-install -Sy "${BASE_PKGS[@]}"

  if [ ${#XBPS_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing dots...${NC}"
    sudo xbps-install -Sy "${XBPS_PKGS[@]}"
  fi

  if [ ${#FONTS_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing fonts...${NC}"
    sudo xbps-install -Sy "${FONTS_PKGS[@]}"
    i_fonts
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
  if [ -d /etc/sv/sddm ]; then
    sudo ln -sf /etc/sv/sddm /var/service/
    echo -e "${GREEN}✓ SDDM service enabled${NC}"
  fi

  gsettings set org.gnome.desktop.wm.preferences button-layout ":"

  if command -v elephant &>/dev/null; then
    elephant service enable || true
  fi

  echo -e "\n${GREEN}=== Installation completed successfully! ===${NC}"
}

i_fonts() {
  echo -e "\n${BLUE}Preparing to install fonts...${NC}"
  curl -fLo /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  sudo true
  sudo unzip -o /tmp/JetBrainsMono.zip -d /usr/share/fonts/JetBrainsMonoNerd/
  rm -f /tmp/JetBrainsMono.zip
  sudo fc-cache -fv
}

i_nvidia() {
  echo -e "\n${BLUE}Preparing to install NVIDIA drivers...${NC}"
  e_repos
  sudo true
  sudo xbps-install -y "${NVIDIA_PKGS[@]}"
  echo -e "${GREEN}✓ NVIDIA drivers installed successfully!${NC}"
}

i_pipewire() {
  echo -e "\n${BLUE}Preparing to install Pipewire...${NC}"
  sudo true
  sudo xbps-install -y "${PIPEWIRE_PKGS[@]}"

  echo -e "${BLUE}Enabling PipeWire service/autostart...${NC}"
  mkdir -p /etc/pipewire/pipewire.conf.d
  sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
  sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
  echo -e "${GREEN}✓ Pipewire installed successfully!${NC}"
}

i_cups() {
  echo -e "\n${BLUE}Preparing to install CUPS drivers...${NC}"
  sudo true
  sudo xbps-install -y "${CUPS_PKGS[@]}"
  echo -e "${BLUE}Enabling CUPS service...${NC}"
  if [ -d /etc/sv/cupsd ]; then
    sudo ln -sf /etc/sv/cupsd /var/service/
  fi
  echo -e "${GREEN}✓ CUPS drivers installed successfully!${NC}"
}

i_xone() {
  echo -e "\n${BLUE}Preparing to install other drivers/packages...${NC}"
  sudo true
  sudo xbps-install -y "${OTHER_PKGS[@]}"
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
  echo -e "${BLUE}=================V2.2==================${NC}"
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
