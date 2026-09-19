#!/bin/sh
# hyprlock-ai.sh — single-line AI usage for hyprlock labels.
# Mirrors the hyprshell `ai-usage` bar widget (same `ai-usagebar` backend,
# same "busiest provider wins" idea) in a lock-screen-safe plain-text form.
#
# Usage in hyprlock.conf:
#   text = cmd[update:300000] $HOME/.config/hypr/hyprlock-ai.sh primary
#   text = cmd[update:300000] $HOME/.config/hypr/hyprlock-ai.sh secondary
#
# Modes:
#   primary   — busiest metric overall, e.g. "Claude · Weekly 84% · 3d 0h"
#   secondary — one-line summary of the rest, e.g. "zai 26% · cur 42%"
#   (no arg defaults to primary)
# POSIX sh, python3 for JSON parsing (no jq dependency).

set -u
MODE="${1:-primary}"
BIN="${AI_USAGEBAR_BIN:-$(command -v ai-usagebar 2>/dev/null || echo "$HOME/.local/bin/ai-usagebar")}"

if [ ! -x "$BIN" ]; then
  echo "AI Usage — unavailable"
  exit 0
fi

DATA="$("$BIN" usage --json 2>/dev/null)"
if [ -z "$DATA" ]; then
  echo "AI Usage — unavailable"
  exit 0
fi

# Pipe via env to avoid the `cmd | python3 <<'HEREDOC'` stdin clash
# (the heredoc would steal stdin from the pipe).
DATA="$DATA" MODE="$MODE" python3 <<'PY'
import json, sys, datetime, os

mode = os.environ.get("MODE", "primary")
raw = os.environ.get("DATA", "")

try:
    d = json.loads(raw)
except Exception:
    print("AI Usage — unavailable")
    sys.exit(0)

entries = [e for e in (d.get("entries") or []) if e.get("status") != "error"]
if not entries:
    print("AI Usage — no providers")
    sys.exit(0)

def countdown(reset_at):
    if not reset_at:
        return ""
    try:
        s = str(reset_at)
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        dt = datetime.datetime.fromisoformat(s)
        diff = (dt - datetime.datetime.now(datetime.timezone.utc)).total_seconds()
    except Exception:
        return ""
    if diff <= 0:
        return "now"
    if diff >= 86400:
        return f"{int(diff // 86400)}d {int((diff % 86400) // 3600)}h"
    h = int(diff // 3600)
    m = int((diff % 3600) // 60)
    return f"{h}h {m}m" if h > 0 else f"{m}m"

def busiest_metric(entry):
    ms = entry.get("metrics") or []
    if not ms:
        return None
    return max(ms, key=lambda m: (m.get("percent") or 0))

# Busiest metric across ALL entries (unlike the bar widget, which only
# looks at metrics[0] per provider — here Weekly 84% beats Session 0%).
best = None  # (percent, entry, metric)
for e in entries:
    for m in (e.get("metrics") or []):
        p = m.get("percent") or 0
        if best is None or p > best[0]:
            best = (p, e, m)

if best is None:
    print("AI Usage — no data")
    sys.exit(0)

_, pentry, pmetric = best
pname = pentry.get("display_name") or pentry.get("id") or "AI"
plabel = pmetric.get("label") or "Usage"
ppct = pmetric.get("percent")
cd = countdown(pmetric.get("reset_at"))

def short_label(e):
    # "@"" accounts share the base short_name (two "cld"s) — use the full
    # display name for those so the lock line stays unambiguous.
    if "@" in (e.get("id") or ""):
        return e.get("display_name") or e.get("id")
    return e.get("short_name") or e.get("display_name") or e.get("id")

if mode == "primary":
    line = f"{pname} · {plabel} {ppct}%"
    if cd:
        line += f" · {cd}"
    print(line)
else:
    # Summary of every other provider: "Name pct% - Name pct%".
    # The primary provider is skipped here so the two lock lines never
    # repeat each other.
    parts = []
    for e in entries:
        if e.get("id") == pentry.get("id"):
            continue
        m = busiest_metric(e)
        if m is None:
            continue
        nm = short_label(e)
        pct = m.get("percent") or 0
        parts.append(f"{nm} {pct}%")
        if len(parts) >= 4:
            break
    if not parts:
        # Single-provider setup: show the runner-up metric of the same
        # provider instead of an empty line.
        rest = sorted((pentry.get("metrics") or []),
                      key=lambda m: (m.get("percent") or 0), reverse=True)[1:3]
        tmp = []
        for m in rest:
            lbl = m.get("label") or "?"
            pct = m.get("percent") or 0
            tmp.append(f"{lbl} {pct}%")
        parts = tmp
    print(" · ".join(parts) if parts else "")
PY
