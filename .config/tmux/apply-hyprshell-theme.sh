#!/usr/bin/env bash
set -euo pipefail

colors_file="${1:-$HOME/.local/state/hyprshell/current/theme/colors.toml}"
plugin="$HOME/.tmux/plugins/tmux"
[[ -f $colors_file && -f $plugin/catppuccin_tmux.conf ]] || exit 0
tmux show-options -g >/dev/null 2>&1 || exit 0

palette=$("$HOME/.local/share/hyprshell/bin/theme-color" --file "$colors_file" --all)
declare -A colors
while IFS=$'\t' read -r key value; do
  [[ -n $key ]] && colors[$key]=$value
done <<< "$palette"

[[ ${colors[background]:-} =~ ^#[[:xdigit:]]{6}$ && ${colors[foreground]:-} =~ ^#[[:xdigit:]]{6}$ ]] || exit 1
flavor=mocha
[[ ${colors[mode]:-dark} != light ]] || flavor=latte
tmux set -g @catppuccin_flavor "$flavor"

for mapping in bg:background fg:foreground mantle:dark_background crust:darker_background \
  surface_0:lighter_background surface_1:selection surface_2:muted \
  overlay_0:dark_foreground overlay_1:muted overlay_2:light_foreground \
  subtext_0:light_foreground subtext_1:foreground red:red maroon:red \
  peach:orange yellow:yellow green:green teal:cyan sky:cyan sapphire:blue \
  blue:blue lavender:accent mauve:magenta pink:magenta flamingo:red rosewater:foreground; do
  key=${mapping%%:*}
  value=${colors[${mapping#*:}]:-${colors[foreground]}}
  [[ $value =~ ^#[[:xdigit:]]{6}$ ]] || exit 1
  tmux set -g "@thm_$key" "$value"
done

tmux source-file "$plugin/catppuccin_tmux.conf"
