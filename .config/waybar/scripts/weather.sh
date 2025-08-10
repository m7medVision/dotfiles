#!/bin/bash
OUTPUT=$(python3 /home/mohammed/dotfiles/.config/Scripts/weather_fetch_om.py 2>/dev/null)

TEMP=$(echo "$OUTPUT" | grep '^temperature:' | head -1 | awk -F: '{print $2}' | xargs)
LOC=$(echo "$OUTPUT" | grep '^localName:' | head -1 | awk -F: '{print $2}' | xargs)
FEEL=$(echo "$OUTPUT" | grep '^feelsLikeTemperature:' | awk -F: '{print $2}' | xargs)
HUM=$(echo "$OUTPUT" | grep '^humidity:' | awk -F: '{print $2}' | xargs)

if [ -n "$TEMP" ] && [ -n "$LOC" ]; then
    TEXT="${TEMP} 󰔄 ${LOC} "
    TOOLTIP="Temperature: ${TEMP}°C\nLocation: ${LOC}\nFeel Like: ${FEEL}°C\nHumidity: ${HUM}%"
    echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\"}"
else
    echo '{"text": "Weather unavailable", "tooltip": "Failed to fetch weather data"}'
fi
