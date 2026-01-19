#!/usr/bin/env bash
#
# link-dotfiles.sh - Links dotfiles from the repository to $HOME
#
# This script can be used on any system (without NixOS/Home-Manager)
# to set up dotfiles via symlinks.
#
# Usage:
#   ./scripts/link-dotfiles.sh           # Links all dotfiles
#   ./scripts/link-dotfiles.sh --dry-run # Shows what would be done
#   ./scripts/link-dotfiles.sh --force   # Overwrites existing files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
RESOURCES_DIR="${SCRIPT_DIR}/resources"

# Parse arguments
DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--force]"
            echo ""
            echo "Options:"
            echo "  --dry-run  Show what would be linked without making changes"
            echo "  --force    Overwrite existing files (creates backups)"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create a symlink with backup support
create_link() {
    local source="$1"
    local target="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would link: $target -> $source"
        return
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Check if target exists
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            local existing_link
            existing_link=$(readlink "$target")
            if [[ "$existing_link" == "$source" ]]; then
                log_success "Already linked: $target"
                return
            fi
        fi

        if [[ "$FORCE" == "true" ]]; then
            local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$target" "$backup"
            log_warning "Backed up: $target -> $backup"
        else
            log_warning "Skipping (exists): $target (use --force to overwrite)"
            return
        fi
    fi

    ln -s "$source" "$target"
    log_success "Linked: $target -> $source"
}

echo ""
echo "========================================"
echo "  Dotfiles Linker"
echo "========================================"
echo ""
log_info "Repository: $SCRIPT_DIR"
log_info "Dotfiles:   $DOTFILES_DIR"
log_info "Target:     $HOME"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Link shell configs
log_info "Linking shell configurations..."
create_link "${DOTFILES_DIR}/.vimrc" "$HOME/.vimrc"
create_link "${DOTFILES_DIR}/.zshrc" "$HOME/.zshrc"

# Link .config files
log_info "Linking .config files..."
create_link "${DOTFILES_DIR}/.config/starship.toml" "$HOME/.config/starship.toml"
create_link "${DOTFILES_DIR}/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
create_link "${DOTFILES_DIR}/.config/terminator/config" "$HOME/.config/terminator/config"

# Hyprland + Waybar
create_link "${DOTFILES_DIR}/.config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
create_link "${DOTFILES_DIR}/.config/hypr/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
create_link "${DOTFILES_DIR}/.config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
create_link "${DOTFILES_DIR}/.config/waybar/style.css" "$HOME/.config/waybar/style.css"
create_link "${DOTFILES_DIR}/.config/waybar/power_menu.xml" "$HOME/.config/waybar/power_menu.xml"

# Conky
create_link "${DOTFILES_DIR}/.config/conky/conky.conf" "$HOME/.config/conky/conky.conf"

# CopyQ
create_link "${DOTFILES_DIR}/.config/copyq/copyq.conf" "$HOME/.config/copyq/copyq.conf"
create_link "${DOTFILES_DIR}/.config/copyq/copyq-commands.ini" "$HOME/.config/copyq/copyq-commands.ini"
create_link "${DOTFILES_DIR}/.config/copyq/copyq_tabs.ini" "$HOME/.config/copyq/copyq_tabs.ini"

# Claude
create_link "${DOTFILES_DIR}/.claude/settings.json" "$HOME/.claude/settings.json"

# MPlayer
create_link "${DOTFILES_DIR}/.mplayer/config" "$HOME/.mplayer/config"

# Blender (version-specific)
BLENDER_VERSION="4.4"
create_link "${DOTFILES_DIR}/.config/blender/${BLENDER_VERSION}/config" "$HOME/.config/blender/${BLENDER_VERSION}/config"

# Godot
create_link "${DOTFILES_DIR}/.config/godot/editor_settings-4.4.tres" "$HOME/.config/godot/editor_settings-4.4.tres"

# GTK Themes (optional - from resources)
log_info "Linking themes (optional)..."
if [[ -d "${RESOURCES_DIR}/styling/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark" ]]; then
    create_link "${RESOURCES_DIR}/styling/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark" "$HOME/.themes/Gruvbox-Dark"

    # GTK4 theme files
    create_link "${RESOURCES_DIR}/styling/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
    create_link "${RESOURCES_DIR}/styling/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
    create_link "${RESOURCES_DIR}/styling/Themes/Gruvbox-Dark-BL-LB/Gruvbox-Dark/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
fi

echo ""
echo "========================================"
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry run complete. Run without --dry-run to apply changes."
else
    log_success "Dotfiles linking complete!"
fi
echo "========================================"
echo ""
