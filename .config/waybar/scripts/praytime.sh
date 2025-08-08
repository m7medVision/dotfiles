#!/bin/bash

# Waybar script for prayer times
# Usage: ./praytime.sh [city]

CITY=${1:-"Muscat"}
SCRIPT_PATH="$HOME/.config/Scripts/praytime.py"

# Execute the Python script with waybar flag
python3 "$SCRIPT_PATH" --waybar "$CITY"