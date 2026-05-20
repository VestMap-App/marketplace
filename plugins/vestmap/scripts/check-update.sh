#!/usr/bin/env bash
# VestMap plugin — SessionStart update check.
# Prints a one-line notice when a newer version has been published.
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

# The published version is whatever plugin.json declares on the default branch — the
# same source of truth that drives `claude plugin update`.
latest="$(curl -fsS --max-time 3 \
  https://raw.githubusercontent.com/VestMap-App/marketplace/main/plugins/vestmap/.claude-plugin/plugin.json 2>/dev/null \
  | extract_quoted version)"
[ -z "$latest" ] && exit 0

# Nudge only when the latest version sorts strictly above the installed version.
if [ "$installed" != "$latest" ]; then
  newer="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | tail -1)"
  if [ "$newer" = "$latest" ]; then
    echo "VestMap: update available ($installed -> $latest). Desktop/web app: start a new session. Terminal: run 'claude plugin marketplace update vestmap-app && claude plugin update vestmap@vestmap-app' then restart. (See the README, \"Keeping it up to date\".)"
  fi
fi

exit 0
