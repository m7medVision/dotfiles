#!/usr/bin/env python3
import json
import re
import sys

import requests

# Al Swaiq Weather Station
STATION_ID = "61af0361-fc82-4c03-bdd1-46e67e457e79"

# # Uncomment the line below to set a different station ID
# STATION_ID = ''

API_URL = "https://met.caa.gov.om/wp-admin/admin-ajax.php"
HOME_URL = "https://met.caa.gov.om/en/home/"

# You can add more fields here if you want
IMPORTANT_FIELDS = [
    "datetime",
    "temperature",
    "feelsLikeTemperature",
    "humidity",
    "dewPoint",
    "pressureStation",
    "pressureQNH",
    "windSpeed",
    "windGust",
    "windDirection",
    "precipitationLast60min",
    "visibilityMin",
    "sunrise",
    "sunset",
]


def get_nonce():
    """Fetches the security nonce from the homepage."""
    try:
        resp = requests.get(HOME_URL, timeout=10)
        resp.raise_for_status()
        match = re.search(r'"nonce":\s*"([0-9a-f]+)"', resp.text)
        if match:
            return match.group(1)
        else:
            print("[ERROR] Nonce pattern not found in the page content.")
            return None
    except Exception as e:
        print(f"[ERROR] Failed to fetch nonce: {e}")
        return None


def fetch_weather():
    nonce = get_nonce()
    if not nonce:
        print("[ERROR] Could not retrieve nonce. Exiting.")
        sys.exit(1)

    data = {
        "action": "get_weather",
        "location": "null",
        "sea_stations_only": "false",
        "nonce": nonce,
    }
    try:
        resp = requests.post(API_URL, data=data, timeout=10)
        resp.raise_for_status()
    except Exception as e:
        print(f"[ERROR] Network or HTTP error: {e}")
        sys.exit(1)
    try:
        result = resp.json()
    except Exception as e:
        print(f"[ERROR] Failed to parse JSON: {e}\nRaw response: {resp.text[:200]}")
        sys.exit(1)
    if not result.get("success"):
        print(f"[ERROR] API did not return success. Message: {result}")
        if "error" in result:
            print(f"[ERROR] Error: {result['error']}")
        sys.exit(1)

    stations = result.get("data", {}).get("stations", [])
    station = next((s for s in stations if s.get("id") == STATION_ID), None)

    if not station:
        print(f"[ERROR] Station ID {STATION_ID} not found in response.")
        sys.exit(1)

    # Get current weather status from forecasts if not available in station
    current_weather_status = station.get("weatherStatus")
    forecasts = station.get("forecasts")
    if not current_weather_status and forecasts:
        # Use today's forecast
        today_forecast = forecasts[0]
        current_weather_status = today_forecast.get("weatherStatus")

    weather_icons = {
        "sun": "\uf185",
        "clouds_sun": "\uf0c2",
        "overcast": "\uf0c4",
        "rain": "\uf043",
        "fog": "\uf0eb",
    }

    weather_data = {
        "text": f"{weather_icons.get(current_weather_status, '')}  {station.get('temperature')}°C",
        "tooltip": f"Weather for {station['location']['name']} - {current_weather_status or 'Unknown'}",
        "alt": current_weather_status,
        "class": current_weather_status,
    }

    # Print the JSON output
    print(json.dumps(weather_data))


if __name__ == "__main__":
    fetch_weather()
