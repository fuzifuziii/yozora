#!/bin/bash

set -e

# Packages
BASE_PKGS=(python3-dbus-next wl-clipboard wl-clip-persist ark unzip unrar zip 7zip 7zip-unrar curl kde-cli-tools)
CUPS_PKGS=(cups gutenprint ghostscript)
NVIDIA_PKGS=(nvidia nvidia-libs nvidia-libs-32bit nvidia-vaapi-driver nvidia-opencl)
PIPEWIRE_PKGS=(pipewire wireplumber)
OTHER_PKGS=(xone)

# Packages for Yozora
XBPS_PKGS=(NetworkManager elogind iwd xtools-minimal sddm dolphin fastfetch fish-shell hyprland hyprpicker kitty plasma-workspace quickshell slurp grim systemsettings libnotify jq power-profiles-daemon)
XREPO_PKGS=(xlibre hyprland hyprpicker xdg-desktop-portal-hyprland hyprland-guiutils hyprland-protocols)
FONTS_PKGS=(noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf-extra noto-fonts-ttf)
SRC_PKGS=(tokyonight-gtk-theme wayfreeze xdg-terminal-exec hyprland-preview-share-picker)

# Helper functions
e_repos() {
  echo -e "${BLUE}Enabling nonfree and multilib repositories...${NC}"
  sudo xbps-install void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
  sudo xbps-install -S
}

e_xrepos() {
  echo -e "${BLUE}Enabling hyprland and xlibre repositories...${NC}"
  sudo mkdir -p /etc/xbps.d
  MIRROR_LINE="repository=https://mirror.black-hole.dev/$(xbps-uhelper arch)"
  if [ ! -f /etc/xbps.d/00-repository-main.conf ] || ! grep -qF "$MIRROR_LINE" /etc/xbps.d/00-repository-main.conf; then
    sudo cp /usr/share/xbps.d/00-repository-main.conf /etc/xbps.d/
    sudo sed -i "1i $MIRROR_LINE" /etc/xbps.d/00-repository-main.conf
  fi
  printf "repository=https://github.com/xlibre-void/xlibre/releases/latest/download/" | sudo tee /etc/xbps.d/99-repository-xlibre.conf >/dev/null
  sudo xbps-install -S
}

i_src() {
  echo -e "\n${BLUE}=== Building and installing custom packages via xbps-src ===${NC}"

  if [[ ${#SRC_PKGS[@]} -eq 0 ]]; then
    echo -e "${RED}SRC_PKGS is empty${NC}"
    return 1
  fi

  WORK_DIR="/tmp/void-packages-fuzi"

  if [[ -d "$WORK_DIR" ]]; then
    echo -e "${BLUE}Updating void-packages-fuzi repository...${NC}"
    git -C "$WORK_DIR" pull || return 1
  else
    echo -e "${BLUE}Cloning void-packages-fuzi repository...${NC}"
    git clone https://github.com/fuzifuziii/void-packages-fuzi.git "$WORK_DIR" || return 1
  fi

  pushd "$WORK_DIR" >/dev/null || return 1

  if [[ ! -d masterdir ]]; then
    echo -e "${BLUE}Bootstrapping xbps-src environment...${NC}"
    ./xbps-src binary-bootstrap || {
      popd >/dev/null
      return 1
    }
  fi

  echo -e "\n${BLUE}Building packages one by one: ${SRC_PKGS[*]}${NC}"

  local built=()
  local failed=()

  for pkg in "${SRC_PKGS[@]}"; do
    echo -e "\n${BLUE}>>> Building $pkg ...${NC}"
    if ./xbps-src pkg "$pkg"; then
      built+=("$pkg")
      echo -e "${GREEN}✓ $pkg built successfully${NC}"
    else
      failed+=("$pkg")
      echo -e "${RED}✗ Failed to build $pkg${NC}"
    fi
  done

  if [[ ${#built[@]} -eq 0 ]]; then
    echo -e "${RED}No packages were built successfully${NC}"
    popd >/dev/null
    return 1
  fi

  echo -e "\n${BLUE}Successfully built: ${built[*]}${NC}"
  if [[ ${#failed[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Failed: ${failed[*]}${NC}"
  fi

  echo -e "\n${BLUE}Installing successfully built packages...${NC}"
  sudo xbps-install -y \
    --repository=hostdir/binpkgs \
    --repository=hostdir/binpkgs/dev \
    -f "${built[@]}" || {
    popd >/dev/null
    return 1
  }

  popd >/dev/null
  echo -e "${GREEN}✓ Custom packages installed${NC}"
}

e_nm() {
  echo -e "${BLUE}Enabling NetworkManager...${NC}"
  sudo rm -rf /etc/sv/dhcpcd
  sudo rm -rf /etc/sv/iwd
  sudo ln -s /etc/sv/NetworkManager/ /var/service/
  sudo xbps-remove -y dhcpd iwd
}

i_dbus() {
  local orig="/usr/share/wayland-sessions/hyprland.desktop"
  local target="/usr/share/wayland-sessions/hyprland-dbus.desktop"

  sudo cp "$orig" "$target"
  sudo sed -i 's|^Name=.*|Name=Hyprland (D-Bus)|' "$target"
  sudo sed -i 's|^Exec=.*|Exec=dbus-run-session /usr/bin/start-hyprland|' "$target"
}

i_fonts() {
  echo -e "\n${BLUE}Preparing to install JetBrainsMono Nerd...${NC}"

  local font_dir="/usr/share/fonts/JetBrainsMonoNerd"
  local zip="/tmp/JetBrainsMono.zip"

  if fc-list | grep -qi "JetBrainsMonoNerdFont"; then
    echo -e "${YELLOW}Already installed. Skipping.${NC}"
    return 0
  fi

  curl -fLo "$zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  sudo mkdir -p "$font_dir"
  sudo unzip -o "$zip" -d "$font_dir"
  rm -f "$zip"
  sudo fc-cache -fv
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
    cp "$SCRIPT_DIR/TokyoNight.colors" "$HOME/.local/share/color-schemes/"
    echo -e "${GREEN}✓ Color theme copied successfully${NC}"
  fi

  echo -e "\n${BLUE}[3/3] Installing packages...${NC}"
  e_repos
  e_xrepos
  sudo true

  echo -e "${BLUE}Updating system...${NC}"
  sudo xbps-install -Syu

  echo -e "${BLUE}Installing base packages...${NC}"
  sudo xbps-install -y "${BASE_PKGS[@]}"

  if [ ${#XBPS_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing dots...${NC}"
    sudo xbps-install -y "${XBPS_PKGS[@]}"
    sudo xbps-install -y "${XREPO_PKGS[@]}"
    sudo ln -sf /etc/sv/iwd /var/service/
  fi

  if [ ${#SRC_PKGS[@]} -gt 0 ]; then
    i_src
  fi

  if [ ${#FONTS_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}Installing fonts...${NC}"
    sudo xbps-install -y "${FONTS_PKGS[@]}"
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
    sudo ln -sf /etc/sv/dbus /var/service/
    echo -e "${GREEN}✓ SDDM service enabled${NC}"
  fi

  i_dbus
  e_nm

  gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true
  mkdir -p ~/.icons && sudo ln -sf /usr/share/icons/Adwaita ~/.icons/default
  sudo ln -sf /etc/sv/power-profiles-daemon /var/service/

  echo -e "\n${GREEN}=== Installation completed successfully! ===${NC}"
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
  echo -e "${BLUE}Enabling Pipewire services...${NC}"
  sudo mkdir -p /etc/pipewire/pipewire.conf.d
  sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
  sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
  echo -e "${GREEN}✓ Pipewire installed successfully!${NC}"
}

i_cups() {
  echo -e "\n${BLUE}Preparing to install CUPS...${NC}"
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
  echo -e "${BLUE}=================V2.3==================${NC}"
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
