#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# apply-system-theme.sh
# Detects the current system light/dark preference and applies the
# matching Catppuccin flavor to all running tmux servers.
#
#   dark  -> mocha
#   light -> latte
#
# Priority: gsettings → XDG portal → Ghostty config → fallback dark
#
# Note: for terminals that report their theme via OSC (e.g. Ghostty),
# the client-light/dark-theme hooks in .tmux.conf handle live switching
# with no latency. This script covers startup and terminals that don't.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

MODE=""

# ── 1. gsettings (GNOME / GTK) ───────────────────────────────────────
COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
if [[ "$COLOR_SCHEME" == *"dark"* ]]; then
  MODE="dark"
elif [[ "$COLOR_SCHEME" == *"light"* ]]; then
  MODE="light"
fi

# ── 2. XDG desktop portal (fallback) ─────────────────────────────────
if [ -z "$MODE" ] && command -v gdbus &>/dev/null; then
  PORTAL_VAL=$(gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.portal.Settings.Read \
    "org.freedesktop.appearance" "color-scheme" 2>/dev/null || true)
  # 1 = dark, 2 = light, 0 = default/no-preference
  if [[ "$PORTAL_VAL" == *"1"* ]]; then
    MODE="dark"
  elif [[ "$PORTAL_VAL" == *"2"* ]]; then
    MODE="light"
  fi
fi

# ── 3. Ghostty theme file (fallback) ─────────────────────────────────
if [ -z "$MODE" ] && [ -f "${HOME}/.config/ghostty/config" ]; then
  GHOSTTY_THEME=$(grep -i '^theme\s*=' "${HOME}/.config/ghostty/config" 2>/dev/null | head -1 | cut -d= -f2 | xargs || true)
  case "$GHOSTTY_THEME" in
    *light*|*Light*|*[Ll]atte*) MODE="light" ;;
    ?*)                         MODE="dark" ;;
  esac
fi

# ── 4. Fallback ──────────────────────────────────────────────────────
MODE="${MODE:-dark}"

# Map to a Catppuccin flavor
if [ "$MODE" = "light" ]; then
  FLAVOR="latte"
else
  FLAVOR="mocha"
fi

# ── Apply to all running tmux servers ────────────────────────────────
RELOAD="${HOME}/.config/tmux/reload-catppuccin.sh"

apply_to_server() {
  local socket="$1"
  local current
  current=$(tmux -S "$socket" show-option -gv @catppuccin_flavor 2>/dev/null || echo "")
  if [ "$current" != "$FLAVOR" ]; then
    "$RELOAD" "$FLAVOR" "$socket"
    tmux -S "$socket" display-message "Catppuccin: ${FLAVOR}" 2>/dev/null || true
  fi
}

# Find all tmux server sockets owned by the current user
TMUX_SOCKETS=()
for dir in /tmp/tmux-*; do
  [ -d "$dir" ] || continue
  [ -O "$dir" ] || continue
  for sock in "$dir"/*; do
    [ -e "$sock" ] || continue
    TMUX_SOCKETS+=("$sock")
  done
done

# No running server → nothing to apply to (flavor comes from .tmux.conf on next start)
[ ${#TMUX_SOCKETS[@]} -eq 0 ] && exit 0

for socket in "${TMUX_SOCKETS[@]}"; do
  apply_to_server "$socket"
done
