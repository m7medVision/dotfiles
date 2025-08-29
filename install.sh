#!/usr/bin/env bash
set -e

# Idempotent install script for Arch/Hyprland dotfiles
# Installs yay, system/AUR packages, Python libs, and systemd user services

# --- Helper functions ---
command_exists() { command -v "$1" >/dev/null 2>&1; }

# --- Install yay if missing ---
if ! command_exists yay; then
  echo "[INFO] yay not found. Installing yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
  makepkg -si --noconfirm
  popd
  rm -rf /tmp/yay
else
  echo "[INFO] yay is already installed."
fi

# --- System/AUR packages ---
PKGS=(
  hyprland waybar kitty playerctl jq python-requests python-lxml python-pip python-virtualenv \
  libnotify hyprlock lazygit alacritty fuzzel nwg-look ripgrep neovim wl-clipboard ttf-font-awesome ttf-jetbrains-mono \
  stow cmake meson cpio pkg-config git gcc g++
)

echo "[INFO] Installing system/AUR packages..."
yay -S --needed --noconfirm "${PKGS[@]}"

# --- Python libraries (global, for Scripts/) ---
PY_PKGS=(requests lxml)
echo "[INFO] Installing Python libraries..."
pip3 install --user --upgrade "${PY_PKGS[@]}"


# --- Install dotfiles using stow ---
DOTFILES_DIR="$HOME/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
  echo "[INFO] Installing dotfiles using stow..."
  pushd "$DOTFILES_DIR"
  stow --no-folding --target="$HOME" --restow --adopt --verbose *
  popd
else
  echo "[ERROR] Dotfiles directory $DOTFILES_DIR not found. Please clone your dot
files repository first."
  exit 1
fi

# --- Install Hyprland plugins ---
echo "[INFO] Installing split-monitor-workspaces plugin..."
hyprpm add https://github.com/Duckonaut/split-monitor-workspaces
hyprpm enable split-monitor-workspaces

echo "[INFO] Install complete."
