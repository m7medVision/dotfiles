#!/bin/bash

# Get location info - you can customize this
if command -v curl >/dev/null 2>&1; then
    location=$(curl -s ipinfo.io/city 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$location" ]; then
        echo "📍 $location"
    else
        echo "📍 Unknown Location"
    fi
else
    echo "📍 Home"
fi