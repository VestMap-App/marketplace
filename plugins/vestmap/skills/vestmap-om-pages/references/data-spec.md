# OM Data Specification

The authoritative list of what data goes on the OM, where each value comes from, and how it's labeled. If a field isn't listed here, it does not appear on a default OM.

Scale convention: **Block · Tract · ZIP · County**. Same scales for every OM, every market.

---

## Section 0 — Hero (identifiers)

Top of page. No cross-scale comparison.

| OM label | Source | Notes |
|---|---|---|
| Address (H1) | user-supplied | Exactly as given. NO eyebrow label above (no "Offering Memorandum", no "OM"). |
| City, State · County · ZIP (locality line) | geocode lookup | |
| Map | Leaflet + ESRI tile layer | **Default-on.** Remove the `.hero__map` div only if geocoding fails. |

### Lat / Lng (map pin)

**VestMap MCP only — see `SKILL.md §O8a`.** Acquisition order:

1. Extract `lat` / `lng` from any `get_section_data(address, ...)` response already in scope (`income`, `expansion`, `crime` — at least one normally surfaces them).
2. If still missing, `search_real_estate_data("geocode")` to discover the geocoding service, then `query_gis_field` against that service for the subject address.
3. If still missing, drop the map cell — the template script removes `.hero__map` and adds `.no-map` to `.summary-row` so the summary card spans full width. Ship the OM without a map.

Surface the result into the template as `{{LAT}}` / `{{LNG}}`. **Never estimate** and **never call an external geocoder** (Nominatim, ArcGIS World Geocoder, Google, Mapbox, etc.). **Never use** `urllib` / `requests` / `curl` / `wget` / `web_fetch` / browser `fetch` to acquire coords — the sandbox blocks them and the map fails silently. The right answer when VestMap MCP can't produce coords is step 3, not an outside retry.

Not on the hero: Tapestry pill, safety pill. None of these are in the header by default.

---

## Context band (3 big-number callouts)

Hard-coded slot contents — see `SKILL.md §O7`. Do NOT substitute.

| Slot | Label | Value | Source |
|---|---|---|---|
| 1 | `Median HHI · Block` | `${{HHI_BLOCK}}` | `get_section_data(address, "income").median_household_income.block` |
| 2 | `Pop Growth · ZIP, 5-yr CAGR` | `{{POPGR_ZIP}}%` | `get_section_data(address, "expansion").zip` |
| 3 | `MSA` | `{{MSA_NAME}}` (verbatim) | See §MSA Lookup below |

**R9 per-slot:** if Block HHI returned null, remove slot 1 entirely (do NOT fall back to ZIP HHI). If ZIP pop growth returned null, remove slot 2. If MSA lookup fails, remove slot 3. The context-band grid simply becomes 2 or 1 columns. Never say "data unavailable".

### MSA Lookup

**Layer:** `https://services5.arcgis.com/9fQmObndozAJu9f5/arcgis/rest/services/Enriched_USA_Metropolitan_Statistical_Areas/FeatureServer/0`

**Discovery:** `search_real_estate_data("Metropolitan Statistical Area")` once per session to confirm the layer URL and the MSA-name field (typical field names: `NAME`, `NAMELSAD`, or `MSA_NAME` — verify which one returns the full name string).

**Query:** `query_gis_field(address, <layer>, ["NAME"])` (or whichever field the discovery call identifies). Use the live string from `query_gis_field` verbatim — do not truncate, do not rename, do not abbreviate. Do NOT pre-fill MSA names from prior plans, training data, or cache; CBSA naming has changed over time and stale names will silently render.

If the address is not inside any CBSA / MSA polygon (rural, outside metros), the slot is dropped (R9).

---

## Section 1 — Population Profile

4 columns.

| OM label | Block source | Non-Block source |
|---|---|---|
| Total population | `query_gis_field(TOTPOP_CY, /12)` — Tier 2 | `query_gis_field(TOTPOP_CY, /11 /9 /7)` |
| Median age | `query_gis_field(MEDAGE_CY, /12)` — Tier 3 (drop cell if null) | same at `/11 /9 /7` |
| Density (per sq mi) | `query_gis_field(POPDENS_CY, /12)` — Tier 2 (manifest) | `query_gis_field(POPDENS_CY, /11 /9 /7)` |
| 5-yr population growth (CAGR) | `get_section_data(address, "expansion").block` | `get_section_data(..., "expansion").tract/.zip/.county` |
| Avg household size | `query_gis_field(AVGHHSZ_CY, /12)` — Tier 3 (drop if null) | same at `/11 /9 /7` |

---

## Section 2 — Income Profile

4 columns.

| OM label | Block source | Non-Block source |
|---|---|---|
| Median HHI | `get_section_data("income").median_household_income.block` | `.tract/.zip/.county` |
| HHI 2029 (forecast) | `query_gis_field(MEDHINC_FY, /12)` — Tier X, drop if null | same at `/11 /9 /7` |
| 5-yr HHI growth | `query_gis_field(MHIGRWCYFY, /12)` — query this field directly; do not cross-check it against any other field or scale. Do not use `get_section_data("income").annual_forecasted_median_income_growth` (different vintage/source). | `query_gis_field(MHIGRWCYFY, /11 /9 /7)` |
| Per capita income | `query_gis_field(PCI_CY, /12)` — Tier 3, drop if null | same at `/11 /9 /7` |
| Unemployment rate | `query_gis_field(UNEMPRT_CY, /12)` Tier 2, fallback compute from `UNEMP_CY / (EMP_CY + UNEMP_CY)` | same |

---

## Section 3 — Housing Values

4 columns.

| OM label | Block source | Non-Block source |
|---|---|---|
| Median home value | `get_section_data("income").median_home_value.block` | `.tract/.zip`; `query_gis_field(MEDVAL_CY, /7)` for County (manifest — survives the poison-pill fallback) |
| HV 2029 (forecast) | `query_gis_field(MEDVAL_FY, /12)` — Tier X | same at `/11 /9 /7` |
| 5-yr HV growth | compute `((MEDVAL_FY/MEDVAL_CY)^(1/5) − 1) × 100` — R11 gated | same at `/11 /9 /7` |

If median home value is 0 at every scale (industrial area with no residential stock), omit the row. No message.

---

## Section 4 — Rental Market

4 columns.

| OM label | Block source | Non-Block source |
|---|---|---|
| Median rent | `query_gis_field(MEDCRNT_CY, /12)` — Tier 2 (manifest; canonical "Median Contract Rent"). Drop if null. | `query_gis_field(MEDCRNT_CY, /11 /9 /7)` |
| Renter units | `query_gis_field(RENTER_CY, /12)` Tier 3, drop if null | same at `/11 /9 /7` |
| Owner units | `query_gis_field(OWNER_CY, /12)` Tier 3, drop if null | same at `/11 /9 /7` |
| 2029 renter units | `query_gis_field(RENTER_FY, /12)` Tier X | same at `/11 /9 /7` |
| Renter share | compute `RENTER_CY / (RENTER_CY + OWNER_CY) × 100` — R11 gated | same at `/11 /9 /7` |

---

## Section 5 — Workforce

4 columns. Default renders 4 occupation buckets + collar shares. Full 13-bucket is opt-in.

| OM label | Block source | Non-Block source |
|---|---|---|
| Management | `query_gis_field(OCCMGMT_CY, /12)` Tier 1 | same at `/11 /9 /7` |
| Sales | `query_gis_field(OCCSALE_CY, /12)` Tier 1 | same |
| Production | `query_gis_field(OCCPROD_CY, /12)` Tier 1 | same |
| Construction | `query_gis_field(OCCCONS_CY, /12)` Tier 1 | same |
| White-collar share | compute from 13 OCC fields | same |
| Blue-collar share | compute from 13 OCC fields | same |

**Collar share formula:** White = MGMT+SALE+COMP+EDUC+HLTH. Blue = CONS+FARM+PROD+TRAN. Services = FOOD+PROT+PERS+BLDG. Share% = bucket / (WC+BC+Services) × 100. R11 gated at each scale.

---

## Section 6 — Safety / Crime

Block Group raw counts from `get_section_data(address, "crime")` → 3×3 grid of raw counts. Hidden cells if null. Per-capita line only if `TOTPOP_CY` at Block returned (R11).

No safety label pill in the hero. No ZIP/City/State crime-index comparison — VestMap's crime endpoint is Block-Group only.

---

## Optional Modules (opt-in only — never rendered by default)

### Natural Hazard Risk (FEMA NRI)
- **Trigger:** "include risk", "FEMA", "hazards"
- **Source:** `search_real_estate_data("National Risk Index")` → Tract FeatureServer
- **Payload:** `RISK_SCORE`, `RISK_RATNG`, `SOVI_SCORE`, `RESL_SCORE`, top 5 hazards by `_RISKS` score. Omit null-rated hazards (R9).
- **Scale:** Tract only.

### Schools
- **Trigger:** "include schools"
- **Source:** `get_section_data(address, "schools")`
- **Payload:** district + 3 nearest schools with rating + URL if returned.

### Education breakdown (5 buckets)
- **Trigger:** "education", "degree attainment"
- **Source:** `query_gis_field` on `NOHS_CY`, `HSGRAD_CY`, `SMCOLL_CY`, `BACHDEG_CY`, `GRADDEG_CY` at `/12 /11 /9 /7`
- **Layout:** 5-segment stacked bar per scale; R11 gated.

### Full Income Distribution (9 HINC buckets)
- **Trigger:** "income distribution", "HINC buckets"
- **Source:** 9 `HINC*_CY` + `TOTHH_CY` at `/12 /11 /9 /7`
- **Layout:** 9-segment stacked bar per scale; R11 gated.

### All 13 occupation buckets
- **Trigger:** "all occupations", "13 occupation buckets"
- **Source:** all 13 `OCC*_CY` at `/12 /11 /9 /7`
- **Layout:** replaces the 4-bar Workforce chart with 13-segment.

### Business / MSA
- **Trigger:** "businesses", "business count"
- **Source:** `N01_BUS`, `N01_EMP` on the MSA FeatureServer (same layer used for the context-band MSA name).
- **Layout:** single-row callout. No scale comparison.

### HPI
- **Trigger:** "HPI", "house price index"
- **Source:** `get_section_data(address, "hpi")` — ~90% reliable.

---

## Block Acquisition — fallback-aware parallel recipe

Field names come from `references/fields-manifest.md`. Do not hardcode
field names here.

### Step 1 — Per-scale safe batch (parallel, single turn)

Fire all of these in parallel:

1. `get_section_data(address, "income")` — Block HHI, home value, forecasted income growth (discovery)
2. `get_section_data(address, "expansion")` — Block pop growth CAGR
3. `get_section_data(address, "crime")` — Block Group crime counts
4. `search_real_estate_data("Metropolitan Statistical Area")` — MSA layer + name field (once per session; cache)
5. `query_gis_field(address, <MSA layer>, ["NAME"])` — MSA name for context band
6. For each of the four scales (`/12 /11 /9 /7`), one `query_gis_field`
   call carrying *every* `demographics_2024` field listed in the manifest
   that's marked queryable at that scale. One call per scale, four
   scales total.

Opt-in modules add their specified queries to the same parallel batch.

### Step 2 — Poison-pill fallback (only when needed)

`query_gis_field` is **all-or-nothing on the field list** — one bad name
or one null value nukes the whole batch with the misleading error
`"No data found at … may be outside this layer's coverage area"`. That
string is **not** a coverage signal. See `SKILL.md §Gotchas`.

If a scale's batch from Step 1 returns "No data found":

1. Re-issue that scale as **one `query_gis_field` call per manifest field,
   in parallel** (a per-field probe). 4-scale × ~20-field worst case
   ≈ 80 probes; VestMap is unlimited, fire them.
2. Drop fields whose probe returns null or "No data found". Keep the
   rest. Never bisect manually.
3. Never surface the failure to chat or to the rendered page (O2).

The fallback runs the same way in custom mode — any time the skill calls
`query_gis_field`, this is the recovery path.

### Step 3 — R9 sweep

Whatever survives Steps 1-2 flows into the template. Null cells get
`display:none`; rows with <2 non-null cells are removed; sections with
<2 rows are removed. No placeholder text anywhere (O2).
