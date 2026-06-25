#!/bin/bash
set -e

# Configuration
PKGS_DIR="./distro/arch/pkgs"
source "./distro/arch/scripts/f_utils.sh"

l_packages "$PKGS_DIR/nvidia.txt" NVIDIA_PKGS

# Helper functions
e_multilib() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${BLUE}Enabling multilib repository...${NC}"
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
  fi
}

echo -e "\n${BLUE}Preparing to install NVIDIA drivers...${NC}"
e_multilib
sudo true

sudo pacman -Syu --needed --noconfirm "${NVIDIA_PKGS[@]}"
echo -e "${GREEN}✓ NVIDIA drivers installed successfully!${NC}"
