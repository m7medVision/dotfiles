#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# tmux-theme-watcher
# Monitors system color-scheme changes via dconf and applies the
# matching tmux theme immediately.
# ─────────────────────────────────────────────────────────────────────

APPLY_SCRIPT="${HOME}/.config/tmux/apply-system-theme.sh"

# Apply immediately on startup
"$APPLY_SCRIPT"

# Watch for changes (process substitution avoids subshell issues)
while IFS= read -r line; do
  "$APPLY_SCRIPT"
done < <(dconf watch /org/gnome/desktop/interface/color-scheme 2>/dev/null)
