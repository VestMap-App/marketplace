#!/usr/bin/env bash
# render-vestmap-map.sh — snapshot a VestMap `show_map` share URL to a PNG.
#
# WHY: VestMap `show_map` returns a LINK to a client-side ArcGIS WebGL SPA — the
# map only exists after JS runs, so the only way to put a map IMAGE on the OM
# page is a headless-Chrome screenshot. WebGL needs software GL
# (--use-angle=swiftshader) and a long virtual-time budget to paint; a plain
# --headless screenshot captures a blank canvas. This command is the one
# empirically verified to render the full basemap + pin + legend.
#
# Usage:   render-vestmap-map.sh <share-url> <out.png>
# Exit:    0  a non-blank PNG was written to <out.png>
#          1  blank/failed after retries  (caller: fall back to a link or drop
#             the map — NEVER a placeholder, per SKILL.md O2)
#          2  bad args   3  no Chrome/Chromium binary found
#
# Blank-vs-rendered heuristic: a painted map is ~1 MB, a blank canvas ~15 KB.
# We treat < 100 KB as "didn't paint" and retry once.
set -u

URL="${1:-}"
OUT="${2:-}"
if [ -z "$URL" ] || [ -z "$OUT" ]; then
  echo "usage: render-vestmap-map.sh <share-url> <out.png>" >&2
  exit 2
fi

# Locate a Chrome/Chromium binary (same discovery as layout.md §9 PDF export).
CHROME=""
for c in \
  google-chrome google-chrome-stable chromium chromium-browser chrome \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
  if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  echo "render-vestmap-map: no Chrome/Chromium binary found" >&2
  exit 3
fi

MIN_BYTES=102400   # 100 KB — below this the WebGL canvas almost certainly blank.

filesize() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0; }

snap() {
  rm -f "$OUT"
  # --use-angle=swiftshader + a 60s virtual-time budget are the load-bearing
  # flags; without software GL the WebGL map never paints in headless mode.
  "$CHROME" \
    --headless=new \
    --use-angle=swiftshader \
    --no-sandbox \
    --hide-scrollbars \
    --force-device-scale-factor=1 \
    --window-size=1280,900 \
    --virtual-time-budget=60000 \
    --timeout=75000 \
    --screenshot="$OUT" \
    "$URL" >/dev/null 2>&1
}

for _attempt in 1 2; do
  snap
  if [ -f "$OUT" ] && [ "$(filesize "$OUT")" -ge "$MIN_BYTES" ]; then
    exit 0
  fi
done

echo "render-vestmap-map: blank/failed after 2 attempts: $URL" >&2
exit 1
