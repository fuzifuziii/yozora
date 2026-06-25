#!/bin/bash
set -e

# Configuration
PKGS_DIR="./distro/arch/pkgs"
source "./distro/arch/scripts/f_utils.sh"

l_packages "$PKGS_DIR/pacman.txt" PACMAN_PKGS
l_packages "$PKGS_DIR/fonts.txt" FONTS_PKGS
l_packages "$PKGS_DIR/aur.txt" AUR_PKGS

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

e_multilib
e_candy
sudo true # Requesting administrator privileges

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
  # Fallback for plasma 6 configs
  kwriteconfig6 --file kdeglobals --group General --key ColorScheme "Tokyo Night" || true
fi

# Enable display manager
echo -e "\n${BLUE}Enabling SDDM display manager...${NC}"
sudo systemctl enable sddm

# Disable gtk buttons
gsettings set org.gnome.desktop.wm.preferences button-layout ":"

# Enable elephant service
elephant service enable

echo -e "\n${GREEN}=== Installation completed successfully! ===${NC}"
echo -e "${BLUE}Please reboot your system when ready.${NC}\n"
