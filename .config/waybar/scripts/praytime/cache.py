"""Cache handling for prayer times."""

import json
import os
from datetime import date, datetime
from typing import Optional

from .constants import CACHE_FILE


def load_cache() -> Optional[dict]:
    """Load prayer times from cache if available and valid for today."""
    if not os.path.exists(CACHE_FILE):
        return None
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        cached_date = datetime.strptime(data["date"], "%Y-%m-%d").date()
        if cached_date == date.today():
            return data
    except (json.JSONDecodeError, KeyError, ValueError):
        pass
    return None


def save_cache(data: dict) -> None:
    """Save prayer times to cache."""
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
