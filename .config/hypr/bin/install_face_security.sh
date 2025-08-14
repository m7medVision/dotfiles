#!/bin/bash
set -e

# Install systemd user units for face security
dest_dir="$HOME/.config/systemd/user"
mkdir -p "$dest_dir"

install -Dm644 "$HOME/dotfiles/.config/systemd/user/face-security.service" "$dest_dir/face-security.service"
install -Dm644 "$HOME/dotfiles/.config/systemd/user/face-security.timer"   "$dest_dir/face-security.timer"

# Reload systemd user units
systemctl --user daemon-reload

# Enable and start the timer
systemctl --user enable --now face-security.timer

echo "Face security systemd timer installed and started."
