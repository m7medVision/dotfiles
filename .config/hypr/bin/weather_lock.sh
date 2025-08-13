#!/bin/bash

# Get weather data from the Python script
WEATHER_JSON=$(python3 ~/.config/Scripts/weather_fetch_om.py 2>/dev/null)

# Extract location and weather info
if [ $? -eq 0 ] && [ -n "$WEATHER_JSON" ]; then
    # Extract the location from the tooltip (it contains "Weather for LocationName")
    LOCATION=$(echo "$WEATHER_JSON" | jq -r '.tooltip' | sed 's/Weather for \([^-]*\) -.*/\1/' | xargs)
    
    # Extract the weather text (icon + temperature)
    WEATHER_TEXT=$(echo "$WEATHER_JSON" | jq -r '.text')
    
    # Combine location and weather
    echo "$LOCATION | $WEATHER_TEXT"
else
    # Fallback if weather script fails
    echo "السويق | 🌡️ Weather unavailable"
fi