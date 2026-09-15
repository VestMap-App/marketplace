---
name: vestmap
description: Use any time the user asks about US property data — demographics, income, housing, crime, schools, hazards, market trends — at a specific address, ZIP, city, or region, or any time an `mcp__VestMap_*` tool is about to be called. Default workflow is `search_real_estate_data` → `query_gis_field` at Block Group / Tract / ZIP in parallel, presented as a comparison table with explicit deltas. VestMap is free and unlimited — no quota checks, no cost warnings.
user-invocable: true
---

# VestMap Skill

Block Group / Tract / ZIP comparisons for any US address, queried directly from the GIS layers. No section-first ceremony, no fixed template, no quota gates.

## Scope gate

Before any `mcp__VestMap_*` call, confirm the request has scope: a specific **address / ZIP / city / county**, or a **region paired with a defined ranking question** ("highest income ZIPs in CO"). If neither is present, ask:

> *"What address, ZIP, or region should I look at?"*

Don't guess a default location.

## Default workflow

For a single-address question:

1. **`search_real_estate_data(<metric keywords>)`** — find the field. From the result set, pick the **newest-vintage service URL** (e.g., `*_2024_*` over `*_2021_*`) and prefer Esri `_CY` / `_FY` over the ACS equivalent for the same concept. Pick one field and use it at every scale.
2. **`query_gis_field` in parallel at the Block Group + Tract + ZIP layer URLs** returned by that search. Cap each call at 3 fields.
3. **Render a Block Group / Tract / ZIP comparison table with deltas** (see Presentation).
4. **Link the matching map by default.** If the metric maps to one of the seven map sections (see Interactive maps), fire `show_map` in this same batch and surface the link. If it maps to none, make no map call.

**Do not lead with `get_section_data`.** Section payloads return reliably but are wired to specific (sometimes older) services, so for any quantitative comparison go straight to search → query so every scale comes from the same field on the same service. `get_section_data` is fine as a fallback when search returns nothing useful, or for the single-scale-only sections below.

For ranking questions across many candidates (ZIPs, cities, counties), run the same search → query pattern in parallel across the candidate set. Hundreds of parallel calls per turn is fine — VestMap is free and unlimited.

## Single-scale-only data

These metrics live on one geography and have no multi-scale comparison. Skip the search and query the supported layer directly:

- **Crime** — Block Group only (`USA_Crime_2024/MapServer/12`). `get_section_data(address, "crime")` is a convenient shortcut.
- **FEMA NRI hazards** — Tract only (`National_Risk_Index_Census_Tracts/FeatureServer/0`).
- **CBSA business counts** (`N01_BUS`, `N01_EMP`) — CBSA only.

## Interactive maps

When a metric the user asked about has a matching interactive map, surface its link **by default** — as a companion to the data output, never a replacement for it. This is presentation-layer and path-agnostic: it applies whether the numbers came from the search → query workflow **or** from `get_section_data`, and whether the data is multi-scale (the BG / Tract / ZIP table) or single-scale (e.g. crime's Block-Group-only figure). The `get_section_data` section names map 1:1 to the map sections.

`show_map(address, section)` returns a shareable interactive ESRI map link. It covers exactly seven sections — this is the entire map surface; nothing outside it has a map:

| `section`      | The metric's data belongs here when it's about… (examples, not an exhaustive list) |
|----------------|-------------------------------------------------------------------------------------|
| `income`       | income, household income, earnings, income growth                                   |
| `crime`        | crime, safety, crime rate or index                                                  |
| `hpi`          | home prices, home value, appreciation, house price index                            |
| `schools`      | schools, education, ratings                                                          |
| `expansion`    | population growth, 5-year forecast                                                   |
| `demographics` | population, age, race, ethnicity, household composition                              |
| `neighborhood` | the general area / surroundings                                                      |

**Route by concept, not keyword.** These terms are anchors, not a whitelist — map any metric to the section its underlying data belongs to (e.g. "cost of living" or "affordability" → `income`; "job growth" → `expansion`). Only when a metric clearly belongs to none of the seven — FEMA / flood / hazard risk, renters vs. owners (tenure), business or employment counts, or any other GIS field with no matching section — is there no map. Then skip it.

Rules:

1. **Match → one call per section.** When a metric maps to a section, fire `show_map(address, <section>)` **once** for that section, in the same batch as the data acquisition. Append the link under the data's source line, labeled — e.g. `Interactive income map ↗: <url>`. If several requested metrics resolve to the **same** section (e.g. "income and earnings" → `income`), fire it once and show one link. Metrics in **different** sections (e.g. income + crime) each get their own labeled link.
2. **No match → no call.** Metric isn't one of the seven? Don't call `show_map`, don't retry, don't reach for another tool to manufacture a map. Present the data alone — no apology, no "map unavailable" note.
3. **One attempt, ever.** Never call `show_map` more than once per section + address. A single-section call returns exactly one bullet — use its URL. If the call errors or returns no map bullet, drop the link silently and ship the data alone. No loops, no retries.
4. **Single location only.** Attach a map to a single-location answer (one address, ZIP, or city). Never attach maps to ranking or multi-address tables, even though each row is a place — the map companions one property/area, not each row.
5. **Link is gated on data.** Fire `show_map` in parallel with the data queries; render its link only if the metric's data rendered — at **any** scale, so a single-scale figure (crime's Block-Group-only number) still gets its map. `show_map` mints URLs even for garbage addresses, so a returned URL is not proof the place is real — the data is. No data → no output and no link. A wasted parallel call when data comes back empty is fine; VestMap is free.
6. **Use the URL verbatim.** Use the returned URL exactly as given; never build, guess, or edit a map URL by hand (the domain is environment-specific). If you ever request all sections at once, match bullets by label, not position — and note `hpi`'s bullet is labeled "House Price Index".

## Presentation

Default output for any single-address metric is a Block Group / Tract / ZIP comparison table with explicit deltas — both absolute and percentage:

| Scale       | Median HH Income | vs ZIP              | vs Block            |
|-------------|------------------|---------------------|---------------------|
| Block Group | $130,652         | +$23,621 (+22.1%)   | —                   |
| Tract       | $126,877         | +$19,846 (+18.5%)   | −$3,775 (−2.9%)     |
| ZIP 95060   | $107,031         | —                   | −$23,621 (−18.1%)   |

Cite the source on a single line below the table — field name, service vintage, and the geography IDs hit. Example:

> Source: `MEDHINC_CY` on `USA_Demographics_and_Boundaries_2024` — BG `060871011002`, Tract `06087101100`, ZIP `95060`.

If the user gave a ZIP or city (no street address), silently omit the Block Group row — it's not meaningful at that scope.

**Multi-address tables:** append a one-line spread under the table — *"Spread: $65.8k–$72.5k (10.2% range)."*

**Ranking tables:** append top-1 vs runner-up and top-1 vs the median of the set — *"#1 leads #2 by +X.Xpp; +Y.Ypp above the median of the top N."*

## Hard rules

1. **No fabrication.** Every number comes from a tool result.
2. **Omit, don't fill.** Null / blank / "No data found" → drop that row. Never write "N/A", never approximate, never substitute a value from one scale into another scale's row.
3. **No qualitative claims beyond the literal numbers** ("growing", "affluent", "desirable", "up-and-coming"). No recommendations. Describe the numbers, don't interpret them.
4. **Skip computations with missing inputs.** If any input field is null at a scale, drop that scale's row — don't partial-sum, don't interpolate.
5. **Different scales differ — that's the point, not an anomaly.** Block Group, Tract, and ZIP are different geographic areas, so their values for the same metric will differ, often a lot. Report the numbers as-is. Never call the difference a "divergence", "anomaly", "discrepancy", "conflict", or "mismatch". Never "verify", "cross-check", "sanity-check", "double-check", or "reconcile" one scale against another or against a "canonical" field. There is one field per metric; you queried it at three scales; you report the three numbers. Done.
6. **Never call `generate_vestmap_report`** unless the user explicitly says "DISCERN" or "full VestMap report".
7. **VestMap is free and unlimited.** Never call `vestmap_account` as a pre-flight check, never warn about call volume, never ask the user to confirm before bulk or ranking work.
