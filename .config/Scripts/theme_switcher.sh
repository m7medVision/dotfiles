#!/usr/bin/env bash
# System-wide theme switcher: gruvbox-dark or gruvbox-light
# Updates: GTK (via gsettings if available), Hyprland borders, Waybar CSS vars (requires restart), Neovim colors

set -euo pipefail

THEME=${1:-gruvbox-dark}
STATE_FILE="$HOME/.config/.current_theme"

write_state() { echo "$THEME" > "$STATE_FILE"; }

apply_hypr() {
  local active inactive
  if [[ "$THEME" == "gruvbox-light" ]]; then
    active=fbf1c7 # light yellow-ish
    inactive=ebdbb2
  else
    active=fabd2f
    inactive=3c3836
  fi
  hyprctl keyword general:col.active_border "rgb(${active}) rgb(282828) rgb(282828) rgb(${active}) 45deg" || true
  hyprctl keyword general:col.inactive_border "rgb(${inactive}) rgb(${inactive}) rgb(${inactive}) rgb(${inactive}) 45deg" || true
}

apply_waybar() {
  pkill -x waybar || true
  nohup waybar >/dev/null 2>&1 &
}

apply_gtk() {
  # Expect a GTK theme named "Gruvbox-Material-Dark" or "Gruvbox-Material-Light" if installed
  local gtk_theme icon_theme cursor_theme
  if [[ "$THEME" == "gruvbox-light" ]]; then
    gtk_theme="Gruvbox-Material-Light"
  else
    gtk_theme="Gruvbox-Material-Dark"
  fi
  # Try gsettings if present
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" || true
    gsettings set org.gnome.desktop.interface color-scheme "$([[ "$THEME" == gruvbox-light ]] && echo 'default' || echo 'prefer-dark')" || true
  fi
}

apply_nvim() {
  # Send command to any running nvim instances listening on /tmp/nvim* sockets
  for sock in /tmp/nvim*/0 2>/dev/null; do
    nvim --server "$sock" --remote-send ':set background='$( [[ "$THEME" == gruvbox-light ]] && echo light || echo dark )"\n:colorscheme gruvbox\n" || true
  done
}

write_state
apply_hypr
apply_waybar
apply_gtk
apply_nvim

echo "Switched to $THEME"
