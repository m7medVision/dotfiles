#!/usr/bin/env python3

# disable verify ssl certificate warnings I know government sites are secure
import warnings

# I have not tried to install using this way if does not work then install manually
try:
    import requests
except:  # noqa: E722
    import os

    _ = os.system("yay -S python-requests")
try:
    from lxml import html
except:  # noqa: E722
    import os

    _ = os.system("yay -S python-lxml")

import json
import os
import sys
from datetime import datetime, timedelta

import requests
from lxml import html

warnings.filterwarnings(
    "ignore", message="Unverified HTTPS request is being made to host"
)

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


# Cache settings
CACHE_DIR = os.path.expanduser("~/.cache/praytime")
CACHE_FILE = os.path.join(CACHE_DIR, "prayer_times_cache.json")
CACHE_DURATION_DAYS = 3


def load_from_cache():
    """Load prayer times from cache if available and not expired."""
    if not os.path.exists(CACHE_FILE):
        return None

    try:
        with open(CACHE_FILE, "r") as f:
            cached_data = json.load(f)

        # Check if cache is for today
        cached_date_str = cached_data.get("date")
        if not cached_date_str:
            return None

        cached_date = datetime.strptime(cached_date_str, "%Y-%m-%d").date()
        if cached_date == datetime.now().date():
            return cached_data

    except (json.JSONDecodeError, FileNotFoundError):
        return None
    return None


def save_to_cache(data):
    """Save prayer times to cache."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump(data, f, indent=4)


def get_government_data(date):
    """Fetch prayer data for a specific date."""
    data = {
        "year": str(date.year),
        "month": str(date.month),
        "day": str(date.day),
        "B1": "View",
    }

    response = requests.post(
        "https://www.mara.gov.om/calendar_page3.asp", data=data, verify=False
    )
    if response.status_code != 200:
        raise Exception(
            f"Failed to fetch government data for {date.strftime('%Y-%m-%d')}"
        )
    return response.content


def get_prayer_times(data):
    tree = html.fromstring(data)
    prayer_times = {}

    for place in range(2, 12):
        row_xpath = f"//table/tr[{place}]"
        row = tree.xpath(row_xpath)
        if not row:
            continue
        tds = row[0].xpath("./td")
        if len(tds) < 7:
            continue
        prayer_times[PLACES[place]] = {
            "Fajr": tds[1].text_content().strip(),
            "Sunrise": tds[2].text_content().strip(),
            "Dhuhr": tds[3].text_content().strip(),
            "Asr": tds[4].text_content().strip(),
            "Maghrib": tds[5].text_content().strip(),
            "Isha": tds[6].text_content().strip(),
        }
    return prayer_times


def get_today_date_arabic(data):
    tree = html.fromstring(data)
    date_xpath = "//div/div/div/div[2]/div/div/div/div[3]/text()"
    date_element = tree.xpath(date_xpath)
    if not date_element:
        return None
    date_text = date_element[0].strip()
    date_text = date_text.split("ميلادى")[1].strip()
    return date_text


def convert_to_24h(time_str):
    """Convert 12-hour format (AM/PM) to 24-hour format for comparison"""
    try:
        return datetime.strptime(time_str, "%I:%M %p").strftime("%H:%M")
    except:
        # If already in 24h format or parsing fails, return as is
        return time_str


def get_next_prayer_time(full_prayer_data, city="Muscat"):
    now = datetime.now()
    today_str = now.strftime("%Y-%m-%d")

    # Check today's prayer times
    today_prayers = (
        full_prayer_data.get(today_str, {}).get("prayer_times", {}).get(city, {})
    )
    if today_prayers:
        prayer_order = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
        current_time_24h = now.strftime("%H:%M")

        for prayer in prayer_order:
            prayer_time_str = today_prayers.get(prayer, "").strip()
            if not prayer_time_str:
                continue

            if "AM" not in prayer_time_str and "PM" not in prayer_time_str:
                if prayer in ["Fajr", "Sunrise"]:
                    prayer_time_str += " AM"
                elif prayer == "Dhuhr":
                    hour = int(prayer_time_str.split(":")[0])
                    prayer_time_str += " AM" if hour < 12 else " PM"
                else:
                    prayer_time_str += " PM"

            prayer_time_24h = convert_to_24h(prayer_time_str)
            if prayer_time_24h > current_time_24h:
                return prayer, prayer_time_str

    # If no prayer is left for today, check for tomorrow's Fajr
    tomorrow = now + timedelta(days=1)
    tomorrow_str = tomorrow.strftime("%Y-%m-%d")

    tomorrow_prayers = (
        full_prayer_data.get(tomorrow_str, {}).get("prayer_times", {}).get(city, {})
    )
    if tomorrow_prayers and "Fajr" in tomorrow_prayers:
        fajr_time = tomorrow_prayers["Fajr"].strip()
        if "AM" not in fajr_time and "PM" not in fajr_time:
            fajr_time += " AM"
        return "Fajr", fajr_time

    # Fallback if data for tomorrow is not available
    return "Fajr", "N/A"


def format_for_waybar(
    next_prayer,
    next_time,
    city="Muscat",
    all_prayers=None,
    arabic_date=None,
    full_cache=None,
):
    icon_map = {
        "Fajr": "🌅",
        "Sunrise": "☀️",
        "Dhuhr": "🌞",
        "Asr": "🌇",
        "Maghrib": "🌆",
        "Isha": "🌃",
    }

    arabic_names = {
        "Fajr": "الفجر",
        "Sunrise": "الشروق",
        "Dhuhr": "الظهر",
        "Asr": "العصر",
        "Maghrib": "المغرب",
        "Isha": "العشاء",
    }

    icon = icon_map.get(next_prayer, "🕌")
    arabic_name = arabic_names.get(next_prayer, next_prayer)
    text = f"{icon} {arabic_name} {next_time}"

    # Create detailed tooltip with all prayer times for today and tomorrow
    tooltip_lines = [f"🕌 أوقات الصلاة في {city}"]
    if arabic_date:
        tooltip_lines.append(f"📅 {arabic_date}")
    tooltip_lines.append("━" * 35)
    tooltip_lines.append(f"🔔 التالي: {arabic_name} في {next_time}")
    tooltip_lines.append("━" * 35)

    if all_prayers:
        tooltip_lines.append("صلوات اليوم:")
        for prayer, time in all_prayers.items():
            prayer_icon = icon_map.get(prayer, "🕌")
            prayer_arabic = arabic_names.get(prayer, prayer)
            if prayer == next_prayer and next_time == time:
                tooltip_lines.append(f"➤ {prayer_icon} {prayer_arabic:<8} {time} (التالي)")
            else:
                tooltip_lines.append(f"   {prayer_icon} {prayer_arabic:<8} {time}")

    if full_cache:
        tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        tomorrow_prayers = (
            full_cache.get(tomorrow, {}).get("prayer_times", {}).get(city, {})
        )
        if tomorrow_prayers:
            tooltip_lines.append("\nصلوات الغد:")
            for prayer, time in tomorrow_prayers.items():
                prayer_icon = icon_map.get(prayer, "🕌")
                prayer_arabic = arabic_names.get(prayer, prayer)
                tooltip_lines.append(f"   {prayer_icon} {prayer_arabic:<8} {time}")

    tooltip = "\n".join(tooltip_lines)

    return {"text": text, "tooltip": tooltip, "class": "prayer-time"}


if __name__ == "__main__":
    try:
        cached_data = load_from_cache()

        if cached_data:
            prayer_times_today = cached_data["prayer_times"]
            arabic_date_today = cached_data["arabic_date"]
            full_prayer_data = cached_data.get("full_cache", {})
        else:
            # Fetch data for the next 3 days and cache it
            all_prayer_data = {}
            today = datetime.now().date()

            for i in range(CACHE_DURATION_DAYS):
                current_date = today + timedelta(days=i)
                html_data = get_government_data(current_date)

                prayer_times = get_prayer_times(html_data)
                arabic_date = get_today_date_arabic(html_data)

                date_str = current_date.strftime("%Y-%m-%d")
                all_prayer_data[date_str] = {
                    "prayer_times": prayer_times,
                    "arabic_date": arabic_date,
                }

            # Save to cache
            save_to_cache(
                {
                    "date": today.strftime("%Y-%m-%d"),
                    "prayer_times": all_prayer_data[today.strftime("%Y-%m-%d")][
                        "prayer_times"
                    ],
                    "arabic_date": all_prayer_data[today.strftime("%Y-%m-%d")][
                        "arabic_date"
                    ],
                    "full_cache": all_prayer_data,
                }
            )

            prayer_times_today = all_prayer_data[today.strftime("%Y-%m-%d")][
                "prayer_times"
            ]
            arabic_date_today = all_prayer_data[today.strftime("%Y-%m-%d")][
                "arabic_date"
            ]
            full_prayer_data = all_prayer_data

        if len(sys.argv) > 1 and sys.argv[1] == "--waybar":
            city = sys.argv[2] if len(sys.argv) > 2 else "Muscat"
            next_prayer, next_time = get_next_prayer_time(full_prayer_data, city)
            all_prayers = prayer_times_today.get(city, {})
            waybar_output = format_for_waybar(
                next_prayer,
                next_time,
                city,
                all_prayers,
                arabic_date_today,
                full_prayer_data,
            )
            print(json.dumps(waybar_output))
        elif len(sys.argv) > 1 and sys.argv[1] == "--lockscreen":
            city = "Muscat"
            prayers = prayer_times_today.get(city, {})
            prayer_order = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
            icons = {
                "Fajr": "🌅",
                "Sunrise": "☀️",
                "Dhuhr": "🌞",
                "Asr": "🌇",
                "Maghrib": "🌆",
                "Isha": "🌃",
            }

            result = []
            for prayer in prayer_order:
                if prayer in prayers:
                    time = prayers[prayer].strip()
                    if "AM" not in time and "PM" not in time:
                        if prayer in ["Fajr", "Sunrise"]:
                            time += " AM"
                        elif prayer == "Dhuhr":
                            hour = int(time.split(":")[0])
                            time += " AM" if hour < 12 else " PM"
                        else:
                            time += " PM"
                    icon = icons.get(prayer, "🕌")
                    result.append(f"{icon} {prayer}: {time}")
            print("  •  ".join(result))
        else:
            print(arabic_date_today)
            for city, times in prayer_times_today.items():
                print(f"\n{city}:")
                for prayer, time in times.items():
                    print(f"  {prayer}: {time}")
    except Exception as e:
        if len(sys.argv) > 1 and sys.argv[1] == "--waybar":
            error_output = {
                "text": "🕌 أوقات الصلاة غير متوفرة",
                "tooltip": f"خطأ في تحميل أوقات الصلاة:\n{str(e)}\n\nيرجى التحقق من اتصالك بالإنترنت.",
                "class": "prayer-time-error",
            }
            print(json.dumps(error_output))
        else:
            print(f"Error: {e}")
