#!/bin/bash

# Get all prayer times for lock screen display
python3 /home/mohammed/.config/Scripts/praytime.py --lockscreen 2>/dev/null || echo "🕌 Prayer times loading..."