#!/bin/bash

set -e

# Config
REPO_URL="https://github.com/fuzifuziii/yozora.git"
CLONE_DIR="$HOME/.local/share/yozora"
INSTALL_SCRIPT="install.sh"

# Terminal colors
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}$*${NC}"; }
log_ok() { echo -e "${GREEN}✓ $*${NC}"; }
log_err() { echo -e "${RED}$*${NC}"; }

detect_distro() {
  local id=""
  if [[ -f /etc/os-release ]]; then
    id="$(. /etc/os-release && echo "$ID")"
  fi

  # Fallback
  if [[ -z "$id" || "$id" == "unknown" ]]; then
    if command -v xbps-install &>/dev/null; then
      id="void"
    elif command -v pacman &>/dev/null; then
      id="arch"
    fi
  fi

  echo "$id"
}

distro_to_branch() {
  case "$1" in
  void) echo "void" ;;
  arch) echo "arch" ;;
  *) echo "" ;;
  esac
}

sync_repo() {
  local branch="$1"

  if [[ -d "$CLONE_DIR/.git" ]]; then
    log_info "Updating $CLONE_DIR (branch: $branch)..."
    git -C "$CLONE_DIR" fetch origin "$branch"
    git -C "$CLONE_DIR" checkout "$branch"
    git -C "$CLONE_DIR" reset --hard "origin/$branch"
  else
    log_info "Cloning $REPO_URL (branch: $branch) into $CLONE_DIR..."
    git clone --branch "$branch" --single-branch "$REPO_URL" "$CLONE_DIR"
  fi
}

main() {
  local distro branch script_path

  distro="$(detect_distro)"
  if [[ -z "$distro" ]]; then
    log_err "Could not detect distro"
    exit 1
  fi

  branch="$(distro_to_branch "$distro")"
  if [[ -z "$branch" ]]; then
    log_err "Distro '$distro' is not supported"
    exit 1
  fi

  log_info "Detected distro: $distro -> branch: $branch"
  sync_repo "$branch"

  script_path="$CLONE_DIR/$INSTALL_SCRIPT"
  if [[ ! -f "$script_path" ]]; then
    log_err "install.sh not found at $script_path"
    exit 1
  fi

  log_ok "Running $script_path"
  exec bash "$script_path" "$@"
}

main "$@"
