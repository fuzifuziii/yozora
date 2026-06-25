#!/bin/bash
set -e

# Configuration
PKGS_DIR="./distro/arch/pkgs"
source "./distro/arch/scripts/f_utils.sh"

l_packages "$PKGS_DIR/other.txt" OTHER_PKGS

i_yay() {
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
}

echo -e "\n${BLUE}Preparing to install xone drivers...${NC}"
i_yay

yay -S --needed --noconfirm "${OTHER_PKGS[@]}"
echo -e "${GREEN}✓ Xone drivers installed successfully!${NC}"
