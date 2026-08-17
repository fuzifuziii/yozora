#!/bin/bash

set -e

# Config
REPO_URL="https://github.com/fuzifuziii/yozora.git"
CLONE_DIR=""
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

select_branch() {
  local choice

  while true; do
    echo "Select release channel:"
    echo "  1) main"
    echo "  2) dev"
    read -r -p "Choice [1-2]: " choice

    case "$choice" in
    1 | main) SELECTED_BRANCH="main"; return ;;
    2 | dev) SELECTED_BRANCH="dev"; return ;;
    *) log_err "Enter 1 (main) or 2 (dev)" ;;
    esac
  done
}

sync_repo() {
  local branch="$1"

  log_info "Cloning $REPO_URL (branch: $branch) into $CLONE_DIR..."
  git clone --branch "$branch" --single-branch "$REPO_URL" "$CLONE_DIR"
}

cleanup() {
  [[ -n "$CLONE_DIR" && -d "$CLONE_DIR" ]] || return
  rm -rf "$CLONE_DIR"
}

main() {
  local distro branch script_path

  if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}Error: Do not run this script with sudo${NC}"
    exit 1
  fi

  select_branch
  branch="$SELECTED_BRANCH"

  distro="$(detect_distro)"
  if [[ -z "$distro" ]]; then
    log_err "Could not detect distro"
    exit 1
  fi

  CLONE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/yozora.XXXXXX")"
  trap cleanup EXIT
  trap 'exit 130' INT TERM

  log_info "Detected distro: $distro; selected channel: $branch"
  sync_repo "$branch"

  script_path="$CLONE_DIR/$INSTALL_SCRIPT"
  if [[ ! -f "$script_path" ]]; then
    log_err "install.sh not found at $script_path"
    exit 1
  fi

  log_ok "Running $script_path"
  bash "$script_path" "$@"
}

main "$@"
