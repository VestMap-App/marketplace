---
name: vestmap-om-pages
description: Render a property Offering Memorandum (OM) page for any US address as a visual, page-oriented PDF (the default output). The default output is a single Demographics dashboard page in VestMap's live brand — narrative lede, three KPI cards, a block-group income choropleth with legend, forecast-growth bars, a block-profile ring trio, and a Block / Tract / ZIP / County / National summary table with above/below-block markers. Named variants: a map-centered layout, a light print theme, and a Rental Market page with a contract-rent map. Use when the user asks for an "OM", "one-pager", "investor page", "property page", "marketing page", or a rendered / laid-out visual for a US property. Self-contained — this file carries its own layout, HTML template, brand tokens, and PDF steps; it needs no other file.
user-invocable: true
---

# VestMap OM Pages

Generate a presentation-ready Offering Memorandum PDF for a single US address. The default output is **one Letter page**: the Demographics dashboard. All numbers come from VestMap MCP tool calls; the page carries a real VestMap choropleth. This file is **self-contained**: the layout, the full HTML/CSS template, the brand tokens, and the PDF command are all below — do not look for or depend on any `references/…` or `templates/…` file, and do not fetch anything over the network for page content beyond the VestMap map image, the vestmap.com logo lockups, and the Google-hosted webfonts the template links.

## Hard rules

- **PDF is the default output.** Write the HTML to a temp file, convert with headless Chrome (see §PDF), print the PDF path. Only output HTML instead if the user says "HTML" / "html only".
- **Every number traces to a VestMap tool call** (`get_section_data`, `query_gis_field`, `custom_map_screenshot`, `search_real_estate_data`) or to a computation in §Computations over those values. If you can't name the call that produced a value, it does not go on the page. No inference, no memory, no fabrication.
- **Missing data disappears — it is never announced.** Null value → drop that cell/segment. Summary-table row with fewer than 2 non-null value cells → drop the row. KPI card whose value is null → drop the card (the grid reflows to 2). Ring whose numerator or base is null → drop that ring. Panel left with nothing to show → drop the panel (see §Graceful failure for the map panel). The page never contains "N/A", "—", "data unavailable", tool names, field names, or any note about what was dropped. The chat reply after generation is equally quiet (see §Respond).
- **Different scales differ — that is normal, never a problem.** Block / Tract / ZIP / County / National cover different areas; report values as-is. Never reconcile or describe a cross-scale difference as an anomaly.
- **No Tapestry, ever.** Never call `get_section_data("demographics")` for numbers and never put a Tapestry segment/grade/lifestyle label on the page.
- **Numbers-only prose.** The lede and panel notes are formulaic sentences (patterns in §Computations) whose every figure is a tool value or documented computation. No "desirable", "up-and-coming", "affluent", "safe" — the only permitted qualifiers are numeric relations (×, pp, %, "against the 30% burden standard").
- **Market-agnostic.** A market name appears only in the address line, the county/ZIP/MSA labels, and panel notes' county name. Nothing city-specific is hardcoded.
- **No "Offering Memorandum" eyebrow.** The masthead is the page title ("Demographics" / "Rental Market"), the address, and the VestMap wordmark.
- **Brand tokens are locked to vestmap.com.** The CSS `:root` block below mirrors the live `colors_and_type.css` (forest-900 page `#11221E`, forest-700 panels `#1E3B34`, mint `#E6F1EB`, sage `#9EB39A`, success green `#2E8B65`, 12–16px radii). Type is **Inter** throughout — the page title is the site header's big-sans treatment (Inter 700, −0.025em), metrics are Inter 600 tabular — with **JetBrains Mono** for data labels. The masthead logo is the real lockup: `https://vestmap.com/assets/logo-vestmap-inverted.png` on dark, `…/logo-vestmap-forest.png` on the light variant — never draw a substitute mark. Never restyle per market or per user.
- **The page must stay one page.** The template's sizes and spacings are tuned so the full content lands exactly on 11in. Do not enlarge fonts, paddings, the lede (keep it ≤4 rendered lines), or the map aspect ratios; if content must grow, something else must shrink or be dropped.

## Workflow

1. **Parse** the subject address; note its ZIP.
2. **Acquire data — fire all of this in parallel in one turn** (VestMap is free and unlimited; never warn about volume):
   - `get_section_data(address, "income")` → `median_household_income` at block/tract/zip/county/national (also returns state; unused).
   - `get_section_data(address, "expansion")` → 5-yr population-growth CAGR at block/tract/zip/county/national.
   - `query_gis_field` batches (≤3 fields each) — the full battery in §Data, at the five scale layers.
   - `query_gis_field(address, <County /7>, ["NAME"])` → county name; `query_gis_field(address, <CBSA layer>, ["NAME"])` → MSA name (used in prose/labels only if needed; the county name feeds the growth note and table header).
   - **The section map** — one `custom_map_screenshot` call per placed map from the registry in §Maps (default page: Income only; Rental variant adds Rent).
3. **Compute** the derived values and formulaic sentences per §Computations. Precondition-gate every computation: if a component is null, skip it and its sentence fragment.
4. **Sweep** for empties per the hard rules.
5. **Fill the template** in §Template (variant deltas in §Variants).
6. **Convert to PDF** per §PDF. Output `vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf` in the current directory.
7. **Respond** minimally: the PDF path + one sentence naming the address.

## Data — what fills each element

Layers on `https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer`:

| Scale | Layer | Table header |
|---|---|---|
| Block (block group) | `/12` | `BLOCK` |
| Tract | `/11` | `TRACT` |
| ZIP | `/9` | `ZIP {zip}` |
| County | `/7` | `{COUNTY} CO.` (strip a trailing " County" from NAME, uppercase) |
| National (country layer) | `/13` | `NATIONAL` |

`query_gis_field` battery — run each batch at **all five layers** in parallel unless marked block-only:

| Batch | Fields | Feeds |
|---|---|---|
| Population | `TOTPOP_CY`, `MEDAGE_CY`, `AVGHHSZ_CY` | Median-age KPI + summary rows |
| Tenure | `TOTHH_CY`, `RENTER_CY`, `OWNER_CY` | Renter KPI, renter-share row, bases |
| Market | `MEDCRNT_CY`, `MEDVAL_CY`, `MEDHINC_CY` | Rent-to-income ring, Rental variant, cross-checks (`MEDHINC_CY` also backs the income section values) |
| Education (block `/12` only) | `NOHS_CY`, `HSGRAD_CY`, `SMCOLL_CY` + `BACHDEG_CY`, `GRADDEG_CY`, `EDUCBASECY` (2nd call; `ASSCDEG_CY` exists too but is not needed) | Bachelor's-or-higher ring |
| Occupation (block `/12` only, 4 calls of ≤3) | `OCCMGMT_CY`, `OCCBUS_CY`, `OCCCOMP_CY`, `OCCARCH_CY`, `OCCSSCI_CY`, `OCCSSRV_CY`, `OCCLEGL_CY`, `OCCEDUC_CY`, `OCCENT_CY`, `OCCHTCH_CY`, `OCCSALE_CY`, `OCCADMN_CY` + `EMP_CY` | White-collar ring |

Field facts (validated live):
- **`OCCPROF_CY` and `WHTCLR_CY` do not exist** on this service. White collar is the 12-field sum above — Esri's standard white-collar set (management, business/financial, computer/math, architecture/engineering, sciences, community/social service, legal, education, arts/entertainment/media, health practitioners/technical, sales, office/admin).
- **`MEDRENT_CY` does not exist** — `MEDCRNT_CY` (Median Contract Rent) is the canonical rent field.
- **`EDUCBASECY`** is the adults-25+ base; use it as the education denominator (the five buckets do not sum to it exactly).
- `/13` is the **country layer** — same field names, national values (e.g. `TOTPOP_CY` ≈ 338M). It backs every `NATIONAL` column cell and the KPI-card national references.
- **`query_gis_field` skips fields that are missing and names them** ("Skipped N field(s) not present…") while returning the rest; a call whose *every* field is missing errors instead. Keep batches ≤3 fields. If a whole batch errors unexpectedly, re-probe its fields one per call (parallel) and drop only the nulls — never surface the failure.

Element → source map (Demographics page):

| Element | Values |
|---|---|
| Masthead | Title "Demographics"; address line; the VestMap logo lockup (template) |
| Lede | Formula in §Computations, from: renter share, median age, bachelor's+, white collar, block HHI, block rent, rent-to-income, block growth, national growth |
| KPI 1 | Block `median_household_income`; sub: "{round(block/national×100)}% of the ${national} national median." |
| KPI 2 | Block `MEDAGE_CY`; sub: "{national − block, 1dp} years under the national {national}." (flip to "over" if block is higher) |
| KPI 3 (mint pop card) | Block renter share; sub: "{RENTER_CY} of {TOTHH_CY} households. Nationally {national share}%." |
| Map panel | Income map (§Maps) + the 10-row HTML legend + mini-row: Block / Tract / ZIP `median_household_income` with `TOTHH_CY` counts, Block cell marked active |
| Growth panel | Expansion CAGR at the five scales as bars (block bar green, others sage; widths ∝ value/max, min 2.5% — a negative value simply renders at the minimum width with its signed label); note: "Growth tightens as the geography shrinks: the block runs **{block/national}×** the national rate and **{block/county}×** {County Name}." (ratios 1dp, drop a ratio if its denominator ≤ 0). **If block growth ≤ 0 the ratio sentence is invalid** — use the plain-difference form instead: "Growth is negative at every local scale: the block runs **−X.XX%** a year against **+Y.YY%** nationally." (adjust "at every local scale" to name just the negative scales when they are mixed). Print negative values with a true minus sign. |
| Profile panel | Rings: white collar %, bachelor's+ %, rent-to-income % (§Computations); bases line: "Bases: {EMP_CY} employed · {EDUCBASECY} adults 25+ · {TOTHH_CY} occupied households." |
| Summary table | Rows: Median household income · Median age · Average household size · Renter-occupied share · Forecast growth (CAGR) — five scale columns, ▲/▼ vs Block on every non-Block cell (§Computations) |
| Footer | "Data: VestMap · Generated {YYYY-MM-DD}" + page number |

## Computations

- **Renter share** = `RENTER_CY / (RENTER_CY + OWNER_CY) × 100` per scale (needs both), 1dp.
- **Bachelor's or higher** = `(BACHDEG_CY + GRADDEG_CY) / EDUCBASECY × 100`, 1dp.
- **White collar** = (sum of the 12 occupation fields) `/ EMP_CY × 100`, 1dp.
- **Rent-to-income** = `MEDCRNT_CY × 12 / median_household_income × 100` per scale, 1dp. If the user supplies the property's own asking rent ("ask is $X", "asking rent $X"), the ring uses `X × 12 / block HHI` instead and its label becomes `ASK RENT TO INCOME`; the summary-table row stays on `MEDCRNT_CY`.
- **Burden coloring**: the rent-to-income ring arc is green below 30% and clay at ≥ 30%; its caption always carries the clay line "30% burden line". Sign only — never add words.
- **▲/▼ markers**: every non-Block cell gets ▲ (green) if its value > Block, ▼ (clay) if < Block, nothing if equal. Direction only — never a value judgment. Key line above the table: "▲ ABOVE BLOCK ▼ BELOW BLOCK".
- **KPI subtexts** and the **growth note** use the exact sentence patterns in the table above; round ratios and years to 1dp, share-of-national to whole %.
- **Lede pattern** (omit any fragment whose inputs are null, keep it ≤4 rendered lines):
  "The block group around **{street address}** is **{renter share}% renter** at a median age of **{age}**, with **{bach}%** holding a bachelor's degree or higher and **{wc}%** working white-collar jobs. Median household income of **${HHI}** puts the **${rent}** median contract rent at **{rti}%** of gross against the 30% burden standard, while the block group grows **{growth}%** a year — {growth/national}× the {national}% national rate."
- **Formatting**: currency `$X,XXX` (no decimals); percentages 1dp except CAGR 2dp; counts with thousands separators; `font-variant-numeric: tabular-nums` is already set globally.

## Maps — one VestMap choropleth per page

Built with **`custom_map_screenshot`** (the arbitrary-field renderer), never `map_screenshot`. It bakes a legend with the actual class breaks into the top-right of a 1120×560 image, with the property pin dead centre.

### Registry

| Page | `service_url` | `field_name` | `field_alias` / `legend_title` | Slot |
|---|---|---|---|---|
| Demographics (default) | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDHINC_CY` | `2024 Median Household Income` / `Median household income` | `{{INCOME_MAP_URL}}` |
| Rental Market (variant) | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDCRNT_CY` | `2024 Median Contract Rent` / `Median contract rent` | `{{RENT_MAP_URL}}` |

Every call passes exactly:

```
classification_method: "equal-interval"
class_breaks_count:    10
colors: ["#d73027","#f46d43","#fdae61","#fee08b","#ffffbf",
         "#d9ef8b","#a6d96a","#66bd63","#1a9850","#006837"]
address: <the subject address>
```

The 10-step red→green ramp (low→high) is the VestMap app's data-map signature — keep it for both fields. `map_id` is unnecessary (the plain-basemap fallback is correct). `"quantile"` is forbidden — null-polluted samples collapse its breaks.

### The HTML legend (breaks are national and deterministic)

Class breaks come from the field's national min/max, so they are identical in every market. Render the legend as HTML swatches beside these exact labels (verified against the baked legend):

| | Income (`MEDHINC_CY`) | Rent (`MEDCRNT_CY`) |
|---|---|---|
| swatch order top→bottom | `#006837 #1a9850 #66bd63 #a6d96a #d9ef8b #ffffbf #fee08b #fdae61 #f46d43 #d73027` | same |
| labels top→bottom | `180,001 – 200,001` · `160,001 – 180,001` · `140,001 – 160,001` · `120,001 – 140,001` · `100,001 – 120,001` · `80,000 – 100,001` · `60,000 – 80,000` · `40,000 – 60,000` · `20,000 – 40,000` · `0 – 20,000` | `3,150 – 3,500` · `2,800 – 3,150` · `2,450 – 2,800` · `2,100 – 2,450` · `1,750 – 2,100` · `1,400 – 1,750` · `1,050 – 1,400` · `700 – 1,050` · `350 – 700` · `0 – 350` |

Lay the ten items in two 5-row columns: left column = the five green (high) classes, right = the five warm (low) classes. If the service ever returns a different baked legend, re-transcribe these labels from the returned image before publishing the page.

### Crop geometry (why the CSS values are what they are)

- **Default panel slot** (`.mapimg`, aspect `1.04/1`, `object-fit:cover; object-position:center`): a centre crop of a 1120×560 image at aspect ≤ 1.05 shows the middle ~52% of the width — the baked top-right legend (starts ≈ x 858) falls outside the visible band and the centre pin stays centred. That is what lets the panel carry the clean HTML legend below instead. Never widen this aspect beyond 1.05 — the baked legend edge enters the frame.
- **Map Center slot** (`.mapimg.wide`, aspect `2.35/1`, `object-position:center top`): full width, cropped only from the bottom, so the baked legend stays visible (it is the legend for that layout) and the pin (y-centre) survives. Never crop a wide slot from the top.

### Transient errors are NOT failures — retry once before omitting

- **Transport / gateway error** — not valid JSON: `Unexpected token '<', "<html>…"`, a timeout, a 502/503. **Retry the call once with identical arguments.** Only omit if the retry also fails.
- **Data error** — a well-formed message naming a field, layer, or address. Retrying will not help; omit immediately.

Never diagnose a transport error as a registry problem, and never let a free-text `data_query` substitute for the registry call — free-text resolution can land on coarser geographies or the dead 2022 service (`Service USA_Demographics_and_Boundaries_2022/MapServer not started` can only come from a non-registry call).

### Graceful failure

If the page's map call fails after the retry: drop the entire map panel (image, HTML legend, and mini-row), and render the growth + profile panels as a two-column row in its place (the same `.grid` markup with `grid-template-columns:1fr 1fr` and the two panels as its children), keeping the rest of the page unchanged. Never substitute a different map; never mention the omission.

### Wired but omitted: home value

`MEDVAL_CY` renders with the same registry pattern, but the national $0–2,000,001 equal-interval breaks compress low-cost metros into one or two bottom classes (verified: Kansas City renders near-uniform red). Offer it only if the user asks for a home-value map, and note nothing on the page either way. It becomes useful the day `custom_map_screenshot` classifies on the visible extent.

### Custom maps on request

If the user names another data layer ("flood risk", "owner-occupancy", "unemployment"): `search_real_estate_data("<ask>")` → pick the **Block Group** (or finest) result → `custom_map_screenshot` with that `layerUrl`/`fieldName`, `class_breaks_count: 10`, `equal-interval`, a ramp suited to the meaning (red ramps only for risk), and a finished `legend_title`. Render it as an extra page in this dashboard language (pattern the page on the Rental variant), with its HTML legend transcribed from the returned image's baked legend.

## Template — the self-contained page

Reproduce this structure and CSS **byte-for-byte**, substituting the subject's real values (or dropping per the sweep rules). Values shown are markup illustration only. The `<style>` block is the locked brand layer.

```html
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>{{ADDRESS}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<style>
@page{ size:Letter; margin:0; }
*{ box-sizing:border-box; margin:0; padding:0; }
/* VestMap live tokens — vestmap.com/colors_and_type.css */
:root{
  --bg:#11221E;            /* forest-900 */
  --panel:#1E3B34;         /* forest-700 */
  --line:rgba(255,255,255,.14);
  --hair:rgba(255,255,255,.10);
  --ink:#E6F1EB;           /* mint-100 */
  --muted:rgba(255,255,255,.66);
  --faint:rgba(255,255,255,.45);
  --green:#2E8B65;         /* success-500 */
  --sage:#9EB39A;          /* sage-400 */
  --mint:#E6F1EB;
  --clay:#C97A6E;          /* dv-div-neg-1 (legible on dark) */
  --cardpop-bg:#E6F1EB; --cardpop-ink:#11221E; --cardpop-sub:#274F45;
  --font-body:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;
  --font-mono:'JetBrains Mono',ui-monospace,'SF Mono',Menlo,Consolas,monospace;
}
body.light{
  --bg:#F3F5F4;            /* stone-100 */
  --panel:#FFFFFF;
  --line:rgba(15,23,32,.14);
  --hair:rgba(15,23,32,.08);
  --ink:#0F1720;           /* slate-900 */
  --muted:#2A333D;         /* slate-700 */
  --faint:#5A6470;         /* slate-500 */
  --green:#1F6B4E;         /* success-700 */
  --sage:#5A6470;
  --mint:#1E3B34;
  --clay:#B23A2E;          /* danger-500 */
  --cardpop-bg:#1E3B34; --cardpop-ink:#E6F1EB; --cardpop-sub:#9EB39A;
}
html,body{ background:var(--bg); color:var(--ink);
  font-family:var(--font-body); font-size:10pt; line-height:1.35;
  -webkit-font-smoothing:antialiased; font-variant-numeric:tabular-nums; }
.page{ width:8.5in; height:11in; padding:0.40in 0.5in 0.34in; position:relative;
  display:flex; flex-direction:column; background:var(--bg); overflow:hidden; }
.mono{ font-family:var(--font-mono); }
.hd{ display:flex; justify-content:space-between; align-items:flex-start; }
.hd h1{ font-weight:700; font-size:24.5pt;
  letter-spacing:-0.025em; line-height:1.04; color:var(--ink); }
.hd .addr{ margin-top:7px; font-family:var(--font-mono); font-weight:500; font-size:8pt;
  letter-spacing:0.08em; text-transform:uppercase; color:var(--sage); }
.wm{ display:flex; align-items:center; padding-top:6px; }
.wm img{ height:0.23in; width:auto; display:block; }
.wm .lg-forest{ display:none; }
body.light .wm .lg-inverted{ display:none; }
body.light .wm .lg-forest{ display:block; }
.rule{ border:none; border-top:1px solid var(--line); margin:0.10in 0 0.10in; }
.lede{ font-size:9.3pt; line-height:1.5; color:var(--muted); max-width:7.5in; }
.lede b{ color:var(--ink); font-weight:600; }
.kpis{ display:grid; grid-template-columns:repeat(3,1fr); gap:0.12in; margin-top:0.11in; }
.kpi{ position:relative; background:var(--panel); border:1px solid var(--line);
  border-radius:12px; padding:0.10in 0.13in 0.11in; }
.kpi .lbl{ font-size:6.8pt; font-weight:600; letter-spacing:0.14em;
  text-transform:uppercase; color:var(--sage); }
.kpi .val{ font-weight:600; font-size:19.5pt; letter-spacing:-0.02em;
  line-height:1.08; margin-top:5px; color:var(--ink); font-variant-numeric:tabular-nums; }
.kpi .sub{ font-size:7.6pt; color:var(--faint); margin-top:4px; }
.kpi.pop{ background:var(--cardpop-bg); border-color:var(--cardpop-bg); }
.kpi.pop .lbl{ color:var(--cardpop-sub); }
.kpi.pop .val{ color:var(--cardpop-ink); }
.kpi.pop .sub{ color:var(--cardpop-sub); }
.grid{ display:grid; grid-template-columns:51.5% 1fr; gap:0.12in; margin-top:0.10in; flex:1; min-height:0; }
.panel{ position:relative; background:var(--panel); border:1px solid var(--line);
  border-radius:16px; padding:0.12in 0.14in; }
.phead{ display:flex; justify-content:space-between; align-items:baseline; margin-bottom:0.07in; }
.phead .t{ font-size:7.6pt; font-weight:600; letter-spacing:0.14em; text-transform:uppercase; color:var(--ink); }
.phead .r{ font-size:6.6pt; font-weight:600; letter-spacing:0.14em; text-transform:uppercase; color:var(--faint); }
.rcol{ display:flex; flex-direction:column; gap:0.12in; min-height:0; }
.mapimg{ width:100%; aspect-ratio:1.04/1; object-fit:cover; object-position:center; display:block;
  border-radius:8px; border:1px solid var(--hair); }
.mapimg.wide{ aspect-ratio:2.35/1; object-position:center top; }
.leg{ display:grid; grid-template-columns:1fr 1fr; gap:1px 0.16in; margin-top:0.07in; }
.leg .li{ display:flex; align-items:center; gap:6px; font-family:var(--font-mono); font-size:6.5pt; color:var(--muted); }
.leg .sw{ width:14px; height:7px; flex:none; border-radius:2px; border:1px solid rgba(0,0,0,0.25); }
.miniscale{ display:grid; grid-template-columns:repeat(3,1fr); gap:0.1in; margin-top:0.07in;
  border-top:1px solid var(--hair); padding-top:0.06in; }
.ms .k{ font-family:var(--font-mono); font-weight:500; font-size:6.4pt; letter-spacing:0.08em; color:var(--faint);
  text-transform:uppercase; padding-bottom:3px; }
.ms.on .k{ color:var(--sage); border-bottom:2px solid var(--green); }
.ms .v{ font-weight:600; font-size:11pt; letter-spacing:-0.02em; margin-top:3px; color:var(--ink);
  font-variant-numeric:tabular-nums; }
.ms .h{ font-size:6.9pt; color:var(--faint); margin-top:1px; }
.bars .brow{ display:grid; grid-template-columns:0.92in 1fr 0.62in; align-items:center; gap:8px; margin:6px 0; }
.bars .bk{ font-family:var(--font-mono); font-weight:500; font-size:6.6pt; letter-spacing:0.06em; color:var(--muted); }
.bars .bt{ height:9px; border-radius:4px; background:var(--hair); position:relative; overflow:hidden; }
.bars .bf{ position:absolute; inset:0 auto 0 0; border-radius:4px; background:var(--sage); }
.bars .brow.first .bf{ background:var(--green); }
.bars .bv{ font-weight:600; font-size:8.6pt; text-align:right; color:var(--ink); font-variant-numeric:tabular-nums; }
.pnote{ font-size:7.4pt; color:var(--faint); line-height:1.45; margin-top:0.08in;
  border-top:1px solid var(--hair); padding-top:0.07in; }
.donuts{ display:grid; grid-template-columns:repeat(3,1fr); gap:0.08in; }
.fillpanel{ display:flex; flex-direction:column; }
.fillpanel .donuts{ margin:auto 0; }
.dn{ text-align:center; }
.dn .dv{ font-weight:600; font-size:13pt; letter-spacing:-0.02em; color:var(--ink);
  margin-top:2px; font-variant-numeric:tabular-nums; }
.dn .dk{ font-family:var(--font-mono); font-weight:500; font-size:6.1pt; letter-spacing:0.07em;
  text-transform:uppercase; color:var(--faint); margin-top:3px; line-height:1.5; }
.dn .dk .warn{ color:var(--clay); }
.sumwrap{ margin-top:0.10in; position:relative; background:var(--panel); border:1px solid var(--line);
  border-radius:16px; padding:0.11in 0.14in 0.08in; }
.sumhead{ display:flex; justify-content:space-between; align-items:baseline; margin-bottom:0.06in; }
.sumhead .t{ font-size:7.6pt; font-weight:600; letter-spacing:0.14em; text-transform:uppercase; color:var(--ink); }
.keys{ font-family:var(--font-mono); font-size:6.2pt; letter-spacing:0.06em; color:var(--faint); }
.keys .up{ color:var(--green); } .keys .dn2{ color:var(--clay); }
table.sum{ width:100%; border-collapse:collapse; }
.sum th{ font-size:6.6pt; letter-spacing:0.12em; text-transform:uppercase; color:var(--sage);
  font-weight:600; text-align:right; padding:4px 6px 4px; border-bottom:1px solid var(--line); }
.sum th:first-child{ text-align:left; padding-left:2px; }
.sum th.blk{ color:var(--ink); }
.sum td{ padding:4.5px 6px; text-align:right; font-size:9.3pt; border-bottom:1px solid var(--hair);
  color:var(--muted); font-variant-numeric:tabular-nums; }
.sum tr:last-child td{ border-bottom:none; }
.sum td.m{ text-align:left; padding-left:2px; font-size:8.2pt; color:var(--muted); }
.sum td.blk{ color:var(--ink); font-weight:600; }
.sum .a{ font-size:7pt; } .sum .a.up{ color:var(--green); } .sum .a.dn2{ color:var(--clay); }
.ft{ display:flex; justify-content:space-between; margin-top:0.09in;
  font-family:var(--font-mono); font-weight:500; font-size:6.6pt; letter-spacing:0.06em;
  text-transform:uppercase; color:var(--faint); }
</style></head>
<body><!-- add class="light" for the Light Print variant -->
<div class="page">
  <div class="hd">
    <div><h1>Demographics</h1>
      <div class="addr">{{ADDRESS_LINE — street, city, state}}</div></div>
    <div class="wm">
      <img class="lg-inverted" src="https://vestmap.com/assets/logo-vestmap-inverted.png" alt="VestMap"/>
      <img class="lg-forest" src="https://vestmap.com/assets/logo-vestmap-forest.png" alt="VestMap"/>
    </div>
  </div>
  <hr class="rule"/>

  <div class="lede">{{LEDE — the pattern in §Computations, figures in <b>}}</div>

  <div class="kpis">
    <div class="kpi"><div class="lbl">Median HH Income &middot; Block</div>
      <div class="val">$56,085</div><div class="sub">71% of the $79,068 national median.</div></div>
    <div class="kpi"><div class="lbl">Median Age &middot; Block</div>
      <div class="val">29.4</div><div class="sub">9.9 years under the national 39.3.</div></div>
    <div class="kpi pop"><div class="lbl">Renter Households &middot; Block</div>
      <div class="val">78.3%</div><div class="sub">396 of 506 households. Nationally 35.6%.</div></div>
  </div>

  <div class="grid">
    <div class="panel">
      <div class="phead"><span class="t">Household Income in Geographic Area</span><span class="r">VestMap</span></div>
      <img class="mapimg" src="{{INCOME_MAP_URL}}" alt="Median household income by block group"/>
      <div class="leg">
        <!-- ten .li items, two columns: interleave left-column (greens, high) and
             right-column (warm, low) items in DOM order; swatches + labels from §Maps -->
        <div class="li"><span class="sw" style="background:#006837"></span>180,001 &ndash; 200,001</div>
        <div class="li"><span class="sw" style="background:#ffffbf"></span>80,000 &ndash; 100,001</div>
        <!-- … 8 more … -->
      </div>
      <div class="miniscale">
        <div class="ms on"><div class="k">Block</div><div class="v">$56,085</div><div class="h">506 households</div></div>
        <div class="ms"><div class="k">Tract</div><div class="v">$50,443</div><div class="h">962 households</div></div>
        <div class="ms"><div class="k">ZIP 64111</div><div class="v">$59,070</div><div class="h">11,077 households</div></div>
      </div>
    </div>
    <div class="rcol">
      <div class="panel">
        <div class="phead"><span class="t">Forecast Growth</span><span class="r">CAGR</span></div>
        <div class="bars">
          <!-- five .brow rows: BLOCK (class "brow first") · TRACT · ZIP {zip} · {COUNTY} CO. · NATIONAL
               .bf width = value/max×100 (min 2.5%), .bv = value 2dp + % -->
          <div class="brow first"><span class="bk">BLOCK</span>
            <span class="bt"><span class="bf" style="width:100.0%"></span></span>
            <span class="bv">4.47%</span></div>
          <!-- … -->
        </div>
        <div class="pnote">Growth tightens as the geography shrinks: the block runs <b>11.8&times;</b> the
        national rate and <b>37&times;</b> Jackson County.</div>
      </div>
      <div class="panel fillpanel" style="flex:1">
        <div class="phead"><span class="t">Block Profile</span><span class="r">Share of block group</span></div>
        <div class="donuts">
          <!-- ring svg: r=26, C=163.4; arc dasharray = pct/100×163.4;
               arc stroke = var(--green), or var(--clay) for rent-to-income ≥ 30% -->
          <div class="dn">
            <svg width="66" height="66" viewBox="0 0 74 74">
              <circle cx="37" cy="37" r="26" fill="none" stroke="var(--hair)" stroke-width="7"/>
              <circle cx="37" cy="37" r="26" fill="none" stroke="var(--green)" stroke-width="7"
                stroke-dasharray="121.5 163.4" transform="rotate(-90 37 37)"/>
              <g stroke="var(--sage)" stroke-width="1.5" fill="none">
                <rect x="26" y="31" width="22" height="15" rx="2"/>
                <path d="M32 31v-3a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v3M26 38h22"/></g>
            </svg>
            <div class="dv">74.4%</div><div class="dk">White Collar</div></div>
          <!-- ring 2: grad-cap icon, "Bachelor's or<br/>Higher" -->
          <!-- ring 3: house icon, "Rent to Income<br/><span class="warn">30% burden line</span>" -->
        </div>
        <div class="pnote">Bases: 774 employed &middot; 590 adults 25+ &middot; 506 occupied households.</div>
      </div>
    </div>
  </div>

  <div class="sumwrap">
    <div class="sumhead"><span class="t">Summary by Geographic Scale</span>
      <span class="keys"><span class="up">&#9650;</span> ABOVE BLOCK &nbsp;&nbsp;<span class="dn2">&#9660;</span> BELOW BLOCK</span></div>
    <table class="sum">
      <thead><tr><th>Metric</th><th class="blk">BLOCK</th><th>TRACT</th><th>ZIP 64111</th><th>JACKSON CO.</th><th>NATIONAL</th></tr></thead>
      <tbody>
        <tr><td class="m">Median household income</td><td class="blk">$56,085</td>
          <td>$50,443 <span class="a dn2">&#9660;</span></td><td>$59,070 <span class="a up">&#9650;</span></td>
          <td>$64,942 <span class="a up">&#9650;</span></td><td>$79,068 <span class="a up">&#9650;</span></td></tr>
        <!-- Median age · Average household size · Renter-occupied share · Forecast growth (CAGR) rows follow the same pattern -->
      </tbody>
    </table>
  </div>

  <div class="ft"><span>Data: VestMap &middot; Generated {{DATE}}</span><span>01</span></div>
</div></body></html>
```

## Variants (only when the user names them)

| Trigger | Variant | Delta from the default template |
|---|---|---|
| "map at the center", "map first", "map-centered" | **Map Center** | Drop the lede. Order: `.kpis` → a full-width `.panel` holding `<img class="mapimg wide" …>` under phead "Household Income in Geographic Area" / "VestMap · Block Group" (no HTML legend, no mini-row — the wide crop keeps the baked legend) → a `.grid` with `style="grid-template-columns:1fr 1fr"` holding the Growth and Profile panels → `.sumwrap` → footer. |
| "light", "print", "light theme" | **Light Print** | `<body class="light">`. Nothing else changes. |
| "rental page", "rental market page", "add the rental page" | **Rental Market page** | Same skeleton, retitled "Rental Market". KPIs: Median Contract Rent · Block (sub "{block/national}% of the ${national} national median."), Renter Households (the mint pop card, same as default), Rent to Income (sub "Against the 30% burden standard."). Map panel: phead "Contract Rent in Geographic Area", `{{RENT_MAP_URL}}`, the rent legend from §Maps, mini-row = Block/Tract/ZIP `MEDCRNT_CY` with "{RENTER_CY} renter HH" subtexts. Right column: "Renter Share by Scale" bars (renter share ×5 scales, 1dp) with note "Tenure flips with scale: the block group runs {block/national}× the national renter share{; {County Name} is majority owner if county share < 50%}." and a "Rental Profile" ring trio: renter share · rent-to-income (burden coloring) · ZIP renter share, bases line "Bases: {TOTHH block} occupied households on the block · {RENTER_CY zip} renter households in ZIP {zip}." Summary table rows: Median contract rent · Renter-occupied share · Rent to income · Median household income · Forecast growth (CAGR). Output as its own page ("02" footer) after the default page, or standalone if asked alone. |
| "ask(ing) rent $X" | Ask override | Rent-to-income ring per §Computations. |
| any other data/module ask | Custom | Extra summary-table rows for tabular asks; an extra dashboard page (Rental-variant pattern) plus a §Custom-maps map for mappable asks. |

## PDF export

Write the filled HTML to `vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.html`, then (macOS; Chrome won't self-exit, so the `perl` alarm stops it once the PDF is written — a non-empty PDF is success regardless of exit code):

```bash
perl -e 'alarm shift @ARGV; exec @ARGV' 40 \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --virtual-time-budget=20000 \
  --user-data-dir="$(mktemp -d)" \
  --print-to-pdf="vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf" \
  "file:///ABSOLUTE/PATH/vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.html"
```

`--virtual-time-budget=20000` covers the hosted map image and the Google webfonts (the page has no JavaScript). Then delete the intermediate `.html`. If Chrome is missing, output the HTML instead and tell the user once that the PDF needs Chrome (File → Print → Save as PDF preserves the page).

## Respond

Print the PDF path and one sentence naming the address. Do not list sections, do not mention any missing data or dropped panel, do not describe the layout.
