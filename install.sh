#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v pacman &>/dev/null; then
  exec bash "$SCRIPT_DIR/distro/arch/install.sh" "$@"
elif command -v xbps-install &>/dev/null; then
  exec bash "$SCRIPT_DIR/distro/void/install.sh" "$@"
else
  echo -e "${RED}Error: This script supports Arch Based and Void Linux only${NC}" >&2
  exit 1
fi
