#!/bin/bash
set -e

# Configuration
PKGS_DIR="./distro/arch/pkgs"
source "./distro/arch/scripts/f_utils.sh"

l_packages "$PKGS_DIR/pipewire.txt" PIPEWIRE_PKGS

e_multilib() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling multilib repository...${NC}"
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
  fi
}

echo -e "\n${BLUE}Preparing to install Pipewire...${NC}"
e_multilib
sudo true

sudo pacman -Syu --needed --noconfirm "${PIPEWIRE_PKGS[@]}"

echo -e "${BLUE}Enabling and starting Pipewire user services...${NC}"
systemctl --user enable --now pipewire pipewire-pulse wireplumber
echo -e "${GREEN}✓ Pipewire installed successfully!${NC}"
