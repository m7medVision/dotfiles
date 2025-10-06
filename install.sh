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
  sassc gtk-engine-murrine gnome-themes-extra \
  stow cmake meson cpio pkg-config git gcc g++ \
  ttf-nerd-fonts-symbols claude-code vicinae-bin \
  nwg-displays nodejs-lts-jod npm \
  visual-studio-code-bin claude-code github-cli luarocks

)

echo "[INFO] Installing system/AUR packages..."
yay -S --needed --noconfirm "${PKGS[@]}"

# --- Python libraries (global, for Scripts/) ---
PY_PKGS=(requests lxml)
echo "[INFO] Installing Python libraries..."
yay -S --needed --noconfirm "python-${PKGS[@]}"

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
hyprpm update
hyprpm add https://github.com/Duckonaut/split-monitor-workspaces
hyprpm enable split-monitor-workspaces

# --- Install Gruvbox GTK Theme ---
echo "[INFO] Installing Gruvbox GTK Theme..."
TMP_DIR="/tmp/gruvbox-gtk-theme"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if [ ! -d "$HOME/.themes/Gruvbox" ]; then
  git clone --depth=1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme "$TMP_DIR/repo"
  pushd "$TMP_DIR/repo"
  # Install dark + light, standard size, libadwaita link, default accent (blue)
  ./install.sh --color dark light --size standard --libadwaita --dest "$HOME/.themes"
  popd
else
  echo "[INFO] Gruvbox GTK already present under ~/.themes. Skipping build."
fi

# Apply GTK theme if gsettings is available (defaults to dark)
if command -v gsettings >/dev/null 2>&1; then
  echo "[INFO] Applying GTK theme via gsettings..."
  gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox"
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true
fi

# Flatpak overrides (optional)
if command -v flatpak >/dev/null 2>&1; then
  echo "[INFO] Setting Flatpak overrides for GTK themes/icons..."
  sudo flatpak override --filesystem=$HOME/.themes || true
  sudo flatpak override --filesystem=xdg-config/gtk-4.0 || true
fi

rm -rf "$TMP_DIR"

echo "[INFO] Install complete."
