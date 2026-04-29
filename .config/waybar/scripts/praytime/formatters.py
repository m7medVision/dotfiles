"""Output formatters for Waybar and lockscreen."""

from datetime import datetime, timedelta
from typing import Optional

from .constants import ARABIC_NAMES, ICON_MAP, PRAYER_ORDER
from .prayers import add_am_pm, is_in_iqama


def build_waybar_output(
    next_prayer: str,
    next_time: str,
    city: str = "Muscat",
    all_prayers: Optional[dict] = None,
    arabic_date: Optional[str] = None,
    full_cache: Optional[dict] = None,
) -> dict:
    """Build the JSON output expected by Waybar."""
    now = datetime.now().strftime("%H:%M")
    special_text = None

    if all_prayers:
        for prayer, time in all_prayers.items():
            if is_in_iqama(prayer, time, now):
                special_text = f"غايتها صلاة {ARABIC_NAMES.get(prayer, prayer)}"
                break

    icon = ICON_MAP.get(next_prayer, "🕌")
    arabic_name = ARABIC_NAMES.get(next_prayer, next_prayer)

    text = special_text if special_text else f"{icon} {arabic_name} {next_time}"

    lines = [f"🕌 أوقات الصلاة في {city}"]
    if arabic_date:
        lines.append(f"📅 {arabic_date}")
    lines.append("━" * 35)
    lines.append(f"🔔 التالي: {arabic_name} في {next_time}")
    lines.append("━" * 35)

    if all_prayers:
        lines.append("صلوات اليوم:")
        for prayer in PRAYER_ORDER:
            time = all_prayers.get(prayer)
            if not time:
                continue
            marker = "➤" if (prayer == next_prayer and time == next_time) else " "
            lines.append(
                f"{marker}  {ICON_MAP.get(prayer, '🕌')} {ARABIC_NAMES.get(prayer, prayer):<8} {time}"
            )

    if full_cache:
        tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        tomorrow_prayers = full_cache.get(tomorrow_str, {}).get("prayer_times", {}).get(city, {})
        if tomorrow_prayers:
            lines.append("")
            lines.append("صلوات الغد:")
            for prayer in PRAYER_ORDER:
                time = tomorrow_prayers.get(prayer)
                if not time:
                    continue
                lines.append(
                    f"   {ICON_MAP.get(prayer, '🕌')} {ARABIC_NAMES.get(prayer, prayer):<8} {time}"
                )

    return {
        "text": text,
        "tooltip": "\n".join(lines),
        "class": "prayer-time",
    }


def build_lockscreen_output(prayers: dict) -> str:
    """Build a plain-text line for lockscreen use."""
    parts = []
    for prayer in PRAYER_ORDER:
        raw = prayers.get(prayer, "").strip()
        if not raw:
            continue
        time = add_am_pm(prayer, raw)
        parts.append(f"{ICON_MAP.get(prayer, '🕌')} {prayer}: {time}")
    return "  •  ".join(parts)
