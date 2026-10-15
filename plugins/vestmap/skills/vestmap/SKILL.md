---
name: vestmap
description: Use any time the user asks about US property data — demographics, income, housing, workforce, crime, businesses, schools, hazards, market trends — at a specific address, ZIP, city, or region, or any time an `mcp__VestMap_*` tool is about to be called. Default workflow is ONE `get_radius_demographics` call carrying every requested field, read at Block Group / Tract / ZIP from 2026 Esri GeoEnrichment and presented as a comparison table with explicit deltas; the same call holds 1 / 3 / 5-mile ring values. VestMap is free and unlimited — no quota checks, no cost warnings.
user-invocable: true
---

# VestMap Skill

Block Group / Tract / ZIP comparisons for any US address from 2026 Esri GeoEnrichment. One call returns every requested field at every scale, with 1 / 3 / 5-mile rings alongside. No section-first ceremony, no fixed template, no quota gates.

## Scope gate

Before any `mcp__VestMap_*` call, confirm the request has scope: a specific **address / ZIP / city / county**, or a **region paired with a defined ranking question** ("highest income ZIPs in CO"). If neither is present, ask:

> *"What address, ZIP, or region should I look at?"*

Don't guess a default location.

## Default workflow

For a single-address question:

1. **Pick the field codes.** Take them from §Field codes. For a metric not listed there, `search_real_estate_data(<metric keywords>)` and use a result's `fieldName` (the Esri code, e.g. `OCCMGMT_CY`), preferring `_CY` (current year) and `_FY` (five-year forecast) codes over ACS ones for the same concept. The search only finds the code; never query the layer URLs it returns for an Esri demographic field.
2. **One `get_radius_demographics(address, fieldNames=[…])` call** with every code the answer needs (up to 25; split a longer list into parallel calls). For each field, `fields.<code>.blockTractZip` holds `block` (the block group), `tract`, `zip`, `county`, `state` and `national`, and `fields.<code>.radius."1"` / `"3"` / `"5"` hold the ring values as `{available, value}`. Read `blockTractZipVintage` and state that year.
3. **Render the Block Group / Tract / ZIP comparison table with deltas** (see Presentation).
4. **Link the matching interactive map by default.** If the metric maps to one of the seven map sections (see Interactive maps), fire `show_map` in this same batch and surface the link. If it maps to none, make no map call.
5. **Offer the rings.** When the question is about a site, deal, OM or trade area, close with one line: "The same data is available at 1 / 3 / 5-mile rings — want those?" When the user asked for 1 / 3 / 5 miles, a radius or rings, present the ring table instead (see Presentation).

Every `get_radius_demographics` call also renders a ring map (`mapImageUrl`, about 30 seconds). It belongs to a ring answer: link it only when the reply shows ring values, and pass `shadeField` set to the field the user cares about (keep it in `fieldNames` too, so the map matches the numbers). A null `mapImageUrl` with a `mapError` is a render failure; when the answer needs the map, repeat the identical call once, and if it fails again ship the table without it.

**Never use `query_gis_field` for Esri demographics.** The `USA_Demographics_and_Boundaries_*` and `USA_Crime_*` layers it reads are the older 2024 vintage, one scale per call. It stays for the non-Esri layers in §Other sources and for boundary names (a county's `NAME`).

**`get_section_data`** sections `income`, `expansion` and `crime` read the same 2026 GeoEnrichment and are fine for a one-section question (`crime` returns the block group's ten indexes); an answer that spans sections is one `get_radius_demographics` call. The `hpi` and `neighborhood` sections are not connected: never call them. A section that returns nothing is omitted, not retried.

**Older connector.** If `get_radius_demographics` takes only a single `fieldName` (no `fieldNames` or `shadeField`), or the call rejects `fieldNames`, tell the user once: "This needs the latest VestMap connector. Install it from app.vestmap.com/mcp, then ask again."

## Field codes

All 2026 Esri GeoEnrichment, available at Block Group, Tract, ZIP, County, State, National and 1 / 3 / 5 miles:

| Ask | Codes |
|---|---|
| Household income | `MEDHINC_CY` median · `MHIGRWCYFY` forecast annual growth (%) |
| Home value | `MEDVAL_CY` median |
| Rent | `MEDCRNT_CY` median monthly contract rent (`MEDRENT_CY` does not exist) |
| Population, households, growth | `TOTPOP_CY` · `TOTHH_CY` · `POPGRWCYFY` (annual population growth 2026–2031, %) |
| Age, household size | `MEDAGE_CY` · `AVGHHSZ_CY` |
| Tenure | `owner_occupied_pct` · `renter_occupied_pct`, or the counts `OWNER_CY` · `RENTER_CY` |
| Income brackets | `income_under_50k_pct` · `income_50k_100k_pct` · `income_100k_150k_pct` · `income_150k_plus_pct` |
| Education | `bachelors_plus_pct` (adults 25+) |
| Workforce | `white_collar_pct` · `blue_collar_pct` · `services_pct` (shares of employed, sum to 100) · `UNEMPRT_CY` (%) · `EMP_CY` |
| Crime (index, 100 = national) | `CRMCYTOTC` total · `CRMCYPERC` personal · `CRMCYPROC` property · `CRMCYMURD` · `CRMCYRAPE` · `CRMCYROBB` · `CRMCYASST` · `CRMCYBURG` · `CRMCYLARC` · `CRMCYMVEH` (motor vehicle theft) |
| Businesses | `N01_BUS` businesses · `N01_EMP` employees (NAICS totals) |

The lowercase codes are derived metrics the connector computes at every scale and ring; their values are already percentages. Any other Esri code works the same way. An unknown code makes the call fail with a message naming it: search for the right code, never guess one.

## Other sources

These are not Esri demographics and keep their own tools:

- **FEMA NRI hazards** — Tract only: `query_gis_field` on `National_Risk_Index_Census_Tracts/FeatureServer/0` (find the field with `search_real_estate_data("flood risk")` and similar).
- **Schools** — `get_section_data(address, "schools")`.

Home values come from `MEDVAL_CY` (§Field codes). VestMap has no current home price index or appreciation series: if the user asks for appreciation, say so in one line and give `MEDVAL_CY` instead.

## Interactive maps

When a metric the user asked about has a matching interactive map, surface its link **by default** — as a companion to the data output, never a replacement for it. This is presentation-layer and path-agnostic: it applies whether the numbers came from `get_radius_demographics` **or** from `get_section_data`, and whether the data is multi-scale (the BG / Tract / ZIP table) or single-scale (a schools section). The `get_section_data` section names map 1:1 to the map sections.

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

**Route by concept, not keyword.** These terms are anchors, not a whitelist — map any metric to the section its underlying data belongs to (e.g. "cost of living" or "affordability" → `income`; "job growth" → `expansion`). Only when a metric clearly belongs to none of the seven — FEMA / flood / hazard risk, renters vs. owners (tenure), business or employment counts, or any other field with no matching section — is there no map. Then skip it.

Rules:

1. **Match → one call per section.** When a metric maps to a section, fire `show_map(address, <section>)` **once** for that section, in the same batch as the data acquisition. Append the link under the data's source line, labeled — e.g. `Interactive income map ↗: <url>`. If several requested metrics resolve to the **same** section (e.g. "income and earnings" → `income`), fire it once and show one link. Metrics in **different** sections (e.g. income + crime) each get their own labeled link.
2. **No match → no call.** Metric isn't one of the seven? Don't call `show_map`, don't retry, don't reach for another tool to manufacture a map. Present the data alone — no apology, no "map unavailable" note.
3. **One attempt, ever.** Never call `show_map` more than once per section + address. A single-section call returns exactly one bullet — use its URL. If the call errors or returns no map bullet, drop the link silently and ship the data alone. No loops, no retries.
4. **Single location only.** Attach a map to a single-location answer (one address, ZIP, or city). Never attach maps to ranking or multi-address tables, even though each row is a place — the map companions one property/area, not each row.
5. **Link is gated on data.** Fire `show_map` in parallel with the data call; render its link only if the metric's data rendered — at **any** scale. `show_map` mints URLs even for garbage addresses, so a returned URL is not proof the place is real — the data is. No data → no output and no link. A wasted parallel call when data comes back empty is fine; VestMap is free.
6. **Use the URL verbatim.** Use the returned URL exactly as given; never build, guess, or edit a map URL by hand (the domain is environment-specific). If you ever request all sections at once, match bullets by label, not position — and note `hpi`'s bullet is labeled "House Price Index".

## Map images

Only when the user asks for a map **image** (not a link):

- **Block-group choropleth:** `custom_map_screenshot(address, service_url, field_name)` with the Esri code as `field_name` and the Block Group layer URL that `search_real_estate_data` returned for it, or `custom_map_screenshot(address, derived_metric)` for a lowercase metric. Use `class_breaks_count: 5`, `classification_method: "quantile"`, a ramp suited to the meaning (green/blue for income or population, red/orange only for risk) and a short `legend_title`. Its reply states a "Data year": say that year with the image. If the year is not "2026 (Esri GeoEnrichment)", use the ring map instead.
- **Rings:** the `mapImageUrl` of a `get_radius_demographics` call shaded by `shadeField`.

Never use `static_map` (a plain basemap carrying no VestMap data), and never pass a free-text `data_query` (it can resolve to an older or retired service).

## Presentation

Default output for any single-address metric is a Block Group / Tract / ZIP comparison table with explicit deltas — both absolute and percentage:

| Scale       | Median HH Income | vs ZIP              | vs Block            |
|-------------|------------------|---------------------|---------------------|
| Block Group | $130,652         | +$23,621 (+22.1%)   | —                   |
| Tract       | $126,877         | +$19,846 (+18.5%)   | −$3,775 (−2.9%)     |
| ZIP 95060   | $107,031         | —                   | −$23,621 (−18.1%)   |

Several fields → one table with a column per field (deltas can then go in a second line per cell, or be dropped for counts). Cite the source on a single line below the table — data year, the field codes, and the geographies:

> Source: Esri GeoEnrichment 2026, `MEDHINC_CY` — the block group, tract and ZIP 95060 containing the address.

- **County, State, National** come back in the same payload. Add them as rows when the user asks how the area compares more broadly, and for crime indexes, which are scaled to a national 100.
- **ZIP given** (no street address): show the ZIP row, with County / State / National as references, and silently omit the Block Group and Tract rows (they belong to the ZIP's centre point). **City given:** show the ZIP and County at the city's centre point, labelled as such. A **county** given: the County row with State / National.
- **Rings** (asked for, or accepted from the offer): rows 1 mi / 3 mi / 5 mi with deltas against 1 mi, County and National as references when useful, and the source line "Esri GeoEnrichment {radiusVintage}, 1 / 3 / 5-mile rings". Ring counts (population, households, businesses) are totals that include the smaller rings. If `radiusVintage` differs from `blockTractZipVintage`, show ring and Block / Tract / ZIP values as separate column groups, never as a year-over-year change. Link the ring map under the table.

**Multi-address tables:** one `get_radius_demographics` call per address, all in one parallel batch with the same `fieldNames`; read the same scale for every row. Append a one-line spread under the table — *"Spread: $65.8k–$72.5k (10.2% range)."*

**Ranking tables:** one call per candidate in one parallel batch, with the ZIP, county or address as `address`, reading the matching scale (`zip` for a ZIP ranking, `county` for a county ranking). Cities have no scale of their own in the payload: rank them by county or by their ZIPs and say which. Append top-1 vs runner-up and top-1 vs the median of the set — *"#1 leads #2 by +X.Xpp; +Y.Ypp above the median of the top N."*

## Hard rules

1. **No fabrication.** Every number comes from a tool result.
2. **Omit, don't fill.** Null / blank / "No data found" / `available: false` → drop that row. Never write "N/A", never approximate, never substitute a value from one scale into another scale's row.
3. **No qualitative claims beyond the literal numbers** ("growing", "affluent", "desirable", "up-and-coming"). No recommendations. Describe the numbers, don't interpret them.
4. **Skip computations with missing inputs.** If any input field is null at a scale, drop that scale's row — don't partial-sum, don't interpolate.
5. **Different scales differ — that's the point, not an anomaly.** Block Group, Tract, ZIP, County, the rings and the nation are different areas, so their values for the same metric will differ, often a lot. Report the numbers as-is. Never call the difference a "divergence", "anomaly", "discrepancy", "conflict", or "mismatch". Never "verify", "cross-check", "sanity-check", "double-check", or "reconcile" one scale against another or against another field. There is one field per metric; one call returned it at every scale; you report the numbers. Done.
6. **Never call `generate_vestmap_report`** unless the user explicitly says "DISCERN" or "full VestMap report".
7. **VestMap is free and unlimited.** Never call `vestmap_account` as a pre-flight check, never warn about call volume, never ask the user to confirm before bulk or ranking work.
8. **Never call `static_map`.** Maps are VestMap's own: `show_map` links, `custom_map_screenshot` choropleths and the ring map.
