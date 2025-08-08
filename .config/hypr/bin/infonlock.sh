#!/bin/bash

# Get the current battery percentage
if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)
    battery_status=$(cat /sys/class/power_supply/BAT0/status)
else
    battery_percentage=100
    battery_status="Full"
fi

# Define the battery icons for each 10% segment
battery_icons=("󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹")

# Define the charging icon
charging_icon="󰂄"

# Calculate the index for the icon array
icon_index=$((battery_percentage / 10))
if [ $icon_index -gt 9 ]; then
    icon_index=9
fi

# Get the corresponding icon
battery_icon=${battery_icons[icon_index]}

# Check if the battery is charging
if [ "$battery_status" = "Charging" ]; then
    battery_icon="$charging_icon"
fi

# Get system uptime
uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
uptime_hours=$((uptime_seconds / 3600))
uptime_minutes=$(((uptime_seconds % 3600) / 60))

# Get memory usage
mem_info=$(free -m | awk 'NR==2{printf "%.0f%%", $3*100/$2}')

# Output the battery percentage and icon with additional info
echo "$battery_percentage% $battery_icon  ${uptime_hours}h${uptime_minutes}m  RAM: $mem_info"