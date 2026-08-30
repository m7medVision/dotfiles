#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# apply-hyprshell-theme.sh [colors.toml] [socket]
#
# Repaints the tmux status bar with the active hyprshell theme's colors,
# instead of one of catppuccin/tmux's 4 built-in flavors. It works by
# pre-setting every @thm_* variable the plugin reads before sourcing the
# plugin itself: catppuccin_tmux.conf loads its flavor file with `-o`
# ("only if unset"), so our values win and the plugin's own layout/module
# logic (window list, gitmux, battery, separators, ...) just runs on top
# of them unchanged.
#
# Run by hyprshell's theme-set (via theme-set-tmux) on every
# `theme-set <name>`. This is separate from reload-catppuccin.sh, which
# still drives the manual mocha/latte-only toggle (prefix+T, OS
# light/dark detection) — running either after the other simply repaints
# again with that source's palette.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

COLORS_TOML="${1:-$HOME/.local/state/hyprshell/current/theme/colors.toml}"
SOCKET="${2:-}"
PLUGIN_DIR="$HOME/.tmux/plugins/tmux"

[[ -f $COLORS_TOML ]] || exit 0
[[ -f "$PLUGIN_DIR/catppuccin_options_tmux.conf" ]] || exit 0

if [[ -n $SOCKET ]]; then
  tmux_cmd=(tmux -S "$SOCKET")
else
  tmux_cmd=(tmux)
fi
"${tmux_cmd[@]}" list-sessions >/dev/null 2>&1 || exit 0

color() { theme-color --file "$COLORS_TOML" "$1" 2>/dev/null; }

# mix <hexA> <hexB> <amount 0-1> — blend from A toward B
mix() {
  awk -v a="${1#\#}" -v b="${2#\#}" -v amt="$3" '
    function hv(c) { return index("0123456789abcdef", tolower(c)) - 1 }
    function pair(h, i) { return hv(substr(h, i, 1)) * 16 + hv(substr(h, i + 1, 1)) }
    BEGIN {
      ar = pair(a, 1); ag = pair(a, 3); ab = pair(a, 5)
      br = pair(b, 1); bg = pair(b, 3); bb = pair(b, 5)
      printf "#%02x%02x%02x\n", ar + (br - ar) * amt, ag + (bg - ag) * amt, ab + (bb - ab) * amt
    }'
}

mode=$(color mode)
background=$(color background); foreground=$(color foreground)
dark_background=$(color dark_background); darker_background=$(color darker_background)
lighter_background=$(color lighter_background); selection=$(color selection)
muted=$(color muted); dark_foreground=$(color dark_foreground); light_foreground=$(color light_foreground)
accent=$(color accent); red=$(color red); orange=$(color orange); yellow=$(color yellow)
green=$(color green); cyan=$(color cyan); blue=$(color blue); magenta=$(color magenta)

[[ -n $background && -n $foreground ]] || exit 0

# Fall back to accent/background/foreground for anything a theme leaves out.
red="${red:-$accent}"; orange="${orange:-$red}"; yellow="${yellow:-$accent}"
green="${green:-$accent}"; cyan="${cyan:-$accent}"; blue="${blue:-$accent}"
magenta="${magenta:-$accent}"
dark_background="${dark_background:-$background}"; darker_background="${darker_background:-$background}"
lighter_background="${lighter_background:-$background}"; selection="${selection:-$muted}"
muted="${muted:-$selection}"; dark_foreground="${dark_foreground:-$muted}"
light_foreground="${light_foreground:-$foreground}"

flavor="mocha"
[[ $mode == light ]] && flavor="latte"

# hyprshell's background/foreground ramps mirror catppuccin's base/mantle/
# crust and surface/overlay/subtext steps by construction, so most of these
# are direct role matches rather than guesses; only the 14 accent hues
# (rosewater..lavender) have no 1:1 source and are approximated.
declare -A thm=(
  [bg]="$background" [fg]="$foreground"
  [mantle]="$dark_background" [crust]="$darker_background"
  [surface_0]="$lighter_background" [surface_1]="$selection" [surface_2]="$muted"
  [overlay_0]="$dark_foreground"
  [overlay_1]="$(mix "$dark_foreground" "$light_foreground" 0.33)"
  [overlay_2]="$(mix "$dark_foreground" "$light_foreground" 0.66)"
  [subtext_0]="$light_foreground"
  [subtext_1]="$(mix "$light_foreground" "$foreground" 0.5)"
  [red]="$red" [maroon]="$(mix "$red" "$background" 0.25)"
  [peach]="$orange" [yellow]="$yellow" [green]="$green" [teal]="$cyan"
  [sky]="$(mix "$cyan" "$blue" 0.35)" [sapphire]="$(mix "$cyan" "$blue" 0.65)"
  [blue]="$blue" [lavender]="$(mix "$blue" "$foreground" 0.3)"
  [mauve]="$(mix "$magenta" "$blue" 0.45)" [pink]="$magenta"
  [flamingo]="$(mix "$foreground" "$red" 0.35)" [rosewater]="$(mix "$foreground" "$red" 0.2)"
)

"${tmux_cmd[@]}" set -g @catppuccin_flavor "$flavor"
"${tmux_cmd[@]}" set -g @catppuccin_reset "true"
"${tmux_cmd[@]}" source-file "$PLUGIN_DIR/catppuccin_options_tmux.conf"

for key in "${!thm[@]}"; do
  "${tmux_cmd[@]}" set -g "@thm_${key}" "${thm[$key]}"
done

# Force a rebuild of chip colors baked in by the module builder (see the
# NOTE in catppuccin-gitmux.conf / catppuccin-battery.conf).
for m in session gitmux host battery directory date_time; do
  for v in \
    "@catppuccin_${m}_color" "@catppuccin_${m}_icon" "@catppuccin_${m}_text" \
    "@catppuccin_status_${m}" \
    "@catppuccin_status_${m}_icon_bg" "@catppuccin_status_${m}_icon_fg" \
    "@catppuccin_status_${m}_text_bg" "@catppuccin_status_${m}_text_fg"; do
    "${tmux_cmd[@]}" set -ugq "$v" 2>/dev/null || true
  done
done

"${tmux_cmd[@]}" source-file "$PLUGIN_DIR/catppuccin_tmux.conf"
"${tmux_cmd[@]}" source-file "$HOME/.config/tmux/catppuccin-gitmux.conf"
"${tmux_cmd[@]}" source-file "$HOME/.config/tmux/catppuccin-battery.conf"
