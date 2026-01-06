#!/bin/sh
# Toggle wl-mirror between HDMI-A-1 and eDP-1

if pgrep -x "wl-mirror" > /dev/null; then
    # wl-mirror is running, kill it
    pkill -x "wl-mirror"
else
    # wl-mirror is not running, start it
    wl-mirror --fullscreen-output "HDMI-A-1" "eDP-1"
fi
