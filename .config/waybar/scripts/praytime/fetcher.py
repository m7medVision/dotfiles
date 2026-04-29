"""Fetch prayer data from the Omani government website using stdlib only."""

import ssl
import urllib.error
import urllib.parse
import urllib.request
from datetime import date

from .constants import GOVT_URL


def fetch_govt_data(target_date: date) -> bytes:
    """Fetch prayer data for a specific date."""
    payload = urllib.parse.urlencode({
        "year": str(target_date.year),
        "month": str(target_date.month),
        "day": str(target_date.day),
        "B1": "View",
    }).encode("utf-8")

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    req = urllib.request.Request(
        GOVT_URL,
        data=payload,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )

    try:
        with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
            return resp.read()
    except urllib.error.HTTPError as exc:
        raise Exception(f"Failed to fetch government data for {target_date}: {exc}") from exc
