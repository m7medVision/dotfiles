#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# reload-catppuccin.sh <flavor> [socket]
#
# Switches the Catppuccin flavor live and re-applies the full theme,
# including the custom git module. Used by:
#   - apply-system-theme.sh   (startup detection + multi-server)
#   - toggle-theme.sh         (prefix + T)
#   - client-dark/light-theme hooks (instant terminal-driven switching)
#
#   flavor : mocha | macchiato | frappe | latte   (default: mocha)
#   socket : optional tmux server socket path     (default: current server)
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

FLAVOR="${1:-mocha}"
SOCKET="${2:-}"
PLUGIN_DIR="$HOME/.tmux/plugins/tmux"

if [ ! -f "$PLUGIN_DIR/catppuccin_options_tmux.conf" ]; then
  echo "reload-catppuccin: Catppuccin not installed at $PLUGIN_DIR (skipping)" >&2
  exit 0
fi

if [ -n "$SOCKET" ]; then
  tmux_cmd=(tmux -S "$SOCKET")
else
  tmux_cmd=(tmux)
fi

# Modules whose per-module option state must be cleared before a rebuild.
# (Catppuccin's built-in reset leaves @catppuccin_<module>_color and the
#  @catppuccin_status_<module>_icon_bg vars in place; because the module
#  builder uses -o / guards on empty, they never get refreshed, so the
#  colored icon chips keep the previous flavor's colors. Clearing them
#  here forces a clean rebuild.)
MODULES=(session gitmux host battery directory date_time)

# 1. Stage the new flavor and request a full reset of the palette/options.
"${tmux_cmd[@]}" set -g @catppuccin_flavor "$FLAVOR"
"${tmux_cmd[@]}" set -g @catppuccin_reset "true"

# 2. Options file runs the reset (unsets @thm_*, @catppuccin_*) then sets defaults.
"${tmux_cmd[@]}" source-file "$PLUGIN_DIR/catppuccin_options_tmux.conf"

# 3. Clear stale per-module state so icon colors are rebuilt for the new flavor.
for m in "${MODULES[@]}"; do
  for v in \
    "@catppuccin_${m}_color" "@catppuccin_${m}_icon" "@catppuccin_${m}_text" \
    "@catppuccin_status_${m}" \
    "@catppuccin_status_${m}_icon_bg" "@catppuccin_status_${m}_icon_fg" \
    "@catppuccin_status_${m}_text_bg" "@catppuccin_status_${m}_text_fg"; do
    "${tmux_cmd[@]}" set -ugq "$v" 2>/dev/null || true
  done
done

# 4. Main config re-sources the new flavor's palette and rebuilds all styling.
"${tmux_cmd[@]}" source-file "$PLUGIN_DIR/catppuccin_tmux.conf"

# 5. Rebuild the custom gitmux module with the new flavor's colors.
"${tmux_cmd[@]}" source-file "$HOME/.config/tmux/catppuccin-gitmux.conf"

# 6. Re-apply the battery override (text source, chip icon).
"${tmux_cmd[@]}" source-file "$HOME/.config/tmux/catppuccin-battery.conf"
