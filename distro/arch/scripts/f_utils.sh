#!/bin/bash

# Configuration loader
l_packages() {
  local file="$1"
  if [ -f "$file" ]; then
    mapfile -t "$2" < <(grep -v -E '^(\s*#|\s*$)' "$file")
  else
    eval "$2=()"
  fi
}

# Pacman tweaks
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

# Yay installer
i_yay() {
  if ! command -v yay >/dev/null 2>&1; then
    echo -e "${BLUE}yay not found. Installing...${NC}"
    rm -rf /tmp/yay-build && mkdir -p /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build/yay
    pushd /tmp/yay-build/yay >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf /tmp/yay-build
  fi
}
