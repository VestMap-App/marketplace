#!/usr/bin/env bash
# VestMap plugin — SessionStart update check.
# Prints a one-line notice when a newer plugin release tag is available.
# Invariant: always exit 0 and fail silently — this must never block or delay
# session start, even with no network.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
[ -z "$PLUGIN_ROOT" ] && exit 0

MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
[ -f "$MANIFEST" ] || exit 0

# Installed version, read from the bundled plugin.json.
installed="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST" \
  | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
[ -z "$installed" ] && exit 0

# Latest published version. `claude plugin tag` publishes release tags of the
# form `vestmap--v<version>`; fetch the tag list and pick the highest version.
# 3s timeout, silent on any failure (offline, rate-limited, no tags yet).
latest="$(curl -fsS --max-time 3 \
  https://api.github.com/repos/VestMap-App/marketplace/tags 2>/dev/null \
  | grep -o '"name"[[:space:]]*:[[:space:]]*"vestmap--v[^"]*"' \
  | sed 's/.*"vestmap--v\([^"]*\)"$/\1/' \
  | sort -V | tail -1)"
[ -z "$latest" ] && exit 0

# Nudge only when the latest tag sorts strictly above the installed version.
if [ "$installed" != "$latest" ]; then
  newer="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | tail -1)"
  if [ "$newer" = "$latest" ]; then
    echo "VestMap: update available ($installed -> $latest). Run: /plugin marketplace update vestmap-app  then  /reload-plugins"
  fi
fi

exit 0
