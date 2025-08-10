#!/usr/bin/env python3
import requests
import sys
import json

# CONFIGURABLE: Update this nonce if it stops working
NONCE = "9e2a8535b5"
STATION_ID = "61af0361-fc82-4c03-bdd1-46e67e457e79"
API_URL = "https://met.caa.gov.om/wp-admin/admin-ajax.php"

# You can add more fields here if you want
IMPORTANT_FIELDS = [
    "datetime", "temperature", "feelsLikeTemperature", "humidity", "dewPoint",
    "pressureStation", "pressureQNH", "windSpeed", "windGust", "windDirection",
    "precipitationLast60min", "visibilityMin", "sunrise", "sunset"
]

def fetch_weather():
    data = {
        "action": "get_weather",
        "location": "null",
        "sea_stations_only": "false",
        "nonce": NONCE
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
        if 'error' in result:
            print(f"[ERROR] Error: {result['error']}")
        print("[HINT] The nonce may have expired. Try updating it in the script.")
        sys.exit(1)
    stations = result.get("data", {}).get("stations", [])
    station = next((s for s in stations if s.get("id") == STATION_ID), None)
    if not station:
        print(f"[ERROR] Station ID {STATION_ID} not found in response.")
        sys.exit(1)
    # Print localName (or fallback to name) for easy extraction
    local_name = station['location'].get('localName') or station['location'].get('name')
    print(f"localName: {local_name}")
    print(f"Weather for station {station['location']['name']} (ID: {STATION_ID}):\n")
    for field in IMPORTANT_FIELDS:
        value = station.get(field)
        if value is not None:
            print(f"{field}: {value}")
    # Print forecast if available
    forecasts = station.get("forecasts")
    if forecasts:
        print("\nForecasts:")
        for f in forecasts[:3]:  # Show up to 3 forecasts
            print(f"  {f['datetime']}: {f['minTemperature']}°C - {f['maxTemperature']}°C, Weather: {f['weatherStatus']}")

if __name__ == "__main__":
    fetch_weather()
