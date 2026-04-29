"""Parse HTML prayer data using stdlib only."""

import re
from html.parser import HTMLParser
from typing import Optional

# Arabic city name → English name mapping (from the HTML table).
_CITY_MAP = {
    "مسقط": "Muscat",
    "صلالة": "Salalah",
    "عبري": "Ibri",
    "نزوى": "Nizwa",
    "البريمي": "Al Buraimi",
    "صحار": "Sohar",
    "الرستاق": "Al Rustaq",
    "صور": "Sur",
    "ابراء": "Ibra",
    "هيما": "Haima",
}


class _TableParser(HTMLParser):
    """Simple HTML table parser that extracts rows and cells."""

    def __init__(self) -> None:
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.current_cell = ""
        self.current_row: list[str] = []
        self.rows: list[list[str]] = []

    def handle_starttag(self, tag: str, attrs: list) -> None:
        if tag == "table":
            self.in_table = True
        elif self.in_table and tag == "tr":
            self.in_row = True
            self.current_row = []
        elif self.in_row and tag == "td":
            self.in_cell = True
            self.current_cell = ""

    def handle_endtag(self, tag: str) -> None:
        if tag == "table":
            self.in_table = False
        elif self.in_table and tag == "tr":
            self.in_row = False
            if self.current_row:
                self.rows.append(self.current_row)
        elif self.in_row and tag == "td":
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())

    def handle_data(self, data: str) -> None:
        if self.in_cell:
            self.current_cell += data


def parse_prayer_times(html_data: bytes) -> dict:
    """Extract prayer times for all cities from the HTML response."""
    parser = _TableParser()
    parser.feed(html_data.decode("utf-8", errors="replace"))

    prayer_times: dict[str, dict[str, str]] = {}
    for row in parser.rows:
        if len(row) < 7:
            continue
        city_name = row[0]
        english_city = _CITY_MAP.get(city_name)
        if english_city:
            prayer_times[english_city] = {
                "Fajr": row[1],
                "Sunrise": row[2],
                "Dhuhr": row[3],
                "Asr": row[4],
                "Maghrib": row[5],
                "Isha": row[6],
            }
    return prayer_times


def parse_arabic_date(html_data: bytes) -> Optional[str]:
    """Extract the Arabic date string from the HTML response."""
    text = html_data.decode("utf-8", errors="replace")
    match = re.search(r"ميلادى\s*([^<]+)", text)
    if match:
        return match.group(1).strip()
    return None
