#!/usr/bin/env bash
set -e

# Idempotent install/update script for Arch/Hyprland dotfiles
# Installs/updates yay, system/AUR packages, Python libs, and systemd user services

# --- Helper functions ---
command_exists() { command -v "$1" >/dev/null 2>&1; }

# --- Update system packages first ---
echo "[INFO] Updating system packages..."
sudo pacman -Syu --noconfirm

# --- Update yay if it exists, install if missing ---
if command_exists yay; then
  echo "[INFO] Updating yay..."
  yay -Syu --noconfirm yay
else
  echo "[INFO] yay not found. Installing yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
  makepkg -si --noconfirm
  popd
  rm -rf /tmp/yay
fi


# --- System/AUR packages ---
PKGS=(
  hyprland waybar kitty playerctl jq python-requests python-lxml python-pip python-virtualenv \
  libnotify hyprlock lazygit alacritty nwg-look ripgrep neovim wl-clipboard ttf-font-awesome ttf-jetbrains-mono \
  sassc gtk-engine-murrine gnome-themes-extra \
  stow cmake meson cpio pkg-config git gcc g++ \
  ttf-nerd-fonts-symbols claude-code \
  nwg-displays nodejs-lts-jod npm \
  visual-studio-code-bin claude-code github-cli luarocks \
  zsh zoxide tmux pamixer auto-cpufreq \
  docker docker-compose podman impala lazydocker \
  jome gimp
)

echo "[INFO] Installing/updating system/AUR packages..."
yay -Syu --needed --noconfirm "${PKGS[@]}"

# --- Docker setup ---
echo "[INFO] Setting up Docker..."

# Add user to docker group
if ! groups $USER | grep -q '\bdocker\b'; then
  echo "[INFO] Adding user to docker group..."
  sudo usermod -aG docker $USER
  echo "[INFO] User added to docker group. You may need to log out and back in for changes to take effect."
else
  echo "[INFO] User is already in docker group."
fi

# Enable and start Docker service
echo "[INFO] Enabling and starting Docker service..."
sudo systemctl enable docker.service
sudo systemctl start docker.service

# Enable Docker socket for user
sudo systemctl enable docker.socket

# --- Install/update npm packages ---
echo "[INFO] Installing/updating global npm packages..."
sudo npm install -g @github/copilot

# --- Python libraries (global, for Scripts/) ---
PY_PKGS=(requests lxml)
echo "[INFO] Installing/updating Python libraries..."
yay -S --needed --noconfirm "python-${PY_PKGS[@]}"

# # --- Install dotfiles using stow ---
# DOTFILES_DIR="$HOME/dotfiles"
# if [ -d "$DOTFILES_DIR" ]; then
#   echo "[INFO] Installing dotfiles using stow..."
#   pushd "$DOTFILES_DIR"
#   stow --no-folding --target="$HOME" --restow --adopt --verbose *
#   popd
# else
#   echo "[ERROR] Dotfiles directory $DOTFILES_DIR not found. Please clone your dot
# files repository first."
#   exit 1
# fi


# --- Install/update Gruvbox-GTK-Theme ---
echo "[INFO] Installing/updating Gruvbox-GTK-Theme"
cd ~
if [ -d "Gruvbox-GTK-Theme" ]; then
  echo "[INFO] Updating existing Gruvbox-GTK-Theme..."
  cd Gruvbox-GTK-Theme
  git pull
else
  echo "[INFO] Cloning Gruvbox-GTK-Theme..."
  git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git
  cd Gruvbox-GTK-Theme
fi
cd themes/
./install.sh -n "Gruvbox-Float-Border" --tweaks outline float
cd ~

# Services
echo "[INFO] Enabling system services..."
sudo systemctl enable --now auto-cpufreq.service

# --- Final system update ---
echo "[INFO] Running final system update..."
sudo pacman -Syu --noconfirm

echo "[INFO] Install/update complete."
echo "[INFO] Note: If you were added to the docker group, please log out and back in for changes to take effect."
