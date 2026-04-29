"""Constants for the praytime package."""

import os

PLACES = {
    2: "Muscat",
    3: "Salalah",
    4: "Ibri",
    5: "Nizwa",
    6: "Al Buraimi",
    7: "Sohar",
    8: "Al Rustaq",
    9: "Sur",
    10: "Ibra",
    11: "Haima",
}

PRAYER_ORDER = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]

IQAMA_DELAYS = {
    "Fajr": 25,
    "Dhuhr": 25,
    "Asr": 25,
    "Maghrib": 15,
    "Isha": 25,
}

ICON_MAP = {
    "Fajr": "🌅",
    "Sunrise": "☀️",
    "Dhuhr": "🌞",
    "Asr": "🌇",
    "Maghrib": "🌆",
    "Isha": "🌃",
}

ARABIC_NAMES = {
    "Fajr": "الفجر",
    "Sunrise": "الشروق",
    "Dhuhr": "الظهر",
    "Asr": "العصر",
    "Maghrib": "المغرب",
    "Isha": "العشاء",
}

CACHE_DIR = os.path.expanduser("~/.cache/praytime")
CACHE_FILE = os.path.join(CACHE_DIR, "prayer_times_cache.json")
CACHE_DAYS = 3
GOVT_URL = "https://www.mara.gov.om/calendar_page3.asp"
