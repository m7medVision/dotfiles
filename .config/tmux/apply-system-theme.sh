#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# apply-system-theme.sh
# Detects the current system light/dark preference and applies the
# matching tmux theme to all running tmux servers.
#
# Priority: gsettings → XDG portal → Ghostty config → fallback dark
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

THEME_DIR="${HOME}/.config/tmux/themes"
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
  if [ -n "$GHOSTTY_THEME" ]; then
    THEME_FILE="${HOME}/.config/ghostty/themes/${GHOSTTY_THEME}"
    # Check if it's a directory with dark/light variants
    if [ -d "$THEME_FILE" ]; then
      # Ghostty themes that support light/dark have sub-files
      if [ -f "${THEME_FILE}/dark" ] || grep -q 'palette\s*=' <(cat "${THEME_FILE}"/* 2>/dev/null); then
        : # can't easily determine, skip
      fi
    fi
  fi
fi

# ── 4. Fallback ──────────────────────────────────────────────────────
MODE="${MODE:-dark}"

# ── Apply to all running tmux servers ────────────────────────────────
THEME_FILE="${THEME_DIR}/${MODE}.conf"

if [ ! -f "$THEME_FILE" ]; then
  echo "apply-system-theme: theme file not found: $THEME_FILE" >&2
  exit 1
fi

apply_to_server() {
  local socket="$1"
  local current
  current=$(tmux -S "$socket" show-option -gv @theme-mode 2>/dev/null || echo "")
  if [ "$current" != "$MODE" ]; then
    tmux -S "$socket" source-file "$THEME_FILE"
    tmux -S "$socket" set-option -g @theme-mode "$MODE"
    tmux -S "$socket" display-message "Theme: ${MODE}" 2>/dev/null || true
  fi
}

# Find all tmux server sockets owned by the current user
TMUX_SOCKETS=()
for dir in /tmp/tmux-*; do
  [ -d "$dir" ] || continue
  # Check ownership
  if [ -O "$dir" ]; then
    for sock in "$dir"/*; do
      [ -e "$sock" ] || continue
      TMUX_SOCKETS+=("$sock")
    done
  fi
done

if [ ${#TMUX_SOCKETS[@]} -eq 0 ]; then
  # No tmux running — nothing to do
  exit 0
fi

for socket in "${TMUX_SOCKETS[@]}"; do
  apply_to_server "$socket"
done
