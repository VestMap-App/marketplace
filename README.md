# VestMap for Claude Code

Real-estate skills for Claude Code from the VestMap marketplace: location intelligence,
Offering Memorandum pages, and rental-property pro formas.

## Skills

- **`vestmap`** — Ask any question about a US address: demographics, income, housing, workforce,
  crime, schools, hazards, and market trends, answered with clear comparison tables.
- **`vestmap-om-pages`** — Generate a presentation-ready Offering Memorandum (OM) page for any US
  address as a PDF.
- **`rental-property-analyzer`** — Turn a rent roll + T12 + loan terms into an investor-grade pro
  forma: an editable Excel model (Current vs. Proforma, NOI, cap rate, DSCR, cash-on-cash, loan
  amortization, multi-year projection) plus a polished PDF report with a KPI dashboard and charts.

## Install

```bash
claude plugin marketplace add VestMap-App/marketplace
claude plugin install vestmap@vestmap-app
claude plugin install rental-analyzer@vestmap-app
```

For live VestMap data, you'll also need a free account and the VestMap MCP server connected —
set up at https://app.vestmap.com/mcp.

## Using the skills

Just ask Claude naturally and the right skill activates on its own:

- *"Median household income around 1600 Pennsylvania Ave NW, Washington, DC?"* → `vestmap`
- *"Make an OM page for 1600 Pennsylvania Ave NW."* → `vestmap-om-pages`
- *"Analyze this rental — here's the rent roll and T12."* → `rental-property-analyzer`

Or trigger one explicitly: `/vestmap:vestmap`, `/vestmap:vestmap-om-pages`,
`/rental-analyzer:rental-property-analyzer`.

## Staying up to date

Turn on auto-update once and forget it: keep `"autoUpdate": true` on the `vestmap-app` marketplace
in your `~/.claude/settings.json`, or run `/plugin` → **Marketplaces** → **vestmap-app** → **Enable
auto-update**. To update right now:

```bash
claude plugin marketplace update vestmap-app
claude plugin update vestmap@vestmap-app
claude plugin update rental-analyzer@vestmap-app
```

## For teams

Commit this `.claude/settings.json` to a shared repo so everyone gets the skills automatically:

```json
{
  "extraKnownMarketplaces": {
    "vestmap-app": {
      "source": { "source": "github", "repo": "VestMap-App/marketplace" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "vestmap@vestmap-app": true,
    "rental-analyzer@vestmap-app": true
  }
}
```

## Publishing (maintainers)

Users only receive changes when you bump a plugin's `"version"` (semver) in its
`.claude-plugin/plugin.json` — under `plugins/vestmap/` or `plugins/rental-analyzer/` — then commit
and push to the default branch. Auto-update users pick it up next session; web/cloud sessions get it
immediately.

## About VestMap

VestMap brings nationwide location intelligence to AI agents — demographics, income, housing,
employment, rents, home values, crime, schools, growth projections, and FEMA hazard exposure,
sourced from ESRI, AGS, FHFA, FEMA, and the US Census. [Get an account](https://app.vestmap.com/mcp).
