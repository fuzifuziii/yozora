#!/bin/bash

# Terminal colors
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Logging helpers
log_info() { echo -e "${BLUE}$*${NC}"; }
log_ok() { echo -e "${GREEN}✓ $*${NC}"; }
log_warn() { echo -e "${YELLOW}$*${NC}"; }
log_err() { echo -e "${RED}$*${NC}"; }

# Packages identical across every supported distro
CUPS_PKGS=(cups gutenprint ghostscript)

set_fish_default_shell() {
  command -v fish >/dev/null 2>&1 || return 0

  echo
  log_info "Setting fish as the default shell..."
  local fish_path
  fish_path=$(command -v fish)

  if [[ "$SHELL" == "$fish_path" ]]; then
    log_ok "Fish is already the default shell"
    return 0
  fi

  if ! grep -q "^$fish_path$" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if chsh -s "$fish_path"; then
    log_ok "Default shell changed to fish"
    log_warn "⚠ Changes will take effect after logging out or rebooting"
  else
    log_warn "⚠ Failed to change shell. chsh -s $fish_path"
  fi
}

apply_tokyonight_colorscheme() {
  if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme TokyoNight || true
  else
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "Tokyo Night" || true
  fi
}

# Copies the shared dotfiles (common/config/*, share/fuzi, TokyoNight.colors)
# into place. Call with the repo root as $1.
# If CONFIG_OVERRIDE_DIR is set and exists, its contents are layered on top
# of common/config after the base copy — this is how a distro overrides a
# single file (e.g. Void's execs.lua) without forking the whole config tree.
install_yozora_dotfiles() {
  local repo_root="$1"
  local config_apps=(fastfetch fish hypr hyprland-preview-share-picker kitty quickshell xdg-desktop-portal)
  local local_share_apps=(fuzi)

  local backup_dir="$HOME/yozora-backup"
  mkdir -p "$backup_dir/config"
  mkdir -p "$backup_dir/local"

  for app in "${config_apps[@]}"; do
    local src_config="$repo_root/common/config/$app"
    if [[ -d "$src_config" ]]; then
      if [[ -d "$HOME/.config/$app" ]]; then
        log_warn "Backing up old config/$app..."
        rm -rf "$backup_dir/config/$app"
        mv "$HOME/.config/$app" "$backup_dir/config/"
      fi
      cp -r "$src_config" "$HOME/.config/"
      log_ok "Updated config for: $app"
    else
      log_err "Warning: folder config/$app not found at $src_config, skipping."
    fi
  done

  if [[ -n "${CONFIG_OVERRIDE_DIR:-}" && -d "$CONFIG_OVERRIDE_DIR" ]]; then
    log_info "Applying distro-specific config overrides..."
    cp -rf "$CONFIG_OVERRIDE_DIR"/. "$HOME/.config/"
    log_ok "Config overrides applied"
  fi

  for app in "${local_share_apps[@]}"; do
    local src_local="$repo_root/share/$app"
    if [[ -d "$src_local" ]]; then
      if [[ -d "$HOME/.local/share/$app" ]]; then
        log_warn "Backing up old local/share/$app..."
        rm -rf "$backup_dir/local/$app"
        mv "$HOME/.local/share/$app" "$backup_dir/local/"
      fi
      cp -r "$src_local" "$HOME/.local/share/"
      log_ok "Updated local/share for: $app"
    else
      log_err "Warning: folder for $app not found in $src_local, skipping."
    fi
  done

  mkdir -p "$HOME/.local/share/color-schemes"
  if [[ -f "$repo_root/TokyoNight.colors" ]]; then
    cp "$repo_root/TokyoNight.colors" "$HOME/.local/share/color-schemes/"
    log_ok "Color theme copied successfully"
  fi
}

s_menu() {
  echo
  log_info "======================================="
  log_info "           CONFIGURATION MENU            "
  log_info "======================================="
  echo "1) Install Yozora"
  echo "2) Install latest NVIDIA drivers"
  echo "3) Install PipeWire"
  echo "4) Install CUPS"
  echo "5) Install Xone drivers"
  echo "6) Exit"
  log_info "=================V2.5=================="
}

# Generic menu loop. Expects i_yozora, i_nvidia, i_pipewire, i_cups and
# i_xone to already be defined by the distro-specific install.sh.
run_menu() {
  while true; do
    s_menu
    read -r -p "Enter your choice [1-6]: " choice
    case $choice in
    1) i_yozora ;;
    2) i_nvidia ;;
    3) i_pipewire ;;
    4) i_cups ;;
    5) i_xone ;;
    6)
      echo
      log_ok "Exiting. Bye!"
      exit 0
      ;;
    *) log_warn "Invalid option. Please choose between 1 and 6." ;;
    esac
  done
}
