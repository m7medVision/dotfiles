"""Command-line interface."""

import json
import sys
from datetime import date, datetime, timedelta

from .cache import load_cache, save_cache
from .constants import CACHE_DAYS
from .fetcher import fetch_govt_data
from .formatters import build_lockscreen_output, build_waybar_output
from .parser import parse_arabic_date, parse_prayer_times
from .prayers import get_next_prayer


def fetch_all_data() -> dict:
    """Fetch and cache prayer times for today + the next few days."""
    today = date.today()
    all_data = {}

    for i in range(CACHE_DAYS):
        current = today + timedelta(days=i)
        html_data = fetch_govt_data(current)
        prayers = parse_prayer_times(html_data)
        arabic = parse_arabic_date(html_data)
        date_str = current.strftime("%Y-%m-%d")
        all_data[date_str] = {"prayer_times": prayers, "arabic_date": arabic}

    cache_payload = {
        "date": today.strftime("%Y-%m-%d"),
        "prayer_times": all_data[today.strftime("%Y-%m-%d")]["prayer_times"],
        "arabic_date": all_data[today.strftime("%Y-%m-%d")]["arabic_date"],
        "full_cache": all_data,
    }
    save_cache(cache_payload)
    return cache_payload


def main() -> None:
    cached = load_cache()

    if cached:
        prayer_times_today = cached["prayer_times"]
        arabic_date_today = cached.get("arabic_date")
        full_prayer_data = cached.get("full_cache", {})
    else:
        data = fetch_all_data()
        prayer_times_today = data["prayer_times"]
        arabic_date_today = data["arabic_date"]
        full_prayer_data = data["full_cache"]

    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    city = sys.argv[2] if len(sys.argv) > 2 else "Muscat"

    try:
        if mode == "--waybar":
            next_prayer, next_time = get_next_prayer(full_prayer_data, city)
            all_prayers = prayer_times_today.get(city, {})
            output = build_waybar_output(
                next_prayer, next_time, city, all_prayers,
                arabic_date_today, full_prayer_data,
            )
            print(json.dumps(output, ensure_ascii=False))
        elif mode == "--lockscreen":
            prayers = prayer_times_today.get("Muscat", {})
            print(build_lockscreen_output(prayers))
        else:
            print(arabic_date_today or "")
            for c, times in prayer_times_today.items():
                print(f"\n{c}:")
                for prayer, t in times.items():
                    print(f"  {prayer}: {t}")
    except Exception as exc:
        if mode == "--waybar":
            error = {
                "text": "🕌 أوقات الصلاة غير متوفرة",
                "tooltip": f"خطأ في تحميل أوقات الصلاة:\n{exc}\n\nيرجى التحقق من اتصالك بالإنترنت.",
                "class": "prayer-time-error",
            }
            print(json.dumps(error, ensure_ascii=False))
        else:
            print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
