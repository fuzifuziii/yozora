#!/bin/bash
set -e

# Configuration
PKGS_DIR="./distro/arch/pkgs"
source "./distro/arch/scripts/f_utils.sh"

l_packages "$PKGS_DIR/cups.txt" CUPS_PKGS

echo -e "\n${BLUE}Preparing to install CUPS drivers...${NC}"
sudo true

sudo pacman -Syu --needed --noconfirm "${CUPS_PKGS[@]}"

echo -e "${BLUE}Enabling and starting CUPS services...${NC}"
sudo systemctl enable --now cups
echo -e "${GREEN}✓ CUPS drivers installed successfully!${NC}"
