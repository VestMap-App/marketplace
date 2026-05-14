---
name: vestmap-om-pages
description: Render a property Offering Memorandum (OM) page for any US address — a visual, page-oriented PDF (default output) showing demographics, income, housing, workforce, and safety at Block / ZIP / City / County scales with explicit cross-scale comparisons. Use when the user asks for an "OM", "one-pager", "investor page", "property page", "marketing page", or a rendered / laid-out visual for a property. The page is market-agnostic — no city-specific wording, no carve-outs. Block-level data is added by default. Optional modules (Risk, Schools, Education detail, HPI, full income distribution, all 13 occupations, Business/MSA) are NOT rendered by default; they appear only on explicit request. Delegates all Block / Tract / ZIP / County data acquisition to the `vestmap` skill and inherits its R7 / R9 / R10 / R11 / R13 rules.
user-invocable: true
---

# VestMap OM Pages Skill

Render Offering Memorandum pages for US addresses. Single-address, page-oriented, PDF-first output.

This skill is a **rendering + data-curation layer on top of the `vestmap` skill**. It defines exactly which fields appear by default, how values flow from source data into the page, and how the page is laid out so comparisons across scales are legible. It does NOT define new data rules — those live in the parent `vestmap` skill.

## When to use this skill

Trigger on any of:
- User asks for an "OM", "offering memorandum", "one-pager", "investor page", "marketing page", "property page", "property brief page"
- User asks to "render" or "lay out" demographic / market data for a property as a page
- User asks for a rendered / formatted page for any US address
- User asks for a comparison page across Block / ZIP / City / County

Do NOT trigger for: plain ranking tables, data dumps, one-liners, "what's the median income here", "which ZIP has…". Those stay on the base `vestmap` skill.

## Inheritance from `vestmap`

Everything the parent skill enforces still applies. In particular:

- **R5 (never use Tapestry for hard metrics)** — OM numbers come from `get_section_data("income"|"expansion"|"crime"|"schools")` and `query_gis_field` Tier 1 fields. NEVER from `get_section_data("demographics")`. NO Tapestry segment names on the page (no "Tapestry Grade", no lifestyle pill).
- **R7 (explicit quantitative cross-scale comparisons)** — every multi-scale metric must show deltas/ratios, not just values. The 4-column + chip layout enforces this.
- **R9 (blank fields are omitted, never filled)** — if a VestMap call returned null, the cell disappears. Never print "N/A", "—", "data unavailable", etc.
- **R10 (no qualitative analysis beyond the numbers)** — no "desirable", "up-and-coming", "affluent". Numbers only.
- **R11 (computed metrics are precondition-gated)** — no delta shown when a component is null.
- **R13 (verify discovery-vs-field for decision-grade metrics)** — forecasted growth rates cross-check the canonical `_CY` / `_FY` field before rendering.

Always read `../vestmap/SKILL.md` before acquiring data. Do not duplicate those rules here — follow them.

## Reference Files

| File | When to load |
|---|---|
| `references/data-spec.md` | Always. Defines which fields are on the OM by default, their data source at each scale, and the opt-in modules. |
| `references/fields-manifest.md` | Always. Frozen, validated list of every field the default OM uses, scoped to the layer where it's verified queryable. Source of truth for field names — `data-spec.md` references it. Custom mode is not constrained by the manifest. |
| `references/layout.md` | Always. Defines section order, comparison viz, typography, styling tokens, PDF export, and what NOT to do. |
| `templates/om-page.html` | Always. Self-contained HTML+CSS template with named slots. |

## Output Rules (hard constraints)

**O0. READ THIS FIRST. Authoritative scope lock.** The rendered page is built from exactly one source of numbers: VestMap tool calls (`get_section_data`, `query_gis_field`, `search_real_estate_data`). The sections listed under **§Default sections** below are the complete, exhaustive set of sections that render on a default OM. Opt-in modules appear only when the user explicitly requests them by name.

Do NOT add, infer, reconstruct, or re-introduce any section, panel, metric, badge, pill, gauge, chip, or callout that is not defined in this file or in `references/data-spec.md`. If a concept you "remember" from a previous conversation, a prior skill version, or training data is not present in these files right now, it does not exist in this skill. Treat any such recollection as a hallucination and ignore it.

If the user asks you to add something that isn't in the default list or the opt-in module list, tell them — do not silently add it based on what you think the skill "used to" do.

**O1. PDF is the default output.** Write the HTML to a temp path, then convert to PDF and print the PDF path to the user. Do NOT stream HTML in chat. Do NOT offer HTML by default. Only provide HTML instead of PDF if the user explicitly says "HTML" or "html only".

See `layout.md §9 PDF export` for the exact headless-Chrome command.

**O2. The rendered page NEVER mentions missing data, failed calls, or dropped modules.** This is the strictest output rule in the skill. The page does not contain:
- "N/A", "—", "No data", "data unavailable", "not available", "unknown"
- "row dropped", "omitted", "skipped", "conserve layer calls"
- R13 divergence explanations
- Lists of which optional modules were added / excluded
- Tool-call names, layer IDs, field names

If a value is missing, the cell is invisible (CSS `display:none`). If a row has fewer than 2 non-null cells, the row is removed from the DOM. If a section has fewer than 2 rows, the section is removed. Everything silently gets smaller.

**O3. Never fabricate a value to fill a cell.** Skip vs. make-up: always skip.

**O4. NO Tapestry anywhere on the page.** Per R5. No "Tapestry Grade: X" pill, no segment name, no "lifestyle" callout. Tapestry is forbidden from the rendered output even as decorative flavor.

**O5. NO market-specific / city-specific hardcoded wording.** The rendered page reads identically regardless of market. The only places a market name appears are the subject address, the locality line, and the MSA callout — all three data-driven from the geocoded subject.

**O6. The header does NOT say "Offering Memorandum".** No eyebrow text above the address. No document-type label. Just the address as the H1. The user wants this. Do not add it back.

**O7. The context band (3 big-number callouts at top of page 1) is FIXED in content:**
1. **Median HHI at Block** (label: "Median HHI · Block"; value: from `get_section_data("income").median_household_income.block`)
2. **Population growth % at ZIP** (label: "Pop Growth · ZIP, 5-yr CAGR"; value: from `get_section_data("expansion").zip`)
3. **MSA name** (label: "MSA"; value: MSA/CBSA name from `search_real_estate_data("CBSA")` or `Enriched_USA_Metropolitan_Statistical_Areas/FeatureServer/0`)

Do NOT substitute. Do NOT add a crime / safety / risk callout to the header. Do NOT use ZIP-level HHI if Block is missing (drop the whole callout cell instead — O2 + R9).

**O8. Map is default-on.** Every OM has the Leaflet+ESRI hero map rendered unless geocoding literally fails (in which case the `.hero__map` div is removed). Do not make the user opt in to the map.

**O8a. Geocoding policy — VestMap MCP only.** Lat/lng for the hero map come exclusively from VestMap MCP responses. Acquisition order:

1. **Primary.** Every `get_section_data(address, ...)` response normally surfaces `lat` / `lng` (or equivalent) in the payload. Read it from whichever section call you've already fired (`income`, `expansion`, `crime`) — you don't need an additional call.
2. **Fallback.** If no surfaced coords, run `search_real_estate_data("geocode")` once to discover the geocoding feature service, then `query_gis_field` against that service to pull the coords for the subject address.
3. **Failure.** If both 1 and 2 return nothing, the template script removes the `.hero__map` div and adds `.no-map` to `.summary-row` so the summary card spans the full width. **That is the only fallback.** The OM ships without a map.

**Forbidden, no exceptions:** external HTTPS geocoders (`nominatim.openstreetmap.org`, `geocode.arcgis.com`, Google Maps, Mapbox, anything else); `python3 urllib` / `requests` / `curl` / `wget` shell-outs to any geocoder; `mcp__workspace__web_fetch` for coords; browser `fetch`; any path that leaves the VestMap MCP. The sandbox blocks them and the only outcome is wasted turns plus no map. If VestMap MCP can't surface coords, ship the OM without a map (per O8) — do NOT reach outside.

**O9. Self-contained HTML before PDF conversion.** All CSS inline. The only external asset is the Leaflet CDN + ESRI tile layer. Before you open the HTML in headless Chrome to export the PDF, the HTML must be able to open standalone in a browser.

**O10a. Every number must trace to a VestMap tool call.** If you cannot name the specific VestMap tool call (`get_section_data`, `query_gis_field`, or `search_real_estate_data`) that produced a value, that value does not appear on the page. No exceptions, no inference, no filling in from memory.

**O10. Chat response after generation is minimal.** After writing the PDF:
- Print the PDF path
- One sentence stating the subject address
- Stop. Do not list which sections rendered vs dropped. Do not apologize for missing data. Do not announce which opt-in modules were / weren't added unless the user explicitly asked for specific modules and one genuinely didn't materialize.

## Default sections (always rendered when data is present)

1. **Header** — full-bleed dark-green page-header strip with address (see `layout.md §Styling`), followed by a two-up row: summary table + map.
2. **Context band** — 3 big-number callouts per O7 (HHI Block · Pop Growth ZIP · MSA).
3. **Population** — 4-scale comparison: total pop, median age, density, 5-yr pop growth, avg HH size.
4. **Income** — 4-scale: median HHI, 2029 HHI forecast, 5-yr HHI growth, per-capita income, unemployment rate.
5. **Housing Values** — 4-scale: median home value, 2029 forecast, 5-yr growth.
6. **Rental Market** — 4-scale: median rent, renter units, owner units, 2029 renter units, renter share.
7. **Workforce** — 4-scale: 4 occupation buckets (Mgmt / Sales / Prod / Cons) + white/blue collar share + per-scale stacked bars.
8. **Safety** — Block Group raw crime counts from VestMap (3×3 grid). Per-capita line only when `TOTPOP_CY` at Block returned.

See `data-spec.md` for exact field-level data sources and `layout.md` for visual rules.

## Opt-in modules (never rendered by default)

Added only when the user explicitly names them:

| Trigger phrase | Module |
|---|---|
| "include risk", "FEMA", "hazards" | FEMA NRI (Tract only) |
| "include schools" | Nearest 3 schools + district |
| "education", "degree attainment" | 5-bucket education by scale |
| "income distribution", "HINC buckets" | 9-bucket income distribution by scale |
| "all occupations", "13 occupation buckets" | Full 13-bucket workforce |
| "businesses", "MSA data" | Business counts (CBSA) |
| "HPI" | House Price Index |

Details in `data-spec.md §Optional Modules`.

## Workflow

1. **Parse.** Extract subject address. Identify subject ZIP.
2. **Data acquisition** — run in parallel (see `data-spec.md §Block Acquisition`):
   - Required always: `get_section_data(address, "income" | "expansion" | "crime")`, plus per-scale `query_gis_field` calls at `/12` (Block), `/11` (Tract), `/9` (ZIP), `/7` (County).
   - **Field names come from `references/fields-manifest.md`.** Any field not listed in the manifest requires a `search_real_estate_data` discovery step before its first `query_gis_field` — never guess Esri field names from memory or training data. This is how stale names like the deprecated `MEDRENT_CY` get caught before they poison a batch.
   - MSA lookup: `search_real_estate_data("Metropolitan Statistical Area")` once per session → query CBSA name (verbatim) + N01_BUS/N01_EMP fields (name used in the context band; business counts only kept if the user opted in to the Business module).
   - Optional modules: only if triggered.
   - **Poison-pill recovery is automatic.** If any `query_gis_field` batch returns "No data found", run the per-field probe fallback in `data-spec.md §Block Acquisition Step 2`. Do not bisect manually. Do not surface the failure.
3. **Compute deltas.** For every metric with ≥2 non-null scale values, compute absolute + ratio/percentage deltas per `layout.md §2`.
4. **R9/R11 sweep.** Remove empty cells, empty rows, empty sections from the DOM before rendering.
5. **Render HTML** to a temp file.
6. **Convert to PDF** via headless Chrome (`layout.md §9`). Output path: `vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf` in the current working directory.
7. **Respond.** Print the PDF path, one sentence naming the subject address. Stop.

## Gotchas

**`query_gis_field` is all-or-nothing on the field list.**

- One bad field name (or one null returned value) causes the **entire**
  call to return `"No data found at … may be outside this layer's
  coverage area."`
- That message is **not** a coverage error. Coverage errors return the
  same string. Treat it as ambiguous.
- Mitigation:
  1. Keep field names in `references/fields-manifest.md` and treat that
     file as the source of truth. Don't inline new field names.
  2. New fields require a `search_real_estate_data` discovery step before
     their first `query_gis_field` call.
  3. On any "No data found" response, the acquisition recipe runs a
     per-field probe fallback in parallel (one call per field). Drop
     fields that probe null. Never bisect manually, never surface the
     failure to chat or to the page (O2).

This applies in both default and custom modes — anywhere the skill calls
`query_gis_field`, this is the recovery path.

## Custom Mode

The defaults above (`fields-manifest.md`, fixed default sections, locked
visual styling) describe the **address-only** invocation. When the user
signals they want a custom render, the manifest no longer constrains
content and the upload becomes the design source-of-truth.

### Triggers (any of)

- The user attached an image, PDF, or screenshot in the message.
- The user said "match this design", "match this OM", "use these fields",
  "custom render", "like this layout", or named specific non-default
  fields/sections.

If only an address is supplied with no design instruction and no upload,
run defaults. If an upload is present, treat as custom — the upload
signals intent.

### Behavior

- Vision-extract layout cues (sections present, palette, type hierarchy,
  header treatment, section order) from the upload. Treat the upload as
  the design source-of-truth; the locked styling in `layout.md §6a`
  becomes a *default* the upload may override.
- The upload may override **styling** (palette, type, section order,
  header treatment). It may NOT override the canonical scale set
  (Block · Tract · ZIP · County) or the default-on hero map — see
  "Scale translation" below and O8.
- `references/fields-manifest.md` does **not** constrain content. Any
  user-named field still routes through `search_real_estate_data`
  discovery before `query_gis_field` (R13).
- The poison-pill fallback in `data-spec.md §Block Acquisition Step 2`
  **still applies** whenever `query_gis_field` is used. Custom mode
  benefits from it for free.

### Scale translation (radial rings → canonical scales)

VestMap data is queried only at Block (`/12`), Tract (`/11`), ZIP
(`/9`), and County (`/7`). Radial-ring scales (1/3/5 mile, 0.5/1/3
mile, drive-time isochrones, etc.) are **not** supported by the data
layer — there is no mile-radius API.

If the upload labels its comparison columns with mile-radii or other
radial rings, translate them to the canonical scale set:

| Upload columns                  | Render as                       |
|---------------------------------|---------------------------------|
| 2 rings (e.g. 1 / 3 mi)         | Tract · ZIP                     |
| 3 rings (e.g. 1 / 3 / 5 mi)     | Block · Tract · ZIP             |
| 4 rings (e.g. 1 / 3 / 5 / 10)   | Block · Tract · ZIP · County    |

Preserve everything else from the upload (palette, type, section order,
header treatment, comparison patterns like "vs County" deviation
chips). Only the column labels change. Never display or query a
mile-radius column — route every column through `query_gis_field` at
`/12 /11 /9 /7` as usual.

### Hard rules that still hold

- O1 PDF-first output.
- O2 the rendered page never mentions missing data, failed calls, or
  dropped modules.
- O3 never fabricate a value to fill a cell.
- R5 / O4 no Tapestry anywhere on the page.
- O8 the Leaflet+ESRI hero map renders unless geocoding fails — even
  if the upload shows a map placeholder, a grey box, radio-button ring
  selector, or no map at all. The map is a feature, not a styling
  token, and is not overridable by the upload.
- R10 no qualitative analysis beyond the numbers.

## Quick Reference

| User says | Do this |
|---|---|
| "OM for 123 Main St, Denver CO" | Default OM, PDF output. |
| "OM for <address>, include risk and schools" | Default + Risk + Schools modules. |
| "OM for <address>, HTML only" | HTML-only output, skip PDF conversion. |
| "Full OM for <address> with everything" | Default + all opt-in modules. |
| User uploads a screenshot or OM PDF along with the address | Custom Mode — upload is the design reference; manifest does not constrain content. |
| "Match this design / layout" / "use these fields" | Custom Mode. |

## What this skill deliberately does NOT do

- Does not define new data rules.
- Does not publish ranking tables, briefs, or maps-only views.
- Does not ask for confirmation before running (F6).
- Does not render Tapestry-derived values anywhere on the page.
- Does not mention missing data, failed calls, R13 divergences, or dropped sections in the rendered output OR the chat response.
- Does not use market-specific wording. The rendered page is layout-identical across every US market.
