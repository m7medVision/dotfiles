#!/bin/bash

# Get weather data (requires curl and jq)
# You can get a free API key from openweathermap.org
API_KEY="your_api_key_here"
CITY="your_city_here"

if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && [ "$API_KEY" != "your_api_key_here" ]; then
    weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$API_KEY&units=metric" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$weather_data" | jq -r '.main.temp' >/dev/null 2>&1; then
        temp=$(echo "$weather_data" | jq -r '.main.temp' | cut -d. -f1)
        description=$(echo "$weather_data" | jq -r '.weather[0].main')
        
        # Weather icons
        case "$description" in
            "Clear") icon="☀️" ;;
            "Clouds") icon="☁️" ;;
            "Rain") icon="🌧️" ;;
            "Snow") icon="❄️" ;;
            "Thunderstorm") icon="⛈️" ;;
            *) icon="🌤️" ;;
        esac
        
        echo "$temp°C $icon"
    else
        echo "Weather unavailable"
    fi
else
    echo "25°C 🌤️"
fi