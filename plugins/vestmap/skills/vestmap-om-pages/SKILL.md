---
name: vestmap-om-pages
description: Render a property Offering Memorandum (OM) page for any US address as a visual, page-oriented PDF (the default output). Shows Population, Income, Housing, and Rental at Block / Tract / ZIP / County scale with explicit cross-scale deltas, plus a Safety block (Block-Group crime index) and a section-matched VestMap data map on every mappable section — Income, Housing, Rental and Safety each carry their own block-group choropleth with a real legend, built with `custom_map_screenshot`. Use when the user asks for an "OM", "one-pager", "investor page", "property page", "marketing page", or a rendered / laid-out visual for a US property. Self-contained — this file carries its own layout, HTML template, and PDF steps; it needs no other file. Optional modules (Workforce, Risk, Schools, Education, Income distribution, Businesses, HPI) render only when the user names them.
user-invocable: true
---

# VestMap OM Pages

Generate a presentation-ready Offering Memorandum PDF for a single US address. All numbers come from VestMap MCP tool calls; each mappable section carries its own matching VestMap map image. This file is **self-contained**: the layout, the full HTML/CSS template, and the PDF command are all below — do not look for or depend on any `references/…` or `templates/…` file, and do not fetch anything over the network for page content beyond the VestMap map images.

## Hard rules

- **PDF is the default output.** Write the HTML to a temp file, convert to PDF with headless Chrome (see §PDF), print the PDF path. Only output HTML instead if the user says "HTML" / "html only".
- **Every number traces to a VestMap tool call** (`get_section_data`, `query_gis_field`, `custom_map_screenshot`, `search_real_estate_data`). If you can't name the call that produced a value, it does not go on the page. No inference, no memory, no fabrication.
- **Missing data disappears — it is never announced.** If a value is null/blank, drop that cell. If a row has fewer than 2 non-null value cells, drop the row. If a section has fewer than 2 rows, drop the section. For a masthead locality segment with no value (e.g. no MSA), drop that segment **and its trailing `· ` separator** so no empty `· ·` remains. The page never contains "N/A", "—", "data unavailable", tool names, field names, or any note about what was dropped. It just gets smaller. The chat reply after generation is equally quiet (see §Respond).
- **Different scales differ — that is normal, never a problem.** Block / Tract / ZIP / County cover different areas, so their values differ. Report them as-is. Do not verify, cross-check, reconcile, or describe any cross-scale difference as a divergence/anomaly.
- **No Tapestry, ever.** Never call `get_section_data("demographics")` for numbers and never put a Tapestry segment/grade/lifestyle label on the page.
- **No prose claims beyond the numbers.** No "desirable", "up-and-coming", "affluent", "safe". Labels and numbers only.
- **Market-agnostic.** The page reads identically for any US market. A market name appears only in the address, the locality line, and (data-driven) the MSA. Nothing city-specific is hardcoded.
- **No "Offering Memorandum" eyebrow.** The masthead is just the address.
- **The comparison table always gets the full 7.4in column — never put a map beside it.** Seven-digit values are routine in high-cost metros (Santa Clara, SF, NYC), and the geometry is unforgiving. Full width: 7.4in − 1.63in metric column = 1.44in per value cell, and `$1,538,982` at 12pt needs ~0.95in — 34% headroom. With a 2.45in map beside it: 4.73in − 1.04in = **0.92in** per cell, and the same value **overlaps its neighbour** (real failure: `$1,107,164$1,538,982`). `table-layout:fixed` gives a number no break opportunity, so it silently runs into the next column rather than wrapping or clipping. Never reintroduce a side-by-side map to buy vertical space.

## Workflow

1. **Parse** the subject address; note its ZIP.
2. **Acquire data** — fire all of this in parallel in one turn (VestMap is free and unlimited; never warn about volume):
   - `get_section_data(address, "income")` → `median_household_income` and `median_home_value` at block/tract/zip/county.
   - `get_section_data(address, "expansion")` → 5-yr population-growth CAGR at block/tract/zip/county.
   - `get_section_data(address, "crime")` → the `CRMCY*` crime **indices** at Block Group.
   - `query_gis_field` batches (≤3 fields each) at the four demographics layers — see §Data.
   - `query_gis_field(address, <County layer /7>, ["NAME"])` → the **county name** (→ `{{COUNTY}}`); and `query_gis_field(address, <CBSA layer>, ["NAME"])` → the **MSA name** (→ `{{MSA}}`). See §Data.
   - **Hero aerial coords** — geocode the property for the aerial hero map: WebFetch the US Census geocoder `https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=<url-encoded address>&benchmark=Public_AR_Current&format=json` → read `result.addressMatches[0].coordinates` (`x`=lng, `y`=lat). If it returns no match, the hero is dropped (graceful).
   - **Section maps** — one `custom_map_screenshot` call per placed map (Income, Housing, Rental, Safety), each with the exact `service_url` / `field_name` / `colors` / `classification_method` from the registry in §Maps. Population has no map — see §Maps.
3. **Compute** the delta chips and the two derived metrics (renter share, HV growth) — see §Computations. Precondition-gate every computation: if a component is null, skip it.
4. **Sweep** for empties (drop empty cells → thin rows → thin sections; drop empty masthead segments) per the hard rules.
5. **Fill the template** in §Template with the subject's values and the map URLs.
6. **Convert to PDF** per §PDF. Output `vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf` in the current directory.
7. **Respond** minimally: the PDF path + one sentence naming the address.

## Data — what fills each section

Demographics layers (`query_gis_field`, ≤3 fields per call, run every field at all four scales in parallel):

| Scale | Layer URL |
|---|---|
| Block | `https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer/12` |
| Tract | `…/USA_Demographics_and_Boundaries_2024/MapServer/11` |
| ZIP | `…/USA_Demographics_and_Boundaries_2024/MapServer/9` |
| County | `…/USA_Demographics_and_Boundaries_2024/MapServer/7` |

| Section | Metric (row) | Source | Chips? |
|---|---|---|---|
| **Population** | Total population | `TOTPOP_CY` | yes |
| | Median age | `MEDAGE_CY` | yes |
| | Avg HH size | `AVGHHSZ_CY` | yes |
| | 5-yr pop growth | `get_section_data("expansion")` | yes |
| **Income** | Median HHI | `get_section_data("income").median_household_income` | yes |
| | HHI 2029 (forecast) | `MEDHINC_FY` | plain |
| | 5-yr HHI growth | `MHIGRWCYFY` | yes |
| | Per capita income | `PCI_CY` | plain |
| | Unemployment | `UNEMPRT_CY` (fallback `UNEMP_CY / (EMP_CY + UNEMP_CY) × 100`) | yes |
| **Housing Values** | Median home value | `get_section_data("income").median_home_value` (block/tract/zip); `MEDVAL_CY` at `/7` for County | yes |
| | HV 2029 (forecast) | `MEDVAL_FY` | plain |
| | 5-yr HV growth | computed — see §Computations | yes |
| **Rental Market** | Median rent | `MEDCRNT_CY` (Esri "Median Contract Rent" — the canonical field; **`MEDRENT_CY` does not exist on this service — never query it**) | yes |
| | Renter units | `RENTER_CY` | plain |
| | Owner units | `OWNER_CY` | plain |
| | Renter share | computed — see §Computations | yes |
| **Safety** | Crime indices | `get_section_data("crime")` → `CRMCYTOTC/PROC/PERC/MURD/RAPE/ROBB/ASST/BURG/LARC` (Block Group) | n/a (grid) |

Context callouts (top of page 1): Median HHI · ZIP, Median Home Value · ZIP, Pop Growth · ZIP (all ZIP-scale, from the sources above).

Locality-line names (used verbatim, one `query_gis_field` each):
- **County** (`{{COUNTY}}`): `query_gis_field(address, …/MapServer/7, ["NAME"])` → e.g. `"Cook County"` (fallback `NAMELSAD`).
- **MSA** (`{{MSA}}`): `query_gis_field(address, https://services5.arcgis.com/9fQmObndozAJu9f5/arcgis/rest/services/Enriched_USA_Metropolitan_Statistical_Areas/FeatureServer/0, ["NAME"])` → e.g. `"Chicago-Naperville-Elgin, IL-IN-WI"` (fallbacks `NAMELSAD`, `MSA_NAME`). If the address is in no CBSA, drop the MSA segment (and its separator) per the sweep rule.

**`query_gis_field` is all-or-nothing:** one bad/absent field name makes the whole call return "No data found". The field names above are validated. If a batch returns "No data found", re-probe its fields one per call (parallel) and drop only the null ones — never surface the failure.

## Maps — hero aerial + section-matched custom maps

Every mappable section carries its own map, built with **`custom_map_screenshot`** — the arbitrary-field renderer — not `map_screenshot`. `custom_map_screenshot` is what makes a per-section map possible at all: it symbolizes *any* field on *any* layer, so sections that the fixed 7-section `map_screenshot` enum never covered (Rental) get a map, and sections whose fixed map is broken (Safety) get a working one. It also **bakes a real legend with the actual class breaks into the image**, which `map_screenshot` does not.

**Hero = a clean aerial base map**, NOT a data layer. No map tool renders a plain property-centered aerial, so the hero stays a Leaflet + ESRI World Imagery render at the geocoded lat/lng (see the `#hero` script in the template). If geocoding failed (no lat/lng), drop the `#hero` div and its caption.

### The section-map registry

Fire all of these in parallel, in the same batch as the data calls. Pass every argument shown — none are optional in practice (see §Map rules for why).

| Section | `service_url` | `field_name` | `field_alias` / `legend_title` | `colors` | Template slot |
|---|---|---|---|---|---|
| Population | *(omit — see below)* | | | | `{{POP_MAP_URL}}` |
| Income | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDHINC_CY` | `2024 Median Household Income` / `Median household income` | `["#f7fcf5","#c7e9c0","#74c476","#31a354","#006d2c"]` | `{{INCOME_MAP_URL}}` |
| Housing Values | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDVAL_CY` | `2024 Median Home Value` / `Median home value` | `["#f7f4f9","#d4b9da","#c994c7","#df65b0","#980043"]` | `{{HOUSING_MAP_URL}}` |
| Rental Market | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDCRNT_CY` | `2024 Median Contract Rent` / `Median contract rent` | `["#edf8fb","#b2e2e2","#66c2a4","#2ca25f","#006d2c"]` | `{{RENTAL_MAP_URL}}` |
| Safety | `https://demographics5.arcgis.com/arcgis/rest/services/USA_Crime_2024/MapServer/12` | `CRMCYTOTC` | `2024 Total Crime Index` / `Crime index · 100 = U.S. avg` | `["#fee5d9","#fcae91","#fb6a4a","#de2d26","#a50f15"]` | `{{SAFETY_MAP_URL}}` |

`…/USA_Demographics_and_Boundaries_2024/MapServer/12` is the **Block Group** layer — the same `/12` used for the Block column of every table, so each map is drawn at the finest scale the page reports. Full prefix: `https://demographics5.arcgis.com/arcgis/rest/services/`.

Every call also passes:

```
classification_method: "equal-interval"
class_breaks_count:    5
address:               <the subject address>
```

### Map rules

- **`classification_method` MUST be `"equal-interval"`.** `"quantile"` is unusable: its sample is polluted by null/zero features, so breaks collapse (a real Denver run produced breaks of `0 · 0 · 7,969 · 12,832 · 200,001` — the whole metro rendered as one flat colour). Equal-interval produces usable, readable breaks on every field in the registry.
- **Always pass `colors` explicitly**, matched to the meaning of the data: red ramps for risk/crime only, green/teal for income and rent, purple for home value, blue for population. The server applies no colour heuristics — an unspecified ramp is not guaranteed to suit the field.
- **Always pass `legend_title`** — it is the text printed on the baked-in legend, so it must read as a finished caption, never as a debug label. Never leave the classification method or field name in it.
- **Breaks are national, not local.** The same field returns identical class breaks in every market (verified: Denver and Minneapolis both returned `449.6 / 896.2 / 1,343 / 1,789 / 2,236` for `CRMCYTOTC`). This is a feature for an OM — an index value means the same thing in every market, so pages are comparable — but it does mute local contrast, and it is what breaks the Population map (below).
- **Do not use `data_query` for section maps.** Free-text resolution picks whatever layer it matches, often a coarser geography (ZIP or County) than the page's Block Group. Use it only for the ad-hoc maps in §Custom maps on request.
- **`map_id` is unnecessary.** Every registry entry renders correctly on the plain-basemap fallback. Passing a webmap ID changes only the basemap underneath, never the data layer.
- **The image is 1120×560 (2:1) with the legend in the TOP-RIGHT corner.** The slot must preserve that: never crop from the top, or the legend is the first thing lost, and never crop below 50% of the source height, or the property marker (dead centre) is lost. See the `.secmap` CSS.

### Maps that are wired but omitted today

Two maps are fully specified here and deliberately **not rendered**, because both currently
produce a *blank* image that the service returns as success — graceful-failure cannot catch
them, so they must be suppressed on purpose. Leave the slot empty and drop the `<figure>`
(and the `sec--map` class if the section has no other map).

| Map | Section | Intended field / layer | Why it is off |
|---|---|---|---|
| Population growth | Population | `POPGRWCYFY` at `…2024/MapServer/12`, blue ramp | One national outlier (a block group at +252.73 %/yr) stretches the equal-interval breaks so far that every block group in any real market lands in the bottom class. `TOTPOP_CY` fails identically (national max 36,584). |
| Renter tenure | Rental Market (2nd map) | `RENTER_CY` at `…2024/MapServer/12`, blue-purple ramp | Two separate blockers. (a) There is **no renter-share field on the layer** — only counts (`RENTER_CY`, `OWNER_CY`, `RENTER_FY`, `OWNER_FY`), and `PCTRENTER` / `PCTRENT_CY` / `RENTER_CY_P` do not exist. A share map needs a `normalization_field` the tool does not accept. (b) The raw count map blanks out anyway, for the same outlier reason as Population (national max 6,042 households). |

Both restore automatically the day `custom_map_screenshot` can classify on the visible extent
(or accepts explicit break values); the tenure map additionally needs a normalization field to
show *share* rather than raw households. Nothing else in this file changes when they land.

### Graceful failure (applies to every map)

If a `custom_map_screenshot` call errors, leave that slot empty: for the hero, drop the whole `<img class="hero-map">` + its caption; for a section map, drop its whole `<figure class="secmap">` and the now-unused `sec--map` class from that `<section>`. (The table is full-width either way — `sec--map` no longer changes the table's geometry, it only marks the section as carrying a map. Dropping it is tidiness, not a reflow.) Never substitute a different map; never mention the omission. A section that can't render its map today simply shows its table, and the map reappears automatically the day the service renders it — no edit to this file.

### Custom maps on request

If the user names a data layer that is not in the registry ("add a flood risk map", "show me owner-occupancy", "map the unemployment rate"), add it as an extra map — this is the same tool, pointed at a different field:

1. `search_real_estate_data("<what they asked for>")` → pick the result whose `layerTitle` is **Block Group** (or the finest available), and take its `fieldName` + `layerUrl`.
2. `custom_map_screenshot(address, service_url=<layerUrl>, field_name=<fieldName>, field_alias=<the alias>, legend_title=<a finished caption>, colors=<a ramp suited to the meaning>, class_breaks_count=5, classification_method="equal-interval")`.
3. Place it under the section it belongs to, or in its own `.sec` if it belongs to none.

`search_maps` + `map_id` are only needed when the user asks for a *named webmap* rather than a data field.

## Computations

- **Delta chips.** A value cell carries a chip comparing it to its **left neighbor**, EXCEPT: the leftmost (Block) cell never has one, and these rows are always **plain** (no chips on any cell): **HHI 2029, HV 2029, Per capita income, Renter units, Owner units**. Every other non-Block cell gets a chip (skip it only if either value is null).
  - Currency/counts: absolute Δ + relative %, e.g. `−$12.6k · −11%` (abbreviate ≥$10k as `$Xk`, ≥1M as `$X.XM`; large counts as `+5.08M · 148×` using the ratio). For a percentage-point metric whose base is near zero, show just the `pp` delta (a relative % off a ~0 base is noise).
  - Percentage/rate metrics (growth, unemployment, renter share): `Δ pp · rel%`, e.g. `+1.12pp · +54%`.
  - Age: `+1.9 yr · +6%`.
  - Class: `p` (Δ>0), `n` (Δ<0), `z` (|rel|<1% or |Δ|<1pp). Sign only — never a value judgment.
- **Renter share** = `RENTER_CY / (RENTER_CY + OWNER_CY) × 100` per scale (needs both).
- **5-yr HV growth** = `((MEDVAL_FY / current-median-home-value)^(1/5) − 1) × 100` per scale, where *current-median-home-value* is the value already shown in the Median home value row (from `get_section_data` at block/tract/zip, `MEDVAL_CY` at `/7` for County). Needs both, both > 0.
- **Crime is an index, not a count.** The `CRMCY*` values are indexed to the U.S. average (100). Label the section "crime index, 100 = U.S. avg" and keep the note line. Never call them counts; never compute a per-capita rate. **Colour:** give a crime cell the `hi` class (red number) **only when its index exceeds 100**; at or below 100 use a plain `cell`. This keeps below-average crime from rendering alarm-red.

## Template — the self-contained page

Reproduce this exact structure and CSS, substituting the subject's real data. The values shown are an **illustration of the markup only** — replace every one with the subject's VestMap values (or drop it per the sweep rules). The comparison sections (Population, Income, Housing, Rental) all use the identical `table.cmp` markup shown; build each section's `<tbody>` from §Data, honoring the "Chips?" column. Keep the CSS byte-for-byte. Keep both `brk` page breaks (Housing, Safety). A full-width section map costs ~2in of column, so the OM lands as **four** pages: page 1 hero + context + Population, page 2 Income, page 3 Housing + Rental, page 4 Safety. Do not try to reclaim a page by shrinking `.secmap img` below 1.85in — that crops the property marker out of every map.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{{ADDRESS}}</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>
  :root{
    --ink:#1a1a1a; --muted:#6b6b6b; --faint:#9a9a97;
    --line:#e6e6e2; --surface:#ffffff; --surface-alt:#f7f7f4;
    --brand:#1e4635; --brand-2:#2c5f4e; --accent:#2c5f4e;
    --pos-bg:#e7efea; --pos-ink:#1e4d3e;
    --neg-bg:#f5e6e1; --neg-ink:#7a2d1f;
    --neu-bg:#eeeeea; --neu-ink:#7a7a76;
    --sans:"Inter","SF Pro Text",-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
  }
  @page{ size:Letter; margin:0; }
  *{ box-sizing:border-box; }
  html,body{ margin:0; padding:0; background:var(--surface); color:var(--ink);
    font-family:var(--sans); font-size:10.5pt; line-height:1.34;
    -webkit-font-smoothing:antialiased; font-variant-numeric:tabular-nums; }
  .page{ width:8.5in; }              /* full paper width; @page margin is 0 so the masthead can bleed to the edges */
  .wrap{ padding:0.22in 0.55in 0.5in; } /* body content sits inside consistent margins */
  .masthead{
    background:var(--brand); color:#fff; padding:0.5in 0.55in 0.34in; } /* full-bleed header (top/left/right) */
  .masthead h1{ margin:0; font-size:23pt; font-weight:650; letter-spacing:-0.015em; line-height:1.1; }
  .masthead .loc{ margin-top:0.07in; font-size:10pt; font-weight:400; color:#cdddd4; letter-spacing:0.01em; }
  .hero-map{ width:100%; height:1.5in; border-radius:7px; border:1px solid var(--line);
    overflow:hidden; background:var(--surface-alt); }
  .leaflet-container{ background:var(--surface-alt); }
  .hero-cap{ font-size:7.6pt; color:var(--faint); text-align:right; margin-top:3px; letter-spacing:0.03em; }
  .context{ display:grid; grid-template-columns:repeat(3,1fr); gap:0.16in; margin:0.16in 0 0.04in; }
  .callout{ background:var(--surface-alt); border:1px solid var(--line); border-radius:7px; padding:0.11in 0.14in; }
  .callout .lbl{ font-size:7.8pt; letter-spacing:0.06em; text-transform:uppercase; color:var(--muted); font-weight:600; }
  .callout .val{ font-size:20pt; font-weight:700; letter-spacing:-0.02em; margin-top:0.03in; line-height:1.05; }
  .sec{ margin-top:0.17in; break-inside:avoid; page-break-inside:avoid; }
  .sec.brk{ page-break-before:always; padding-top:0.5in; } /* top margin for the new page (since @page margin is 0) */
  .sec__head{ display:flex; align-items:baseline; justify-content:space-between;
    border-bottom:2px solid var(--brand); padding:0 2px 4px; margin-bottom:0.08in; }
  .sec__head h2{ margin:0; font-size:12.5pt; font-weight:650; letter-spacing:-0.01em; color:var(--brand); }
  .sec__head .scale{ font-size:7.8pt; letter-spacing:0.05em; text-transform:uppercase; color:var(--faint); font-weight:600; }
  /* The map goes FULL WIDTH beneath its table, never beside it. The map image carries a
     baked-in legend that is unreadable below ~3.4in of width, while the 4-scale table needs
     ~4.7in — they do not both fit across 7.4in of column. Full width gives both room. */
  .sec--map .sec__body{ display:block; }
  .sec__data{ min-width:0; }
  .secmap{ margin:0.13in 0 0; }
  /* Source is 1120x560 (2:1), legend TOP-right, property marker dead centre. Crop from the
     bottom only (object-position:center top) and never below 0.5x the width, or the marker
     is lost. 7.4in x 1.85in keeps both. */
  .secmap img{ width:100%; height:1.85in; object-fit:cover; object-position:center top;
    border-radius:6px; border:1px solid var(--line); display:block; }
  .secmap figcaption{ margin-top:3px; font-size:7.6pt; color:var(--faint); text-align:right; letter-spacing:0.03em; }
  table.cmp{ width:100%; border-collapse:collapse; table-layout:fixed; }
  table.cmp col.m{ width:22%; }
  .cmp th{ font-size:7.8pt; letter-spacing:0.05em; text-transform:uppercase; color:var(--muted);
    font-weight:600; text-align:right; padding:0 5px 5px; border-bottom:1px solid var(--line); }
  .cmp th:first-child{ text-align:left; padding-left:2px; }
  .cmp td{ padding:6px 5px 6px; vertical-align:top; text-align:right; border-bottom:1px solid var(--line); }
  .cmp tr:last-child td{ border-bottom:none; }
  .cmp td.m{ text-align:left; padding-left:2px; font-size:8.4pt; font-weight:500; color:var(--muted);
    text-transform:uppercase; letter-spacing:0.02em; }
  .v{ font-size:12pt; font-weight:640; letter-spacing:-0.01em; }
  .chip{ display:inline-block; margin-top:3px; padding:1.5px 5px; border-radius:20px;
    font-size:7.6pt; font-weight:600; white-space:nowrap; }
  .chip.p{ background:var(--pos-bg); color:var(--pos-ink); }
  .chip.n{ background:var(--neg-bg); color:var(--neg-ink); }
  .chip.z{ background:var(--neu-bg); color:var(--neu-ink); }
  .crime{ display:grid; grid-template-columns:repeat(3,1fr); gap:7px; }
  .crime .cell{ border:1px solid var(--line); border-radius:6px; padding:7px 9px; background:var(--surface); }
  .crime .cell .k{ font-size:7.6pt; text-transform:uppercase; letter-spacing:0.05em; color:var(--muted); font-weight:600; }
  .crime .cell .n{ font-size:14pt; font-weight:700; margin-top:1px; }
  .crime .cell.hi .n{ color:#a2432f; }
  .crime .note{ grid-column:1 / -1; font-size:7.8pt; color:var(--faint); margin-top:1px; }
  .foot{ margin-top:0.28in; padding-top:0.09in; border-top:1px solid var(--line); font-size:7.8pt; color:var(--faint); }
</style>
</head>
<body>
<section class="page">
  <div class="masthead">
    <h1>{{ADDRESS_LINE1}}</h1>
    <!-- Drop any segment (and its leading " · ") whose value is missing, e.g. no MSA. -->
    <div class="loc">{{CITY_STATE}} &nbsp;&middot;&nbsp; {{COUNTY}} &nbsp;&middot;&nbsp; ZIP {{ZIP}} &nbsp;&middot;&nbsp; {{MSA}} MSA</div>
  </div>

  <div class="wrap">

  <!-- HERO: clean aerial base map (Leaflet + ESRI World Imagery, marker only). Drop #hero + caption if geocoding failed. -->
  <div class="hero-map" id="hero"></div>
  <div class="hero-cap">Aerial view &middot; property location</div>

  <div class="context">
    <div class="callout"><div class="lbl">Median HHI &middot; ZIP</div><div class="val">{{HHI_ZIP}}</div></div>
    <div class="callout"><div class="lbl">Median Home Value &middot; ZIP</div><div class="val">{{HV_ZIP}}</div></div>
    <div class="callout"><div class="lbl">Pop Growth &middot; ZIP, 5-yr</div><div class="val">{{POPGR_ZIP}}</div></div>
  </div>

  <!-- POPULATION — no map: POPGRWCYFY renders blank (see §Maps). Table only, full width. -->
  <section class="sec">
    <div class="sec__head"><h2>Population</h2><span class="scale">Block &middot; Tract &middot; ZIP &middot; County</span></div>
    <div class="sec__body">
      <div class="sec__data">
        <table class="cmp"><colgroup><col class="m"/><col/><col/><col/><col/></colgroup>
          <thead><tr><th>Metric</th><th>Block</th><th>Tract</th><th>ZIP</th><th>County</th></tr></thead>
          <tbody>
            <tr>
              <td class="m">Total population</td>
              <td><div class="v">4,443</div></td>
              <td><div class="v">10,961</div><span class="chip p">+6,518 · 2.5×</span></td>
              <td><div class="v">34,511</div><span class="chip p">+23,550 · 3.1×</span></td>
              <td><div class="v">5,113,353</div><span class="chip p">+5.08M · 148×</span></td>
            </tr>
            <!-- …Median age, Avg HH size, 5-yr pop growth rows follow the same pattern (all chipped)… -->
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- INCOME (income map) -->
  <section class="sec sec--map">
    <div class="sec__head"><h2>Income</h2><span class="scale">Block &middot; Tract &middot; ZIP &middot; County</span></div>
    <div class="sec__body">
      <div class="sec__data">
        <table class="cmp"><colgroup><col class="m"/><col/><col/><col/><col/></colgroup>
          <thead><tr><th>Metric</th><th>Block</th><th>Tract</th><th>ZIP</th><th>County</th></tr></thead>
          <tbody>
            <tr>
              <td class="m">Median HHI</td>
              <td><div class="v">$123,992</div></td>
              <td><div class="v">$119,267</div><span class="chip n">−$4.7k · −4%</span></td>
              <td><div class="v">$119,949</div><span class="chip z">+$682 · +1%</span></td>
              <td><div class="v">$81,445</div><span class="chip n">−$38.5k · −32%</span></td>
            </tr>
            <!-- HHI 2029 (plain), 5-yr HHI growth (chips), Per capita income (plain), Unemployment (chips) rows follow -->
          </tbody>
        </table>
      </div>
      <figure class="secmap">
        <img src="{{INCOME_MAP_URL}}" alt="Median household income map" />
        <figcaption>Median household income by block group</figcaption>
      </figure>
    </div>
  </section>

  <!-- HOUSING (median home value map) — 'brk' forces the page break here -->
  <section class="sec sec--map brk">
    <div class="sec__head"><h2>Housing Values</h2><span class="scale">Block &middot; Tract &middot; ZIP &middot; County</span></div>
    <div class="sec__body">
      <div class="sec__data">
        <table class="cmp"><colgroup><col class="m"/><col/><col/><col/><col/></colgroup>
          <thead><tr><th>Metric</th><th>Block</th><th>Tract</th><th>ZIP</th><th>County</th></tr></thead>
          <tbody>
            <tr>
              <td class="m">Median home value</td>
              <td><div class="v">$545,752</div></td>
              <td><div class="v">$517,572</div><span class="chip n">−$28.2k · −5%</span></td>
              <td><div class="v">$460,318</div><span class="chip n">−$57.3k · −11%</span></td>
              <td><div class="v">$325,501</div><span class="chip n">−$134.8k · −29%</span></td>
            </tr>
            <!-- HV 2029 (plain), 5-yr HV growth (chips) rows follow -->
          </tbody>
        </table>
      </div>
      <figure class="secmap">
        <img src="{{HOUSING_MAP_URL}}" alt="Median home value map" />
        <figcaption>Median home value by block group</figcaption>
      </figure>
    </div>
  </section>

  <!-- RENTAL (median contract rent map — MEDCRNT_CY at Block Group) -->
  <section class="sec sec--map">
    <div class="sec__head"><h2>Rental Market</h2><span class="scale">Block &middot; Tract &middot; ZIP &middot; County</span></div>
    <div class="sec__body"><div class="sec__data">
      <table class="cmp"><colgroup><col class="m"/><col/><col/><col/><col/></colgroup>
        <thead><tr><th>Metric</th><th>Block</th><th>Tract</th><th>ZIP</th><th>County</th></tr></thead>
        <tbody>
          <!-- Median rent (chips), Renter units (plain), Owner units (plain), Renter share (chips) -->
        </tbody>
      </table>
      </div>
      <figure class="secmap">
        <img src="{{RENTAL_MAP_URL}}" alt="Median contract rent map" />
        <figcaption>Median contract rent by block group</figcaption>
      </figure>
    </div>
  </section>

  <!-- SAFETY (total crime index map; self-omits on failure). Give a cell 'hi' only when its index > 100. -->
  <section class="sec sec--map brk">
    <div class="sec__head"><h2>Safety</h2><span class="scale">Block Group &middot; crime index, 100 = U.S. avg</span></div>
    <div class="sec__body">
      <div class="sec__data">
        <div class="crime">
          <div class="cell hi"><div class="k">Total</div><div class="n">165</div></div>
          <div class="cell hi"><div class="k">Property</div><div class="n">177</div></div>
          <div class="cell hi"><div class="k">Personal</div><div class="n">101</div></div>
          <div class="cell"><div class="k">Murder</div><div class="n">50</div></div>
          <div class="cell"><div class="k">Rape</div><div class="n">79</div></div>
          <div class="cell hi"><div class="k">Robbery</div><div class="n">254</div></div>
          <div class="cell"><div class="k">Assault</div><div class="n">58</div></div>
          <div class="cell"><div class="k">Burglary</div><div class="n">48</div></div>
          <div class="cell hi"><div class="k">Larceny</div><div class="n">211</div></div>
          <div class="note">Indexed to the U.S. average (100). A value of 200 is twice the national rate.</div>
        </div>
      </div>
      <figure class="secmap">
        <img src="{{SAFETY_MAP_URL}}" alt="Total crime index map" />
        <figcaption>Total crime index by block group</figcaption>
      </figure>
    </div>
  </section>

  <div class="foot">Data: VestMap &middot; Generated {{DATE}}</div>
  </div><!-- .wrap -->
</section>

<script>
  // Hero aerial base map: ESRI World Imagery at the geocoded property, marker only.
  window.addEventListener('load', function(){
    var lat = parseFloat('{{LAT}}'), lng = parseFloat('{{LNG}}');
    var el = document.getElementById('hero');
    if (!el || isNaN(lat) || isNaN(lng)) {
      if (el) { var cap = el.nextElementSibling;
        if (cap && cap.className.indexOf('hero-cap') > -1) cap.parentNode.removeChild(cap);
        el.parentNode.removeChild(el); }
      return;
    }
    var map = L.map('hero', { zoomControl:false, attributionControl:false, dragging:false, scrollWheelZoom:false, keyboard:false });
    map.setView([lat, lng], 16);
    L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom:19 }).addTo(map);
    L.marker([lat, lng]).addTo(map);
  });
</script>
</body>
</html>
```

## PDF export

Write the filled HTML to `vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.html`, then (macOS; Chrome 150 won't self-exit, so the `perl` alarm stops it once the PDF is written — a non-empty PDF is success regardless of exit code):

```bash
perl -e 'alarm shift @ARGV; exec @ARGV' 40 \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --virtual-time-budget=28000 \
  --user-data-dir="$(mktemp -d)" \
  --print-to-pdf="vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf" \
  "file:///ABSOLUTE/PATH/vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.html"
```

`--virtual-time-budget=28000` gives the aerial hero tiles (Leaflet + ESRI) and the hosted section-map images time to fetch. Then delete the intermediate `.html`. If `/Applications/Google Chrome.app/...` is missing, output the HTML instead and tell the user once that the PDF needs Chrome (File → Print → Save as PDF preserves the maps).

## Respond

Print the PDF path and one sentence naming the address. Do not list sections, do not mention any missing data or dropped map, do not describe the layout.

## Opt-in modules (only when the user names them)

Rendered only on explicit request; otherwise absent. Same rules (VestMap-sourced, omit-on-null, no failure notes). Add each as an extra `.sec` (heavy modules on their own page via `brk`).

| Trigger | Module | Source |
|---|---|---|
| "workforce", "occupations" | Occupation mix / collar shares | the 13 `OCC*_CY` fields at each scale |
| "include risk", "FEMA", "hazards" | Natural-hazard risk (Tract) | `search_real_estate_data("National Risk Index")` → `RISK_SCORE`, `RISK_RATNG`, `SOVI_SCORE`, `RESL_SCORE`, top hazards by `_RISKS` |
| "include schools" | Nearest schools + district | `get_section_data(address, "schools")`; pair with a `custom_map_screenshot` on the schools layer resolved via `search_real_estate_data` |
| "education", "degree attainment" | 5-bucket education by scale | `NOHS_CY`, `HSGRAD_CY`, `SMCOLL_CY`, `BACHDEG_CY`, `GRADDEG_CY` |
| "income distribution", "HINC buckets" | 9-bucket income distribution | `HINC0_CY`…`HINC200_CY`, `TOTHH_CY` |
| "businesses", "MSA data" | Business counts (CBSA) | `N01_BUS`, `N01_EMP` on the CBSA layer |
| "HPI" (as data, not the map) | House Price Index | `get_section_data(address, "hpi")` |
