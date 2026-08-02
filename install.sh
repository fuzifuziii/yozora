#!/bin/bash

set -e

# Terminal colors
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Sudo check
if [ "$EUID" -eq 0 ]; then
  echo "Error: Do not run this script with sudo"
  exit 1
fi

# Distro check
if command -v pacman &>/dev/null; then
  echo "Detected Arch Linux"
  bash distro/arch/arch.sh
elif command -v xbps-install &>/dev/null; then
  echo "Detected Void Linux"
  bash distro/void/void.sh
else
  echo "Error: This script supports Arch Linux and Void Linux only" >&2
  exit 1
fi
