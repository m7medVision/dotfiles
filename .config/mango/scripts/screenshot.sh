#!/usr/bin/env bash
# MangoWM screenshot helper → captures with grim, annotates with satty.
#
# Usage:  screenshot.sh region | fullscreen | window   (default: region)
# Needs:  grim slurp satty mmsg jq   (pacman -S grim slurp satty)
#
# Region mode uses slurp for interactive selection (red box) before capture.
# Esc in slurp cancels cleanly — nothing is captured.
set -euo pipefail

mode="${1:-region}"
shots_dir="${HOME}/Pictures/Screenshots"
stamp="$(date '+%Y%m%d-%H:%M:%S')"
out="${shots_dir}/satty-${stamp}.png"
mkdir -p "$shots_dir"

# Capture → annotate. Always pipes the ppm stream straight into Satty.
run_satty () {
    satty --filename - --fullscreen --output-filename "$out"
}

case "$mode" in
  region)
    # Free-draw a rectangle: click-drag to select. -d shows live dimensions,
    # -c draws a red border. Esc cancels (nothing captured).
    # NOTE: do NOT use -o (select-whole-output) or -r (snap to boxes) —
    # those make a plain click grab the full screen.
    grim -g "$(slurp -d -c '#ff0000ff')" -t ppm - | run_satty
    ;;
  fullscreen)
    grim -t ppm - | run_satty
    ;;
  window)
    # Focused client geometry via MangoWM's IPC tool.
    geom="$(mmsg get focusing-client \
              | jq -r '"\(.x),\(.y) \(.width)x\(.height)"')"
    [ -z "$geom" ] && { echo "no focused client" >&2; exit 1; }
    grim -g "$geom" -t ppm - | run_satty
    ;;
  *)
    echo "usage: $0 region|fullscreen|window" >&2
    exit 1
    ;;
esac
