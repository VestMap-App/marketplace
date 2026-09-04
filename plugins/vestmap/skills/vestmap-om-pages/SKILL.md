---
name: vestmap-om-pages
description: Render a property Offering Memorandum (OM) page for any US address as a visual, page-oriented PDF (the default output). The default output is a single Demographics dashboard page in VestMap's live brand — the address as the page title, a narrative lede, three KPI cards, a five-class block-group income choropleth with a legend, population-growth bars, an Occupation Profile (white-collar / blue-collar / service rings with unemployment at Block, Tract and ZIP), and a Cross-Scale Summary table with per-cell deltas against the block. Named variants: a map-centered layout, a light print theme, and a Rental Market page with a contract-rent map. Use when the user asks for an "OM", "one-pager", "investor page", "property page", "marketing page", or a rendered / laid-out visual for a US property. Self-contained — this file carries its own layout, HTML template, brand tokens, and PDF steps; it needs no other file.
user-invocable: true
---

# VestMap OM Pages

Generate a presentation-ready Offering Memorandum PDF for a single US address. The default output is **one Letter page**: the Demographics dashboard. All numbers come from VestMap MCP tool calls; the page carries a real VestMap choropleth. This file is **self-contained**: the layout, the full HTML/CSS template, the brand tokens, and the PDF command are all below — do not look for or depend on any `references/…` or `templates/…` file, and do not fetch anything over the network for page content beyond the VestMap map image, the vestmap.com logo lockup, and the Google-hosted webfonts the template links.

## Hard rules

- **PDF is the default output.** Write the HTML to a temp file, convert with headless Chrome (see §PDF), print the PDF path. Only output HTML instead if the user says "HTML" / "html only".
- **Every number traces to a VestMap tool call** (`get_section_data`, `query_gis_field`, `custom_map_screenshot`, `search_real_estate_data`) or to a computation in §Computations over those values. If you can't name the call that produced a value, it does not go on the page. No inference, no memory, no fabrication.
- **Missing data disappears — it is never announced.** Null value → drop that cell/segment. Summary-table row with fewer than 2 non-null value cells → drop the row. KPI card whose value is null → drop the card (the grid reflows to 2). Ring whose numerator or base is null → drop that ring. Occupation section (Block / Tract / ZIP) with no rings → drop the section. Panel left with nothing to show → drop the panel (see §Graceful failure for the map panel). The page never contains "N/A", "—" as a placeholder, "data unavailable", tool names, field names, or any note about what was dropped. The chat reply after generation is equally quiet (see §Respond).
- **Different scales differ — that is normal, never a problem.** Block / Tract / ZIP / County / National cover different areas; report values as-is. Never reconcile or describe a cross-scale difference as an anomaly.
- **No Tapestry, ever.** Never call `get_section_data("demographics")` for numbers and never put a Tapestry segment/grade/lifestyle label on the page.
- **Numbers-only prose.** The lede and panel lines are formulaic sentences (patterns in §Computations) whose every figure is a tool value or documented computation. No "desirable", "up-and-coming", "affluent", "safe" — the only permitted qualifiers are numeric relations (×, pt, %, "the 30% of gross income rent burden standard") and the fixed comparator phrases in §Computations.
- **Market-agnostic.** A market name appears only in the masthead (address, city/state, county), the county/ZIP column labels, and the growth-bar labels. Nothing city-specific is hardcoded.
- **The masthead is eyebrow → address → context line.** Eyebrow = the page title in small caps ("DEMOGRAPHICS" / "RENTAL MARKET"); the H1 is the **full subject address**; the context line is "{City}, {ST} · {County Name} · ZIP {zip}". No "Offering Memorandum" eyebrow, ever. The VestMap lockup sits top-right with the tagline "REAL ESTATE INTELLIGENCE" beneath it.
- **Brand tokens are locked to vestmap.com.** The CSS `:root` block below mirrors the live `colors_and_type.css` (forest-900 page `#11221E`, forest-700 panels `#1E3B34`, mint `#E6F1EB`, sage `#9EB39A`, success green `#2E8B65`, 12–16px radii). Type is **Inter** throughout — the H1 is the site header's big-sans treatment (Inter 700, −0.025em), KPI values are Inter 700 — with **JetBrains Mono** for every figure inside a panel or table (ring percentages, bar values, table cells). The masthead logo is the real lockup: `https://vestmap.com/assets/logo-vestmap-inverted.png` on dark, `…/logo-vestmap-forest.png` on the light variant — never draw a substitute mark. Never restyle per market or per user.
- **The page must stay one page.** The template's sizes and spacings are tuned so the full content lands on 11in with `@page{margin:0}` — the dark page is full-bleed; never let Chrome add its default white margins. Do not enlarge fonts, paddings, the lede (keep it ≤4 rendered lines), or the map aspect ratio; if content must grow, something else must shrink or be dropped.

## Workflow

1. **Parse** the subject address; note its street line (for the lede), city, state and ZIP.
2. **Acquire data — fire all of this in parallel in one turn** (VestMap is free and unlimited; never warn about volume):
   - `get_section_data(address, "income")` → `median_household_income` at block/tract/zip/county/national.
   - `get_section_data(address, "expansion")` → 5-yr population-growth CAGR at block/tract/zip/county/national.
   - `query_gis_field` batches (≤3 fields each) — the full battery in §Data, at the layers each batch names.
   - `query_gis_field(address, <County /7>, ["NAME"])` → county name (context line, county column header, county growth bar).
   - **The section map** — one `custom_map_screenshot` call per placed map from the registry in §Maps (default page: Income only; Rental variant adds Rent).
3. **Compute** the derived values and formulaic sentences per §Computations. Precondition-gate every computation: if a component is null, skip it and its sentence fragment.
4. **Sweep** for empties per the hard rules.
5. **Fill the template** in §Template (variant deltas in §Variants).
6. **Convert to PDF** per §PDF. Output `vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf` in the current directory.
7. **Respond** minimally: the PDF path + one sentence naming the address.

## Data — what fills each element

Layers on `https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer`:

| Scale | Layer | Label |
|---|---|---|
| Block (block group) | `/12` | `BLOCK` (table) · `Block` (bars, occupation) |
| Tract | `/11` | `TRACT` · `Tract` |
| ZIP | `/9` | `ZIP {zip}` |
| County | `/7` | `{COUNTY} CO.` (table; strip a trailing " County" from NAME, uppercase) · `{County} Co.` (bars) |
| National (country layer) | `/13` | `NATIONAL` · `National` |

`query_gis_field` battery — every batch ≤3 fields, all batches in parallel:

| Batch | Fields | Layers | Feeds |
|---|---|---|---|
| Population | `TOTPOP_CY`, `MEDAGE_CY`, `AVGHHSZ_CY` | all five | Median-age KPI · Median Age + Avg HH Size rows |
| Tenure | `TOTHH_CY`, `RENTER_CY`, `OWNER_CY` | all five | Renter KPI · Renter Share row · lede |
| Rent | `MEDCRNT_CY`, `MEDVAL_CY`, `MEDHINC_CY` | block `/12` only (all five for the Rental variant) | Lede rent-to-income (`MEDHINC_CY` cross-checks the income section's block value) |
| Occupation O1 | `OCCMGMT_CY`, `OCCBUS_CY`, `OCCCOMP_CY` | `/12`, `/11`, `/9` | White collar |
| Occupation O2 | `OCCARCH_CY`, `OCCSSCI_CY`, `OCCSSRV_CY` | `/12`, `/11`, `/9` | White collar |
| Occupation O3 | `OCCLEGL_CY`, `OCCEDUC_CY`, `OCCENT_CY` | `/12`, `/11`, `/9` | White collar |
| Occupation O4 | `OCCHTCH_CY`, `OCCSALE_CY`, `OCCADMN_CY` | `/12`, `/11`, `/9` | White collar |
| Occupation O5 | `OCCHLTH_CY`, `OCCPROT_CY`, `OCCFOOD_CY` | `/12`, `/11`, `/9` | Service |
| Occupation O6 | `OCCBLDG_CY`, `OCCPERS_CY`, `EMP_CY` | `/12`, `/11`, `/9` | Service · employed base |
| Occupation O7 | `OCCFARM_CY`, `OCCCONS_CY`, `OCCMAIN_CY` | `/12`, `/11`, `/9` | Blue collar |
| Occupation O8 | `OCCPROD_CY`, `OCCTRAN_CY`, `UNEMPRT_CY` | `/12`, `/11`, `/9` | Blue collar · unemployment rate |

Field facts (validated live):
- **No aggregate occupation fields exist** on this service (`WHTCLR_CY`, `OCCPROF_CY`, `WHITECOL_CY`, `OCCWHT_CY` etc. all error). The three classes are sums of the 22 `OCC*_CY` fields, which together equal `EMP_CY` exactly (verified: 424 + 60 + 104 = 588). Esri's standard grouping: **white collar** = management, business/financial, computer/math, architecture/engineering, sciences, community/social service, legal, education, arts/entertainment/media, health practitioners/technical, sales, office/admin (O1–O4); **service** = healthcare support, protective service, food preparation, building/grounds, personal care (O5 + `OCCBLDG_CY`, `OCCPERS_CY`); **blue collar** = farming/fishing, construction/extraction, installation/maintenance, production, transportation (O7 + `OCCPROD_CY`, `OCCTRAN_CY`).
- **`UNEMPRT_CY`** is the unemployment rate in percent (e.g. `1.3`); `EMP_CY` is employed civilians 16+. Both exist at `/12`, `/11` and `/9`.
- **`MEDRENT_CY` does not exist** — `MEDCRNT_CY` (Median Contract Rent) is the canonical rent field.
- `/13` is the **country layer** — same field names, national values (e.g. `TOTPOP_CY` ≈ 338M). It backs every `NATIONAL` column cell and the KPI-card national references.
- **`query_gis_field` skips fields that are missing and names them** ("Skipped N field(s) not present…") while returning the rest; a call whose *every* field is missing errors instead. Keep batches ≤3 fields. If a whole batch errors unexpectedly, re-probe its fields one per call (parallel) and drop only the nulls — never surface the failure.

Element → source map (Demographics page):

| Element | Values |
|---|---|
| Masthead | Eyebrow "Demographics"; H1 = full address; context "{City}, {ST} · {County Name} · ZIP {zip}"; lockup + tagline (template) |
| Lede | Formula in §Computations, from: renter share, median age, white collar, block HHI, block rent, rent-to-income, block growth, national growth |
| KPI 1 `MEDIAN HHI · BLOCK` | Block `median_household_income`; sub: "{round(block/national×100)}% of the ${national} national median." |
| KPI 2 `MEDIAN AGE · BLOCK` | Block `MEDAGE_CY`; sub: "{|national − block|, 1dp} years {under|over} the national {national}." ("Matches the national {national}." if equal at 1dp) |
| KPI 3 `RENTER SHARE · BLOCK` (mint pop card) | Block renter share; sub: "{RENTER_CY} of {TOTHH_CY} HH · Nationally {national share}%" |
| Map panel | Head "Median HHI · Block Groups" / "2024 ACS estimate"; the Income map (§Maps); legend title "Median Household Income" + five swatches with the transcribed class labels |
| Growth panel | Head "Population Growth · 5-yr CAGR"; expansion CAGR at the five scales as bars, labels Block · Tract · ZIP {zip} · {County} Co. · National, every bar green, widths ∝ value/max (min 2.5% — a negative value renders at the minimum width with its signed label), values signed 2dp. No note line. |
| Occupation panel | Head "Occupation Profile"; three sections — Block, Tract, ZIP {zip} — each: three rings (White Collar · Blue Collar · Service, whole-% inside the ring), then the dominant line "▶ {Dominant class}" in that class's colour and "Unemployment: {UNEMPRT_CY}% · {EMP_CY} employed" |
| Summary table | Title "Cross-Scale Summary"; rows Median HHI · Median Age · Renter Share · Pop Growth (CAGR) · Avg HH Size; five scale columns; every non-Block cell carries a delta line vs Block (§Computations) |
| Footer | "Source: Esri Demographics 2024 · ACS 5-yr estimates · VestMap GIS" · "Generated {Month D, YYYY}" |

## Computations

- **Renter share** = `RENTER_CY / (RENTER_CY + OWNER_CY) × 100` per scale (needs both), 1dp.
- **Occupation classes** (per scale, each needs `EMP_CY` > 0): white collar = Σ(O1–O4 fields) / `EMP_CY` × 100; service = (`OCCHLTH_CY`+`OCCPROT_CY`+`OCCFOOD_CY`+`OCCBLDG_CY`+`OCCPERS_CY`) / `EMP_CY` × 100; blue collar = (`OCCFARM_CY`+`OCCCONS_CY`+`OCCMAIN_CY`+`OCCPROD_CY`+`OCCTRAN_CY`) / `EMP_CY` × 100. A class whose every field was skipped is null (drop its ring); a class with some fields skipped uses the fields returned. Rings print the whole-number percent; the lede prints the block white-collar share at 1dp.
- **Dominant class** = the largest of the three shares in that section; its name ("White Collar" / "Blue Collar" / "Service") and colour (green / blue / clay) drive the ▶ line. Ties go to white collar, then service.
- **Rent-to-income** = `MEDCRNT_CY × 12 / median_household_income × 100` for the block, 1dp. If the user supplies the property's own asking rent ("ask is $X", "asking rent $X"), the lede uses `X × 12 / block HHI` and says "the **${X}** asking rent" instead of "the block **${rent}** median contract rent".
- **Burden comparator** (lede): let d = rent-to-income − 30. d = 0.0 → "right at"; |d| ≤ 3 → "just slightly {lower|higher} than"; 3 < |d| ≤ 10 → "{lower|higher} than"; |d| > 10 → "well {below|above}". Lower/below when d < 0.
- **Growth ratio** = block CAGR / national CAGR, 1dp, only when both > 0.
- **Table deltas** (every non-Block cell, direction from the raw values, magnitude rounded): ▲ (green) when the cell's value > Block, ▼ (clay) when < Block, no delta line when exactly equal. Magnitude by row — Median HHI: `|cell − block| / block × 100` as "{x.x}%"; Median Age: "{x.x} yr"; Renter Share: "{x.x} pt"; Pop Growth: "{x.xx} pt"; Avg HH Size: "{x.xx}". Direction only — never a value judgment.
- **KPI subtexts** use the exact sentence patterns in the table above; round years and ratios to 1dp, share-of-national to whole %.
- **Lede pattern** (omit any fragment whose inputs are null, keep it ≤4 rendered lines):
  "The block group location of **{street line}** is **{renter share}% renters** with a median age of **{age}**, with **{wc}%** of the employed population working white-collar jobs. The median household income for the block of **${HHI}** means the block **${rent}** median contract rent is **{rti}%** of gross income {comparator} the 30% of gross income rent burden standard. The block group is growing **+{growth}%** a year — **{ratio}×** the national rate."
  - Block growth ≤ 0 → the last sentence becomes "The block group is shrinking **−{|growth|}%** a year against **{signed national}%** nationally." (a zero prints as "+0.00%").
  - Block growth > 0 but national ≤ 0 → end at "…a year." and drop the ratio clause.
  - Print negative values with a true minus sign (−), positives with an explicit plus.
- **Formatting**: currency `$X,XXX` (no decimals); percentages 1dp except CAGR 2dp and ring labels 0dp; counts with thousands separators; `font-variant-numeric: tabular-nums` is already set globally. Footer date is long-form ("September 4, 2026").

## Maps — one VestMap choropleth per page

Built with **`custom_map_screenshot`** (the arbitrary-field renderer), never `map_screenshot`. It returns a hosted 1120×560 JPG with a legend baked into the top-right, the property pin dead centre, and Esri attribution along the bottom-right.

### Registry

| Page | `service_url` | `field_name` | `field_alias` / `legend_title` | Slot |
|---|---|---|---|---|
| Demographics (default) | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDHINC_CY` | `2024 Median Household Income` / `Median HHI` | `{{INCOME_MAP_URL}}` |
| Rental Market (variant) | `…/USA_Demographics_and_Boundaries_2024/MapServer/12` | `MEDCRNT_CY` | `2024 Median Contract Rent` / `Median Rent` | `{{RENT_MAP_URL}}` |

Every call passes exactly:

```
classification_method: "quantile"
class_breaks_count:    5
colors: ["#edf5ef","#b7d9bf","#6fb585","#2e8b65","#1b4d3e"]
address: <the subject address>
```

The five-step mint→forest ramp (low→high) is the page's map signature — it is the brand's success green and forest tones, and the same five hexes are the HTML legend swatches. `map_id` is unnecessary (the plain-basemap fallback is correct). Quantile classes are cut on the rendered extent, so the map carries local contrast in every market; the price is that the breaks differ per market and must be read off the returned image.

### The HTML legend — transcribe the baked breaks

1. Open the returned image (download it and view it). Read the five legend rows top→bottom (highest class first).
2. **Degenerate check.** A quantile legend is degenerate when two adjacent breaks are equal, or the bottom class ends at 0. If degenerate, retry the call once with identical arguments; if still degenerate, switch to `classification_method: "equal-interval"` (breaks are then national and fixed — see the fallback labels below).
3. Write the five HTML labels **low→high** (the legend row runs left→right, light→dark) from the actual breaks, rounded for legibility — income to the nearest $1k, rent to the nearest $10:

| | first | middle three | last |
|---|---|---|---|
| Income | `<${b1}k` | `${b1}–{b2}k` · `${b2}–{b3}k` · `${b3}–{b4}k` | `${b4}k+` |
| Rent | `<${b1}` | `${b1}–{b2}` · … | `${b4}+` |

   e.g. baked `<= 26,954 / 26,954 - 41,096 / 41,096 - 51,670 / 51,670 - 64,046 / 64,046 - 200,001` → `<$27k · $27–41k · $41–52k · $52–64k · $64k+`.
4. **Equal-interval fallback labels** (deterministic, no transcription): income `<$40k · $40–80k · $80–120k · $120–160k · $160k+`; rent `<$700 · $700–1,400 · $1,400–2,100 · $2,100–2,800 · $2,800+`.
5. If you have no way to view the image, do not guess the quantile breaks — use the equal-interval call and its fixed labels instead. A legend that does not match its map is worse than a paler map.

### Crop geometry (why the CSS values are what they are)

- **Default panel slot** (`.mapwrap` at aspect `1.8/1` holding `.mapimg` at `width:150%`, centred on both axes): the image is enlarged 1.5× and centred, so the panel shows raw pixels x ≈ 187–933, y ≈ 72–487 of the 1120×560 image — the baked legend (x ≥ 950) sits just outside the right edge, the attribution strip (y > 528) below the bottom edge, and the pin stays dead centre. That is what lets the panel carry the clean HTML legend beneath. The zoom is what hides the legend: never reduce it below 148% (the legend's left edge re-enters the frame); the aspect may sit anywhere between 1.6 and 1.9.
- **Map Center slot** (`.mapimg.wide`, aspect `2.35/1`, `object-fit:cover; object-position:center top`): full width, cropped only from the bottom, so the baked legend stays visible (it is the legend for that layout) and the pin (y-centre) survives. Never crop a wide slot from the top.

### Transient errors are NOT failures — retry once before omitting

- **Transport / gateway error** — not valid JSON: `Unexpected token '<', "<html>…"`, a timeout, a 502/503. **Retry the call once with identical arguments.** Only omit if the retry also fails.
- **Data error** — a well-formed message naming a field, layer, or address. Retrying will not help; omit immediately.

Never diagnose a transport error as a registry problem, and never let a free-text `data_query` substitute for the registry call — free-text resolution can land on coarser geographies or the dead 2022 service (`Service USA_Demographics_and_Boundaries_2022/MapServer not started` can only come from a non-registry call).

### Graceful failure

If the page's map call fails after the retry: drop the entire map panel (image and legend) and let the growth panel fill the left column (`.growth` already has `flex:1`), keeping the rest of the page unchanged. Never substitute a different map; never mention the omission.

### Wired but omitted: home value

`MEDVAL_CY` renders with the same registry pattern; offer it only if the user asks for a home-value map, and note nothing on the page either way.

### Custom maps on request

If the user names another data layer ("flood risk", "owner-occupancy", "unemployment"): `search_real_estate_data("<ask>")` → pick the **Block Group** (or finest) result → `custom_map_screenshot` with that `layerUrl`/`fieldName`, `class_breaks_count: 5`, `quantile` (same degenerate check), a ramp suited to the meaning (red ramps only for risk), and a finished `legend_title`. Render it as an extra page in this dashboard language (pattern the page on the Rental variant), with its HTML legend transcribed from the returned image's baked legend.

## Template — the self-contained page

Reproduce this structure and CSS **byte-for-byte**, substituting the subject's real values (or dropping per the sweep rules). Values shown are markup illustration only. The `<style>` block is the locked brand layer.

```html
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Demographics · {{ADDRESS}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap" rel="stylesheet">
<style>
@page{ size:Letter; margin:0; }
*{ box-sizing:border-box; margin:0; padding:0; }
/* VestMap live tokens — vestmap.com/colors_and_type.css */
:root{
  --bg:#11221E;            /* forest-900 */
  --panel:#1E3B34;         /* forest-700 */
  --line:rgba(255,255,255,.14);
  --hair:rgba(255,255,255,.10);
  --track:rgba(255,255,255,.08);
  --ink:#E6F1EB;           /* mint-100 */
  --muted:rgba(255,255,255,.66);
  --faint:rgba(255,255,255,.45);
  --green:#2E8B65;         /* success-500 */
  --blue:#5B8DB8;          /* dv-cat-blue (legible on dark) */
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
  --track:rgba(15,23,32,.08);
  --ink:#0F1720;           /* slate-900 */
  --muted:#2A333D;         /* slate-700 */
  --faint:#5A6470;         /* slate-500 */
  --green:#1F6B4E;         /* success-700 */
  --blue:#3D6E9E;
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
.eyebrow{ font-size:7pt; font-weight:600; letter-spacing:0.16em; text-transform:uppercase; color:var(--sage); }
.hd{ display:flex; justify-content:space-between; align-items:flex-start; }
.hd h1{ font-weight:700; font-size:17pt; letter-spacing:-0.025em; line-height:1.1; color:var(--ink); margin-top:3px; }
.hd .ctx{ margin-top:4px; font-size:8.5pt; color:var(--muted); }
.wm{ display:flex; flex-direction:column; align-items:flex-end; padding-top:4px; flex:none; }
.wm img{ height:0.23in; width:auto; display:block; }
.wm .lg-forest{ display:none; }
body.light .wm .lg-inverted{ display:none; }
body.light .wm .lg-forest{ display:block; }
.wm .tag{ margin-top:5px; font-family:var(--font-mono); font-size:6.3pt; letter-spacing:0.14em;
  text-transform:uppercase; color:var(--sage); }
.rule{ border:none; border-top:1px solid var(--line); margin:0.10in 0 0.10in; }
.lede{ font-size:9.2pt; line-height:1.5; color:var(--muted); }
.lede b{ color:var(--ink); font-weight:600; }
.kpis{ display:grid; grid-template-columns:repeat(3,1fr); gap:0.12in; margin-top:0.11in; }
.kpi{ position:relative; background:var(--panel); border:1px solid var(--line);
  border-radius:12px; padding:0.10in 0.13in 0.11in; }
.kpi .lbl{ font-size:6.8pt; font-weight:600; letter-spacing:0.14em;
  text-transform:uppercase; color:var(--sage); }
.kpi .val{ font-weight:700; font-size:20pt; letter-spacing:-0.02em;
  line-height:1.08; margin-top:4px; color:var(--ink); }
.kpi .sub{ font-size:7.6pt; color:var(--faint); margin-top:4px; }
.kpi.pop{ background:var(--cardpop-bg); border-color:var(--cardpop-bg); }
.kpi.pop .lbl{ color:var(--cardpop-sub); }
.kpi.pop .val{ color:var(--cardpop-ink); }
.kpi.pop .sub{ color:var(--cardpop-sub); }
.grid{ display:grid; grid-template-columns:60% 1fr; gap:0.12in; margin-top:0.11in; flex:1; min-height:0; }
.lcol{ display:flex; flex-direction:column; gap:0.12in; min-height:0; }
.panel{ position:relative; background:var(--panel); border:1px solid var(--line);
  border-radius:16px; padding:0.12in 0.14in; }
.phead{ display:flex; justify-content:space-between; align-items:baseline; margin-bottom:0.07in; }
.phead .t{ font-size:7.2pt; font-weight:600; letter-spacing:0.14em; text-transform:uppercase; color:var(--sage); }
.phead .r{ font-size:6.6pt; color:var(--faint); }
.mapwrap{ position:relative; width:100%; aspect-ratio:1.8/1; overflow:hidden;
  border-radius:8px; border:1px solid var(--hair); }
.mapwrap .mapimg{ position:absolute; width:150%; height:auto; left:50%; top:50%;
  transform:translate(-50%,-50%); display:block; }
.mapimg.wide{ width:100%; aspect-ratio:2.35/1; object-fit:cover; object-position:center top;
  display:block; border-radius:8px; border:1px solid var(--hair); }
.legt{ margin-top:0.08in; font-size:6.8pt; font-weight:600; letter-spacing:0.14em;
  text-transform:uppercase; color:var(--sage); }
.leg{ display:flex; gap:0.16in; margin-top:0.05in; }
.leg .li{ display:flex; align-items:center; gap:5px; font-size:7pt; color:var(--muted); }
.leg .sw{ width:12px; height:12px; flex:none; border-radius:2px; border:1px solid rgba(0,0,0,0.25); }
.growth{ flex:1; display:flex; flex-direction:column; }
.growth .bars{ margin:auto 0; }
.bars .brow{ display:grid; grid-template-columns:0.85in 1fr 0.55in; align-items:center; gap:8px; margin:5px 0; }
.bars .bk{ font-size:7.5pt; color:var(--muted); text-align:right; }
.bars .bt{ height:6px; border-radius:3px; background:var(--track); position:relative; overflow:hidden; }
.bars .bf{ position:absolute; inset:0 auto 0 0; border-radius:3px; background:var(--green); }
.bars .bv{ font-family:var(--font-mono); font-weight:600; font-size:8pt; text-align:right; color:var(--ink); }
.occ .sec{ padding:0.02in 0 0.06in; }
.occ .sec + .sec{ border-top:1px solid var(--hair); padding-top:0.06in; }
.occ .sh{ font-size:9.5pt; font-weight:700; color:var(--ink); letter-spacing:0.04em; text-transform:uppercase;
  padding-bottom:4px; border-bottom:1px solid var(--hair); margin-bottom:0.06in; }
.rings{ display:grid; grid-template-columns:repeat(3,1fr); gap:0.06in; }
.rg{ text-align:center; }
.rg svg{ display:block; margin:0 auto; }
.rg .pct{ font-family:var(--font-mono); font-weight:700; font-size:9.5pt; fill:var(--ink); }
.rg .rk{ font-size:6.8pt; color:var(--muted); line-height:1.3; margin-top:3px; }
.occ .dom{ display:flex; justify-content:space-between; align-items:baseline; margin-top:0.05in; }
.occ .dom .d{ font-size:8pt; font-weight:700; }
.occ .dom .d.wc{ color:var(--green); } .occ .dom .d.bc{ color:var(--blue); } .occ .dom .d.sv{ color:var(--clay); }
.occ .dom .u{ font-size:6.5pt; color:var(--faint); }
.sumt{ margin-top:0.12in; margin-bottom:0.03in; font-size:7.2pt; font-weight:600; letter-spacing:0.14em;
  text-transform:uppercase; color:var(--sage); }
table.sum{ width:100%; border-collapse:collapse; }
.sum th{ font-size:6.8pt; letter-spacing:0.12em; text-transform:uppercase; color:var(--sage);
  font-weight:600; text-align:right; padding:5px 6px; border-bottom:1px solid var(--line); }
.sum th:first-child{ text-align:left; padding-left:2px; }
.sum td{ padding:4.5px 6px; text-align:right; font-family:var(--font-mono); font-size:8.5pt;
  border-bottom:1px solid var(--hair); color:var(--ink); vertical-align:top; }
.sum tr:last-child td{ border-bottom:none; }
.sum td.m{ text-align:left; padding-left:2px; font-family:var(--font-body); font-size:7.6pt; color:var(--muted); }
.sum td.blk{ font-weight:700; }
.sum td.nat{ font-style:italic; color:var(--muted); }
.sum .d{ display:block; font-size:6.5pt; margin-top:2px; }
.sum .d.up{ color:var(--green); } .sum .d.dn{ color:var(--clay); }
.ft{ display:flex; justify-content:space-between; margin-top:0.10in; font-size:7pt; color:var(--faint); }
</style></head>
<body><!-- add class="light" for the Light Print variant -->
<div class="page">
  <div class="hd">
    <div><div class="eyebrow">Demographics</div>
      <h1>511 Campbell St, Kansas City, MO 64106</h1>
      <div class="ctx">Kansas City, MO &middot; Jackson County &middot; ZIP 64106</div></div>
    <div class="wm">
      <img class="lg-inverted" src="https://vestmap.com/assets/logo-vestmap-inverted.png" alt="VestMap"/>
      <img class="lg-forest" src="https://vestmap.com/assets/logo-vestmap-forest.png" alt="VestMap"/>
      <div class="tag">Real Estate Intelligence</div>
    </div>
  </div>
  <hr class="rule"/>

  <div class="lede">{{LEDE — the pattern in §Computations, figures in <b>}}</div>

  <div class="kpis">
    <div class="kpi"><div class="lbl">Median HHI &middot; Block</div>
      <div class="val">$55,644</div><div class="sub">70% of the $79,068 national median.</div></div>
    <div class="kpi"><div class="lbl">Median Age &middot; Block</div>
      <div class="val">40.2</div><div class="sub">0.9 years over the national 39.3.</div></div>
    <div class="kpi pop"><div class="lbl">Renter Share &middot; Block</div>
      <div class="val">67.2%</div><div class="sub">299 of 445 HH &middot; Nationally 35.6%</div></div>
  </div>

  <div class="grid">
    <div class="lcol">
      <div class="panel">
        <div class="phead"><span class="t">Median HHI &middot; Block Groups</span><span class="r">2024 ACS estimate</span></div>
        <div class="mapwrap"><img class="mapimg" src="{{INCOME_MAP_URL}}" alt="Median household income by block group"/></div>
        <div class="legt">Median Household Income</div>
        <div class="leg">
          <!-- five .li items low→high; swatches are the registry colours in order, labels transcribed per §Maps -->
          <div class="li"><span class="sw" style="background:#edf5ef"></span>&lt;$27k</div>
          <div class="li"><span class="sw" style="background:#b7d9bf"></span>$27&ndash;41k</div>
          <div class="li"><span class="sw" style="background:#6fb585"></span>$41&ndash;52k</div>
          <div class="li"><span class="sw" style="background:#2e8b65"></span>$52&ndash;64k</div>
          <div class="li"><span class="sw" style="background:#1b4d3e"></span>$64k+</div>
        </div>
      </div>
      <div class="panel growth">
        <div class="phead"><span class="t">Population Growth &middot; 5-yr CAGR</span></div>
        <div class="bars">
          <!-- five .brow rows: Block · Tract · ZIP {zip} · {County} Co. · National
               .bf width = value/max×100 (min 2.5%), .bv = signed value 2dp + % -->
          <div class="brow"><span class="bk">Block</span>
            <span class="bt"><span class="bf" style="width:63.7%"></span></span>
            <span class="bv">+1.23%</span></div>
          <!-- … -->
        </div>
      </div>
    </div>
    <div class="panel occ">
      <div class="phead"><span class="t">Occupation Profile</span></div>
      <!-- three .sec blocks: Block · Tract · ZIP {zip} -->
      <div class="sec">
        <div class="sh">Block</div>
        <div class="rings">
          <!-- ring svg: r=25, C=157.1; arc dasharray = pct/100×157.1 followed by 157.1;
               arc stroke = var(--green) white collar · var(--blue) blue collar · var(--clay) service -->
          <div class="rg"><svg width="52" height="52" viewBox="0 0 64 64">
              <circle cx="32" cy="32" r="25" fill="none" stroke="var(--track)" stroke-width="5.5"/>
              <circle cx="32" cy="32" r="25" fill="none" stroke="var(--green)" stroke-width="5.5" stroke-linecap="round"
                stroke-dasharray="113.3 157.1" transform="rotate(-90 32 32)"/>
              <text class="pct" x="32" y="32" text-anchor="middle" dominant-baseline="central">72%</text></svg>
            <div class="rk">White<br/>Collar</div></div>
          <!-- ring 2: var(--blue), "Blue<br/>Collar" · ring 3: var(--clay), "Service" -->
        </div>
        <div class="dom"><span class="d wc">&#9654; White Collar</span>
          <span class="u">Unemployment: 1.3% &middot; 588 employed</span></div>
      </div>
      <!-- .sec "Tract" … · .sec "ZIP 64106" … -->
    </div>
  </div>

  <div class="sumt">Cross-Scale Summary</div>
  <table class="sum">
    <thead><tr><th>Metric</th><th>Block</th><th>Tract</th><th>ZIP 64106</th><th>Jackson Co.</th><th>National</th></tr></thead>
    <tbody>
      <tr><td class="m">Median HHI</td><td class="blk">$55,644</td>
        <td>$78,551<span class="d up">&#9650; 41.2%</span></td><td>$59,458<span class="d up">&#9650; 6.9%</span></td>
        <td>$64,942<span class="d up">&#9650; 16.7%</span></td><td class="nat">$79,068<span class="d up">&#9650; 42.1%</span></td></tr>
      <!-- Median Age ("x.x yr") · Renter Share ("x.x pt") · Pop Growth (CAGR) (signed values, "x.xx pt") · Avg HH Size ("x.xx") follow the same pattern -->
    </tbody>
  </table>

  <div class="ft"><span>Source: Esri Demographics 2024 &middot; ACS 5-yr estimates &middot; VestMap GIS</span><span>Generated {{Month D, YYYY}}</span></div>
</div></body></html>
```

## Variants (only when the user names them)

| Trigger | Variant | Delta from the default template |
|---|---|---|
| "map at the center", "map first", "map-centered" | **Map Center** | Drop the lede. Order: `.kpis` → a full-width `.panel` holding `<img class="mapimg wide" …>` under phead "Median HHI · Block Groups" / "Block Group · 2024 ACS estimate" (no HTML legend — the wide crop keeps the baked legend) → a full-width `.panel.occ` whose three `.sec` blocks sit side by side (`style="display:grid;grid-template-columns:repeat(3,1fr);gap:0.14in"` on a wrapper, no `.sec + .sec` rule) → the Growth panel full width → `.sumt` + table → footer. |
| "light", "print", "light theme" | **Light Print** | `<body class="light">`. Nothing else changes. |
| "rental page", "rental market page", "add the rental page" | **Rental Market page** | Same skeleton, eyebrow "Rental Market". KPIs: Median Rent · Block (sub "{block/national}% of the ${national} national median."), Renter Share · Block (the mint pop card, same as default), Rent to Income · Block (sub "{comparator} the 30% burden standard."). Map panel: phead "Median Rent · Block Groups" / "2024 ACS estimate", `{{RENT_MAP_URL}}`, legend title "Median Contract Rent" with the rent labels transcribed per §Maps. Growth panel becomes "Renter Share · by Scale" bars (renter share ×5 scales, 1dp, unsigned). Occupation panel becomes "Tenure Profile": per scale (Block · Tract · ZIP) rings Renter (green) · Owner (blue) · Rent to Income (green below 30%, clay at ≥30%), dominant line "▶ Renter" / "▶ Owner" and "Median rent: ${MEDCRNT_CY} · {TOTHH_CY} HH". Summary rows: Median Rent · Renter Share ("x.x pt") · Rent to Income ("x.x pt") · Median HHI · Pop Growth (CAGR). Output as its own page after the default page, or standalone if asked alone. |
| "ask(ing) rent $X" | Ask override | Lede per §Computations. |
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

`--virtual-time-budget=20000` covers the hosted map image and the Google webfonts (the page has no JavaScript). On Linux use the `chromium`/`google-chrome` binary with the same flags; `--no-pdf-header-footer` plus the template's `@page{margin:0}` keep the page full-bleed. Then delete the intermediate `.html`. If Chrome is missing, output the HTML instead and tell the user once that the PDF needs Chrome (File → Print → Save as PDF preserves the page).

## Respond

Print the PDF path and one sentence naming the address. Do not list sections, do not mention any missing data or dropped panel, do not describe the layout.
