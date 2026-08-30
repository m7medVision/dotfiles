#!/usr/bin/env bash
# gitmux-status.sh <dir>
# Pass-through to the gitmux binary using ~/.gitmux.conf.
# Kept as a wrapper so future extras (e.g. ahead/behind coloring, untracked
# count) can be added without touching the Catppuccin module.

set -euo pipefail

dir="${1:-.}"
timeout_flag=()
if [[ "${GITMUX_TIMEOUT:-2s}" =~ ^[0-9]+(ms|s|m)?$ ]]; then
  timeout_flag=(-timeout "${GITMUX_TIMEOUT:-2s}")
fi

exec gitmux "${timeout_flag[@]}" -cfg "$HOME/.gitmux.conf" "$dir"
