#!/usr/bin/env bash
# battery-status.sh
# Reads /sys/class/power_supply/BAT*/capacity and status; prints
# Nerd Font icon + percentage for tmux status modules.
#
# Skipped: battery health, time-to-full, per-cell voltage — ponytail: add
# only if the basic chip isn't enough. Source: github.com/gpakosz/.tmux
# (the reference config that uses these same /sys paths).

set -euo pipefail

# Find a battery (BAT0, BAT1, ...). Stops on first hit.
for bat in /sys/class/power_supply/BAT*; do
  [ -f "$bat/capacity" ] || continue
  cap=$(<"$bat/capacity")
  status=$(<"$bat/status" 2>/dev/null || echo Unknown)
  break
done

if [ -z "${cap:-}" ]; then
  # No battery (desktop) — emit nothing so the module is invisible.
  exit 0
fi

# Charge tier (matches tmux-battery's icon set for visual parity)
case $cap in
  9[0-9]|100) icon="" ;;   # 󰁹 full
  7[0-9])     icon="" ;;   # 󰂀 7/8
  6[0-9])     icon="" ;;   # 󰁿 6/8
  5[0-9])     icon="" ;;   # 󰁾 5/8
  4[0-9])     icon="" ;;   # 󰁽 4/8
  3[0-9])     icon="" ;;   # 󰁼 3/8
  2[0-9])     icon="" ;;   # 󰁻 2/8
  1[0-9])     icon="" ;;   # 󰁺 1/8
  *)          icon="" ;;   # 󰂎 unknown
esac

# Charging / charged / discharging override
case $status in
  Charging)  icon="" ;;  # 󰂄
  Charged|\
  Full)      icon="" ;;  # 󰚥
  Not\ charging|\
  Pending)   : ;;  # keep tier icon
esac

printf '%s %d%%' "$icon" "$cap"
