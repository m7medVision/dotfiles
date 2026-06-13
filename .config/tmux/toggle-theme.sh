#!/bin/bash
# Toggle between tmux light and dark themes in the current session

CURRENT=$(tmux show-option -gv @theme-mode 2>/dev/null || echo "dark")
THEME_DIR=~/.config/tmux/themes

if [ "$CURRENT" = "dark" ]; then
  tmux source-file "$THEME_DIR/light.conf"
  tmux set-option -g @theme-mode "light"
  tmux display-message "☀️  Light"
else
  tmux source-file "$THEME_DIR/dark.conf"
  tmux set-option -g @theme-mode "dark"
  tmux display-message "🌙  Dark"
fi
