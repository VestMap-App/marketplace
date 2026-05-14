#!/usr/bin/env bash
# VestMap plugin — SessionStart update check.
# Prints a one-line notice when a newer marketplace release is available.
# Invariant: always exit 0 and fail silently — this must never block or delay
# session start, even with no network.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
[ -z "$PLUGIN_ROOT" ] && exit 0

MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
[ -f "$MANIFEST" ] || exit 0

extract_quoted() {
  # Pull the value of the first "key": "value" pair for the given key.
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}

installed="$(extract_quoted version < "$MANIFEST")"
[ -z "$installed" ] && exit 0

latest="$(curl -fsS --max-time 3 \
  https://api.github.com/repos/VestMap-App/marketplace/releases/latest 2>/dev/null \
  | extract_quoted tag_name)"
[ -z "$latest" ] && exit 0

latest="${latest#v}"

# Nudge only when the latest release sorts strictly above the installed version.
if [ "$installed" != "$latest" ]; then
  newer="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | tail -1)"
  if [ "$newer" = "$latest" ]; then
    echo "VestMap: update available ($installed -> $latest). Run: /plugin marketplace update vestmap-app  then  /reload-plugins"
  fi
fi

exit 0
