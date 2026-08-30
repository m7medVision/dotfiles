#!/bin/bash
# Toggle between Catppuccin Latte (light) and Mocha (dark).

CURRENT=$(tmux show-option -gv @catppuccin_flavor 2>/dev/null || echo "mocha")

if [ "$CURRENT" = "latte" ]; then
  NEW="mocha"
  MSG="🌙  Mocha"
else
  NEW="latte"
  MSG="☀️  Latte"
fi

~/.config/tmux/reload-catppuccin.sh "$NEW"
tmux display-message "$MSG"
