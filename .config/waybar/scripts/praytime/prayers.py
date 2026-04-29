"""Prayer time calculations and utilities."""

from datetime import datetime, timedelta
from typing import Optional

from .constants import IQAMA_DELAYS, PRAYER_ORDER


def to_24h(time_str: str) -> str:
    """Convert a 12-hour time string to 24-hour format."""
    try:
        return datetime.strptime(time_str.strip(), "%I:%M %p").strftime("%H:%M")
    except ValueError:
        return time_str.strip()


def to_minutes(time_str: str) -> int:
    """Convert a time string to minutes since midnight."""
    h, m = map(int, to_24h(time_str).split(":"))
    return h * 60 + m


def add_am_pm(prayer: str, time_str: str) -> str:
    """Add AM/PM suffix if missing, based on prayer name."""
    time_str = time_str.strip()
    if "AM" in time_str or "PM" in time_str:
        return time_str
    if prayer in ("Fajr", "Sunrise"):
        return f"{time_str} AM"
    if prayer == "Dhuhr":
        hour = int(time_str.split(":")[0])
        return f"{time_str} AM" if hour < 12 else f"{time_str} PM"
    return f"{time_str} PM"


def is_in_iqama(prayer: str, time_str: str, current_time: Optional[str] = None) -> bool:
    """Check if the current time falls between Athan and Iqama for a prayer."""
    if prayer == "Sunrise" or prayer not in IQAMA_DELAYS:
        return False
    now = current_time or datetime.now().strftime("%H:%M")
    prayer_min = to_minutes(add_am_pm(prayer, time_str))
    current_min = to_minutes(now)
    iqama_min = prayer_min + IQAMA_DELAYS[prayer]
    return prayer_min <= current_min <= iqama_min


def get_next_prayer(full_data: dict, city: str = "Muscat") -> tuple[str, str]:
    """Return the name and time of the next upcoming prayer."""
    now = datetime.now()
    today_str = now.strftime("%Y-%m-%d")
    current_min = now.hour * 60 + now.minute

    today_prayers = full_data.get(today_str, {}).get("prayer_times", {}).get(city, {})
    for prayer in PRAYER_ORDER:
        raw_time = today_prayers.get(prayer, "").strip()
        if not raw_time:
            continue
        time_with_suffix = add_am_pm(prayer, raw_time)
        if to_minutes(time_with_suffix) > current_min:
            return prayer, time_with_suffix

    # Fallback to tomorrow's Fajr
    tomorrow_str = (now + timedelta(days=1)).strftime("%Y-%m-%d")
    tomorrow_prayers = full_data.get(tomorrow_str, {}).get("prayer_times", {}).get(city, {})
    if tomorrow_prayers:
        fajr = add_am_pm("Fajr", tomorrow_prayers.get("Fajr", "N/A"))
        return "Fajr", fajr
    return "Fajr", "N/A"
