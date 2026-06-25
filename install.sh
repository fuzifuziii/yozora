#!/bin/bash

set -e

# Terminal colors
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Sudo
if [ "$EUID" -eq 0 ]; then
  echo "Do not run this script with sudo"
  exit 1
fi

# Distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  export DISTRO=$ID
else
  echo "Cannot determine OS distribution."
  exit 1
fi

if [[ "$DISTRO" != "arch" && "$DISTRO" != "fedora" ]]; then
  echo "This script only supports Arch Linux and Fedora."
  exit 1
fi

SCRIPTS_DIR="./distro/$DISTRO/scripts"

run_script() {
  local script_name="$1"
  local target="$SCRIPTS_DIR/$script_name"

  if [ -f "$target" ]; then
    bash "$target"
  else
    echo -e "${RED}Error: Script $target not found!${NC}"
  fi
}

# Interactive menu
show_menu() {
  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}         CONFIGURATION MENU            ${NC}"
  echo -e "${BLUE}=======================================${NC}"
  echo -e "1) Install Yozora"
  echo -e "2) Install latest NVIDIA drivers"
  echo -e "3) Install pipewire"
  echo -e "4) Install CUPS"
  echo -e "5) Install other packages"
  echo -e "6) Exit"
  echo -e "${BLUE}=================V2.0===================${NC}"
}

while true; do
  show_menu
  read -r -p "Enter your choice [1-6]: " choice
  case $choice in
  1) run_script "i_yozora.sh" ;;
  2) run_script "i_nvidia.sh" ;;
  3) run_script "i_pipewire.sh" ;;
  4) run_script "i_cups.sh" ;;
  5) run_script "i_other.sh" ;;
  6)
    echo -e "\n${GREEN}Exiting. Bye!${NC}"
    exit 0
    ;;
  *) echo -e "\n${YELLOW}Invalid option. Please choose between 1 and 6.${NC}" ;;
  esac
done
