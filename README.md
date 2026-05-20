# VestMap for Claude Code

Bring VestMap's nationwide location intelligence into Claude Code. Install once and
get two skills: ask Claude anything about a US address, and generate polished Offering
Memorandum pages — all grounded in live VestMap data.

## What you get

Installing the **VestMap** plugin adds two skills to Claude Code:

- **`vestmap`** — Ask Claude any question about a US address: demographics, income,
  housing, workforce, crime, schools, natural hazards, and market trends. Claude pulls
  live data from VestMap and answers with clear comparison tables.
- **`vestmap-om-pages`** — Generate a presentation-ready Offering Memorandum (OM) page
  for any US address, as a PDF you can drop straight into a deal package.

The two skills are bundled together because the OM page builder is built on top of the
base skill — installing the plugin always gets you both, correctly paired.

## Before you start

You'll need three things:

1. **Claude Code** — installed. This can be the **desktop app**, the **web app**
   (claude.ai/code), or the **terminal** CLI. If you don't have it yet, get it at
   https://claude.ai/claude-code.
2. **A VestMap account** — free to create at https://app.vestmap.com/mcp.
3. **The VestMap MCP server connected** in Claude Code. This is what lets Claude pull
   live VestMap data. Follow the setup steps at https://app.vestmap.com/mcp.

## Install it

Two ways — pick one.

### 1. Terminal

```bash
claude plugin marketplace add VestMap-App/marketplace
claude plugin install vestmap@vestmap-app
```

### 2. Ask Claude to do it

Paste this to Claude in **Claude Code** (the desktop app, the web app, or a terminal
session):

```
Set up the VestMap Claude Code plugin for me. Create .claude/settings.json in this project — or merge into it if it already exists — so it contains:

{
  "extraKnownMarketplaces": {
    "vestmap-app": {
      "source": { "source": "github", "repo": "VestMap-App/marketplace" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "vestmap@vestmap-app": true
  }
}

Then tell me to restart Claude Code (or start a new session) so the VestMap skills load.
```

## Using the skills

Most of the time you don't need to type a command at all — just ask Claude naturally
and the right skill activates on its own:

- *"What's the median household income around 1600 Pennsylvania Ave NW, Washington,
  DC?"* → the **`vestmap`** skill answers with a comparison table.
- *"Make me an OM page for 1600 Pennsylvania Ave NW, Washington, DC."* → the
  **`vestmap-om-pages`** skill generates a PDF.

If you'd rather trigger a skill explicitly, type its command:

- `/vestmap:vestmap` — ask questions about an address
- `/vestmap:vestmap-om-pages` — generate an Offering Memorandum page

The `vestmap:` prefix simply means the skill comes from the VestMap plugin.

## Keeping it up to date

VestMap is set up to stay current on its own — in most cases you do nothing.

- **Desktop app / web (claude.ai/code):** **automatic.** Each new session loads the
  current published version. With `autoUpdate` in your `.claude/settings.json` (as shown
  in [Install it](#install-it)), the marketplace also refreshes at startup. Nothing to do.
- **Terminal:** turn auto-update on once, then forget it. Either keep `"autoUpdate": true`
  on the `vestmap-app` entry in your `~/.claude/settings.json`, **or** run `/plugin` in a
  `claude` session → **Marketplaces** tab → select **vestmap-app** → **Enable
  auto-update**. (Third-party marketplaces start with auto-update off, so this is a
  one-time opt-in.) After that, updates apply at the next startup and Claude Code prompts
  you to run `/reload-plugins`.
- **Update right now**, without waiting for startup — in a terminal:

  ```bash
  claude plugin marketplace update vestmap-app
  claude plugin update vestmap@vestmap-app
  ```

  then restart Claude Code. (Inside a `claude` session you can instead run
  `/plugin marketplace update vestmap-app` then `/reload-plugins`.)

When a newer version is published, Claude Code also shows a short "update available"
notice at the start of a session.

## For teams (shared repo)

To give everyone in a shared repository the VestMap skills automatically, commit the
**same** `.claude/settings.json` from [Install it](#install-it) to that repository:

```json
{
  "extraKnownMarketplaces": {
    "vestmap-app": {
      "source": { "source": "github", "repo": "VestMap-App/marketplace" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "vestmap@vestmap-app": true
  }
}
```

When teammates trust the project folder, Claude Code installs and enables VestMap for
them, and `autoUpdate` keeps it current. Organizations can also enforce this fleet-wide
through [managed settings](https://code.claude.com/docs/en/settings).

## Publishing an update (for VestMap maintainers)

VestMap pins an explicit version, so users only receive changes when you **bump that
version** — pushing commits alone does nothing for already-installed copies.

1. Make your changes under `plugins/vestmap/`.
2. Bump `"version"` in `plugins/vestmap/.claude-plugin/plugin.json` using semver
   (`MAJOR.MINOR.PATCH`). This one field is what triggers the update everywhere.
3. Commit and push to the default branch.

That's the whole release. Users with auto-update on (the default in the instructions
above) pick it up at their next session; web/cloud sessions get it immediately; anyone
else sees the "update available" notice. Optionally run `claude plugin tag` from the
plugin folder to create a `vestmap--v<version>` git tag for the release.

## About VestMap

VestMap brings nationwide location intelligence to AI agents. Turn any US address into
a complete picture of the people, economy, housing market, and risk profile around it
— demographics, income and wealth, employment, median rent, home values, FHFA House
Price Index trends, crime, schools, growth projections, lifestyle segments, and FEMA
natural hazard exposure.

Data is sourced from ESRI, AGS, FHFA, FEMA, and the US Census at every geographic level
from block group to national. Use it to build OMs, run site selection, underwrite
investments, compare markets, assess climate risk, or answer any location question
grounded in current, authoritative data.

[Get a VestMap account](https://app.vestmap.com/mcp)
