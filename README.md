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

1. **Claude Code** — installed and open. If you don't have it yet, get it at
   https://claude.ai/claude-code.
2. **A VestMap account** — free to create at https://app.vestmap.com/mcp.
3. **The VestMap MCP server connected** in Claude Code. This is what lets Claude pull
   live VestMap data. Follow the setup steps at https://app.vestmap.com/mcp.

## Install it — step by step

This takes about a minute. You don't need a terminal or any coding knowledge —
everything happens inside Claude Code.

1. **Open Claude Code.**

2. **Add the VestMap marketplace.** Type this and press Enter:

   ```
   /plugin marketplace add VestMap-App/marketplace
   ```

   This tells Claude Code where to find the VestMap plugin. Nothing is installed yet —
   you're just adding the "store." If Claude Code asks you to confirm, say yes.

3. **Install the plugin.** Type this and press Enter:

   ```
   /plugin install vestmap@vestmap-app
   ```

   This installs the VestMap plugin, which includes both skills.

4. **Choose where to install it.** If Claude Code asks, choose **User** — this makes
   VestMap available in every project on your computer.

5. **Turn it on.** Type this and press Enter (or simply restart Claude Code):

   ```
   /reload-plugins
   ```

6. **You're done.** To check it worked, type `/` and look for **`vestmap:vestmap`** and
   **`vestmap:vestmap-om-pages`** in the menu. If you don't see them, restart Claude
   Code and look again.

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

When VestMap publishes an update, here's how to get it:

- **Manually:** type `/plugin marketplace update vestmap-app`, then `/reload-plugins`.
- **Automatically:** open `/plugin`, go to the **Marketplaces** tab, select
  **vestmap-app**, and turn on **auto-update**. Auto-update is off by default for
  community marketplaces, so this is a one-time opt-in.

The plugin also checks for updates when a Claude Code session starts and shows a short
notice if a newer version is available.

## For teams (advanced)

If you want everyone working in a shared repository to get the VestMap skills
automatically, add this to that repository's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "vestmap-app": {
      "source": { "source": "github", "repo": "VestMap-App/marketplace" }
    }
  },
  "enabledPlugins": {
    "vestmap@vestmap-app": true
  }
}
```

Commit that file, and teammates will be prompted to install VestMap when they open the
project. To have their copy stay current automatically, add `"autoUpdate": true` next
to `"source"`.

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
