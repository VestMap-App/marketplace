---
name: vestmap-market-area-pages
description: Render the demographic, housing, flood and workforce pages of a narrative appraisal report (the Regional and Market Area Analysis, a Site Description flood-hazard page, the Employment Analysis insert, and Demographic Data Detail addenda) for any US address, as a Letter PDF styled to slot into a USPAP/FIRREA report — navy headings, white pages, source-lined tables, captioned maps, a sample-style trend chart, no branding. Every figure comes from one vintage of 2026 Esri GeoEnrichment read at 1 / 3 / 5-mile rings, county, state and nation (block group, tract and ZIP in a one-page Immediate Area Profile and in the addenda, with the Esri variable codes printed), plus the FEMA National Flood Hazard Layer at the subject. Narrative is formulaic and comparative only; the market-area boundary, rating, conclusions and FIRM panel stay with the appraiser as highlighted draft placeholders. Use when the user asks for "appraisal demographics", "market area analysis pages", "market area section", "neighborhood analysis for an appraisal", "demographic pages for a report", "flood zone page", "employment analysis pages", or a "market area / demographic section" for a property. Not an Offering Memorandum: for an OM, investor page or one-pager use vestmap-om-pages. Self-contained.
user-invocable: true
---

# VestMap Market Area Pages

Generate the pages an appraiser drops into a narrative report: **four body pages for Regional and Market Area Analysis, one Site Description flood-hazard page, one Employment Analysis page, and four addenda pages (map exhibits and data detail)**, for a single US address, as one Letter PDF. The pages are written the way a review appraiser wants them: one data vintage, one source line per table, comparative language chosen by fixed bands, no opinions in data tables, no protected-class data, and the appraiser's own passages left as highlighted placeholders. This file is **self-contained**: the layout, the full HTML/CSS template, the chart, the sentence patterns and the PDF command are all below.

## Hard rules

- **PDF is the default output.** Write the HTML to a temp file, convert with headless Chrome (§PDF), print the PDF path. Output HTML only if the user says "HTML".
- **Every number traces to a VestMap tool call** (`get_radius_demographics` for every demographic figure, `query_gis_field` for the county name and the FEMA flood attributes, `custom_map_screenshot` for the block-group maps, the radius call's own `mapImageUrl` for the ring maps) or to a computation in §Computations over those values. No inference, no memory, no fabrication. A narrative figure is always the same value, formatted the same way, as its table cell.
- **Missing data:** a single missing cell prints `n/a` (never a dash that reads as zero). A row with fewer than two values is dropped. A narrative fragment whose inputs are missing is dropped. Never substitute a value from another scale.
- **One vintage.** Read `blockTractZipVintage` and `radiusVintage` from a call whose first field is a `_CY` code; print that year everywhere the template shows `2026` and the forecast year (`vintage + 5`) wherever it shows `2031`. If the ring and B/T/Z vintages differ, stop and say so once; do not build.
- **No protected-class data and no neighborhood adjectives.** Never request or print race, ethnicity, ancestry, language, nativity, religion, familial status, disability, Tapestry segments, school ratings, livability or walkability scores, or the FEMA NRI *composite* index (its social-vulnerability component carries protected-class inputs). Median age and household size appear as numbers only, with no inference drawn from them. The only comparative language is the §Language table. Market-area life-cycle terms are never generated.
- **Crime, unemployment, education and flood risk are numbers, never maps.** The crime index table lives in the addenda only; no crime, unemployment, education or NRI risk choropleth is ever rendered. The only flood map is the FEMA NFHL zone map (and when it does not render, a FIRMette placeholder).
- **Appraiser passages are placeholders, not prose.** The market-area boundary, which radius approximates it, the favorable/neutral/unfavorable rating, the HAI demand sentence, the conclusions, the FIRM panel and effective date, and the FIRMette exhibit are the appraiser's. In the default **draft** build they print as yellow `[APPRAISER: …]` tags. The user may supply them (§Appraiser inputs); a `final` build strips the `[verify: …]` flags and must not be produced while any `[APPRAISER: …]` tag remains.
- **No VestMap branding on the page.** No logo, no brand colours, no cards or KPI tiles. VestMap appears only in source lines and the Demographic Data Note. The header carries a faint `Firm logo` placeholder left and `{PROJECT} / {SECTION}` right; the footer a `Firm footer` placeholder left and `Page N` right — the firm's template replaces them.
- **Style is locked** to the `<style>` block in §Template: navy `#1F3F6B` headings, table heads and chart columns, light tint `#DCE6F1`, Source Sans 3 (fallback Segoe UI), 10.5pt justified body, 8.5pt tables, captions in bold caps above maps, one single-hue ramp per data category (§Maps). Never restyle per market or per user.
- **Ten fixed pages.** Each `.page` is 8.5×11in with `overflow:hidden`; the template's sizes are tuned so every page lands above the footer rule. If content grows (a long county name, a long project name), shrink that page's map one step (`.mapw.m` 57% → 52%, `.s` 66% → 60%, `.xs` 46% → 40%) rather than letting anything reach the footer.

## Workflow

1. **Parse** the address; note street line, city, state, ZIP. Note the optional **project name** (the report's property name, e.g. "The Stones"; default = the street line) and the **property-type profile**: `multifamily` (default), `retail`, `office`, `industrial`, `land`.
2. **Acquire — fire all of these in parallel in one turn** (VestMap is free and unlimited; never warn about volume): the five `get_radius_demographics` calls and the four `query_gis_field` calls in §Data, and the `custom_map_screenshot` calls in §Maps.
3. **View the maps** and transcribe each legend (§Maps); read the rent map's pattern (§Narrative).
4. **Compute** per §Computations; gate every computation on its inputs.
5. **Fill** the template (§Template) page by page; apply the draft tags and verify flags.
6. **Convert to PDF** (§PDF) as `vestmap-market-area-{zip}-{YYYYMMDD-HHMMSS}.pdf` in the current directory.
7. **Respond** (§Respond).

## Data — five radius calls and four field queries carry every figure

Each `get_radius_demographics` call takes up to 25 codes and returns every field at `fields.<code>.blockTractZip.{block,tract,zip,county,state,national}` and `fields.<code>.radius."1"/"3"/"5".value`. The calls (every code below is validated live on connector 1.8.0-beta.10):

```
address: <the subject address>   — on every call

Call 1 (shadeField "POPDENS_CY" → its mapImageUrl is the Radius Map):
  ["POPDENS_CY","MEDHINC_CY","MEDHINC_FY","MHIGRWCYFY","AVGHINC_CY","PCI_CY","MEDAGE_CY","TOTPOP20","TOTPOP_CY",
   "TOTPOP_FY","POPGRW20CY","POPGRWCYFY","TOTHH_CY","TOTHH_FY","HHGRWCYFY","AVGHHSZ_CY","MEDVAL_CY","MEDCRNT_CY",
   "TOTHU_CY","OWNER_CY","RENTER_CY","VACANT_CY","HAI_CY","income_150k_plus_pct","WLTHINDXCY"]
Call 2 (shadeField "MEDHINC_CY" → its mapImageUrl is the income ring map for the Immediate Area Profile):
  ["MEDHINC_CY","TOTPOP10","TOTHH10","TOTHH20","HHGRW20CY","MEDVAL_FY","INCMORT_CY","DPOP_CY","DPOPWRK_CY","DPOPRES_CY",
   "EMP_CY","UNEMPRT_CY","white_collar_pct","blue_collar_pct","services_pct","bachelors_plus_pct","N01_BUS","N01_EMP",
   "income_under_50k_pct","income_50k_100k_pct","income_100k_150k_pct","CRMCYTOTC","CRMCYPERC","CRMCYPROC"]
Call 3 (industry):
  ["INDBASE_CY","INDAGRI_CY","INDMIN_CY","INDCONS_CY","INDMANU_CY","INDWHTR_CY","INDRTTR_CY","INDTRAN_CY","INDUTIL_CY",
   "INDINFO_CY","INDFIN_CY","INDRE_CY","INDTECH_CY","INDMGMT_CY","INDADMN_CY","INDEDUC_CY","INDHLTH_CY","INDARTS_CY",
   "INDFOOD_CY","INDOTSV_CY","INDPUBL_CY"]
Call 4 (age cohorts):
  ["POP0_CY","POP5_CY","POP10_CY","POP15_CY","POP20_CY","POP25_CY","POP30_CY","POP35_CY","POP40_CY","POP45_CY",
   "POP50_CY","POP55_CY","POP60_CY","POP65_CY","POP70_CY","POP75_CY","POP80_CY","POP85_CY"]
Call 5 (crime detail, addenda only):
  ["CRMCYMURD","CRMCYRAPE","CRMCYROBB","CRMCYASST","CRMCYBURG","CRMCYLARC","CRMCYMVEH"]

query_gis_field(address, "https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer/7", ["NAME"])
  → the county name (the payload carries no place names). Take only NAME from that boundary layer, never a number.
query_gis_field(address, "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28", ["FLD_ZONE","ZONE_SUBTY","SFHA_TF"])
query_gis_field(address, "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28", ["STATIC_BFE","DEPTH","DFIRM_ID"])
  → the FEMA flood zone at the subject's geocoded point (−9999 means not applicable).
query_gis_field(address, "https://services.arcgis.com/XG15cJAlne2vxtgt/arcgis/rest/services/National_Risk_Index_Census_Tracts/FeatureServer/0", ["IFLD_EALR","CFLD_EALR","NRI_VER"])
  → the tract's inland (riverine) and coastal flooding Expected Annual Loss ratings and the NRI release.
```

Field facts:
- `POPGRW20CY` / `HHGRW20CY` are Esri's annual 2020–current rates; `POPGRWCYFY` / `HHGRWCYFY` / `MHIGRWCYFY` the annual current–forecast rates, all already in percent. `POPGRW10CY` and `HHGRW10CY` **do not exist**; 2010–2020 growth is computed (§Computations).
- The call that starts with `TOTPOP20` reports vintage "2020" and one starting with `TOTPOP_FY` reports "2031": the vintage field follows the first code. Read the vintage from Call 1 (first code `POPDENS_CY`).
- Tenure: `OWNER_CY + RENTER_CY + VACANT_CY = TOTHU_CY`, so the three shares of total units sum to 100%. Use total units as the denominator everywhere (not occupied units).
- `MEDCRNT_CY` is top-coded at 3,501 → print `$3,501+` and raise a verify flag. `MEDVAL_CY` is top-coded at 2,000,001 → `$2,000,000+`.
- The lowercase codes are the connector's derived shares, already in percent. The occupation shares equal Esri's 22 `OCC*_CY` groups summed (12 white-collar, 5 service, 5 blue-collar); never request or re-sum `OCC*_CY`.
- **FEMA NFHL.** `FLD_ZONE` (X, A, AE, AO, VE, D …), `ZONE_SUBTY` (FEMA's wording, e.g. "AREA OF MINIMAL FLOOD HAZARD"), `SFHA_TF` ("T"/"F"), `STATIC_BFE` and `DEPTH` (−9999 = not applicable), `DFIRM_ID` (the county study, e.g. "29095C"). **Never query or print the FIRM panel layer** (`NFHL/MapServer/3`): for a subject near a county or state line it returns the neighbouring county's panel, which is exactly the error that gets a report kicked back. The panel number and effective date are the appraiser's, from the FIRMette.
- **FEMA NRI.** The December 2025 release renamed riverine flooding to **inland flooding**: the codes are `IFLD_*` (the catalog's `RFLD_*` fail with "field does not exist"). Print only the Expected Annual Loss rating word (`IFLD_EALR`, and `CFLD_EALR` where it is not "Not Applicable"); never the composite `RISK_SCORE` / `RISK_RATNG`, and never a score as a site-level finding.
- An unknown code fails the whole call and names it: fix the code; never fall back to older layers for a demographic figure. A transport error (not valid JSON, timeout, 502/503) retries once; if Call 1 or 2 still fails there is no page — say so once. If Call 3, 4 or 5 or a flood query fails, drop the table(s) or rows it feeds.
- **Older connector.** If the tool takes only a single `fieldName` or rejects `fieldNames`, build nothing: "These pages need the latest VestMap connector. Install it from app.vestmap.com/mcp, then ask again."

### Scales and labels

| Role | Keys | Column label |
|---|---|---|
| Body tables (six columns + comparison) | `radius.1`, `radius.3`, `radius.5`, `county`, `state`, `national` | `1-Mile` · `3-Mile` · `5-Mile` · `{County Name}` · `{State name}` · `U.S.` · `1-Mile vs. County` |
| Immediate Area Profile | `block`, `radius.1`, `county` | `Block Group` · `1-Mile` · `{County Name}` · `Block Group vs. 1-Mile` |
| Addenda tables (nine columns + code) | `block`, `tract`, `zip`, then the six above | `Block Group` · `Tract` · `ZIP {zip}` · … · `Esri variable` |
| Industry body table | `radius.3`, `county`, `national` | `3-Mile` · `{County Name}` · `U.S.` |
| Crime table | the six body keys | `1-Mile` … `U.S.` · `Esri variable` |

County is shown **in lieu of city and MSA** and every table source line says so. Block group, tract and ZIP never appear in a six-column body table; the block group appears only on the Immediate Area Profile page, with its framing sentence, and in the addenda.

## Computations

- **Annual growth 2010–2020** = `((X20 / X10)^(1/10) − 1) × 100` from the census counts (`TOTPOP10`/`TOTPOP20`, `TOTHH10`/`TOTHH20`), 2dp; the addenda labels it "(calc.)" and names both inputs in the code column. Every other growth rate is Esri's own field.
- **Tenure shares** = `OWNER_CY / TOTHU_CY`, `RENTER_CY / TOTHU_CY`, `VACANT_CY / TOTHU_CY` × 100, 1dp.
- **Land area** (Immediate Area Profile) = `TOTPOP_CY / POPDENS_CY` square miles, 2dp, labelled "(computed)".
- **Age bands** (% of `TOTPOP_CY`, 1dp): Under 20 = POP0+POP5+POP10+POP15 · 20 to 34 = POP20+POP25+POP30 · 35 to 54 = POP35…POP50 · 55 to 64 = POP55+POP60 · 65 and over = POP65…POP85.
- **Industry shares** = `IND*_CY / INDBASE_CY` × 100, 1dp. Body table: rank by the 3-mile share, show the top eight, then "All other industries" (the sum of the rest) and the `INDBASE_CY` count row. Addenda: all twenty, same order.
- **Daytime ÷ resident** = `DPOP_CY / TOTPOP_CY`, 2dp.
- **Legend class** of a value: compare it with the five breaks transcribed from the map (§Maps) and print "in the ${lo}–${hi} class" only when both bounds exist.
- **Comparison bands** (every comparison column and every comparative verb): let d = subject scale − reference scale (1-mile − county in the body; block group − 1-mile on the profile page).
  - *rate* (growth rates, unemployment): in line when |d| ≤ 0.3 pt
  - *share* (tenure, occupation, education, income brackets): in line when |d| ≤ 3.0 pt
  - *money / index* (dollar medians, averages, per capita, HAI, household size, median age, the daytime ratio): in line when |d| ≤ 5% of the reference value
  - *count* (population, households, units, businesses, employees, land area, density): never compared — the cell prints `–`
  - Symbols, navy, one colour: `▲` higher · `▼` lower · `►` in line. Verbs for rates: *exceeds / trails / is in line with*; for medians: *{x.x}% above / below the county median of $Y* or *in line with the county median of $Y* (relative difference 1dp).
- **Tenure pattern** = "predominantly rental" when the 1-mile renter share ≥ 55%, "predominantly owner-occupied" when the owner share ≥ 55%, else "mixed". For the `multifamily` profile it is "consistent with the subject's use" when the renter share ≥ 45%, otherwise "a departure from"; for `land` the same test on the owner share; other profiles omit the clause.
- **HAI sentence** (multifamily only): HAI < 100 → "indicates lower affordability of home ownership than the national benchmark of 100, which supports demand for rental housing"; HAI > 100 → "indicates higher affordability …, which does not add to demand for rental housing"; always followed by the `[APPRAISER: confirm]` tag.
- **Profile closing sentence:** list the non-count profile rows whose band is ▲ as "{a, b and c} are above the 1-mile radius", those ▼ as "{d} is below", then "and the remaining indicators are in line." (or "every indicator is in line with the 1-mile radius." when none differ).
- **Verify flags** (draft build only; listed in the addenda "Draft review flags" box, and the rent flag also beside the figure): `MEDCRNT_CY` = 3,501 at any body scale; 1-mile population < 1,000; any printed growth rate > +5% or < −3%. When none trips, the box says so.
- **Formatting:** counts with thousands separators and no rounding to thousands; dollars to the nearest dollar; percents 1dp; growth rates signed 2dp with a true minus sign (−); indexes whole; household size and the daytime ratio 2dp; median age 1dp. Retrieval date `MM/DD/YYYY` = today. Tables carry "Shares may not sum to 100% due to rounding" where shares appear.

## Narrative — the sentence patterns

Data sentences are third-person factual. Every figure is a table value; omit any fragment whose inputs are missing. `{V}` = vintage, `{FY}` = forecast year.

**Location (page 1).** "The subject is located in {City}, {County Name}, {State name}. According to Esri {V} estimates, the population within one mile of the subject is {TOTPOP_CY 1}, within three miles {3}, and within five miles {5}. {County Name} has an estimated {V} population of {TOTPOP_CY county} and a projected annual growth rate of {POPGRWCYFY county}% through {FY}, compared with {state}% for {State name} and {national}% nationally."

**Market Area Overview (page 1).** First paragraph: the appraiser's boundary passage — `[APPRAISER: define the market area boundaries and the rationale (physical barriers, land-use pattern, competitive properties)]` unless supplied. Then: "The market area described above does not coincide with a census geography. The demographic analysis that follows therefore relies on 1-, 3- and 5-mile radii from the subject, shown on the radius map below, supplemented by county, state and national figures for context. The {best}-mile radius most closely approximates the market area." with `{best}` = 3 unless supplied, followed by `[APPRAISER: confirm which radius best approximates the market area]` when not supplied.

**Immediate Area Profile (page 2), framing paragraph, verbatim:** "The following compares the subject's census block group, the smallest geography for which Esri publishes estimates, with the 1-mile radius used in the Area Comparison. Block-group estimates describe a small population and carry greater estimation error than radius or county figures; they are presented to illustrate the subject's immediate surroundings and are not relied upon for the conclusions in this report. The paired maps shade the same field, median household income, with one set of class breaks: the left panel is the neighbourhood-scale view around the subject, the right panel the same map with the 1-, 3- and 5-mile rings." Then the table, the paired maps, and the closing sentence from §Computations. Nothing else.

**Population and Household Trends (page 3).** "Population within one mile of the subject grew at an annual rate of {POPGRW20CY 1}% between 2020 and {V}, which {exceeds/trails/is in line with} the county rate of {county}%. Esri projects annual growth of {POPGRWCYFY 1}% within one mile through {FY} versus {county}% for the county. Household growth within one mile is projected at {HHGRWCYFY 1}% annually. Average household size within one mile is {AVGHHSZ_CY 1} persons compared with {county} in the county, and median age is {MEDAGE_CY 1} years versus {county}." Stop there — no adjectives about age or size. The chart follows (§Chart).

**Household Income (page 3).** "Median household income within one mile is ${MEDHINC_CY 1}, {median phrase vs county} and {median phrase vs national}. Within three miles the median is ${3}. Esri projects median household income within one mile to grow {MHIGRWCYFY 1}% annually through {FY}. {income_150k_plus_pct 1}% of households within one mile report income of $150,000 or more, compared with {county}% county-wide. The map below shows median household income by census block group; the subject's own block group has a median of ${MEDHINC_CY block}, in the ${lo}–${hi} class."

**Housing Characteristics (page 4).** "Of {TOTHU_CY 1} housing units within one mile, {renter}% are renter-occupied, {owner}% owner-occupied and {vacant}% vacant, compared with {county renter}% renter-occupied in the county. The tenure pattern within one mile is {pattern}, which is {consistent with / a departure from} the subject's use. Median owner-occupied home value within one mile is ${MEDVAL_CY 1} versus ${county} county-wide. The Housing Affordability Index of {HAI_CY 1} within one mile {HAI sentence}. [APPRAISER: confirm]" Multifamily only, after viewing the rent map: " Median contract rent by block group is generally higher to the {direction(s)} of the subject and lower to the {direction(s)}." — pattern only; never the subject block group's rent figure, never a comparison with the subject's rents.

**Outlook and Conclusions (page 4, appraiser voice, template).** "Based on the foregoing, population and household growth in the subject's immediate area {exceeds/trails/is in line with} the county rate, median household income is {above/below/in line with} the county median, and the tenure pattern within one mile is {pattern}. We consider the demographic characteristics of the market area [APPRAISER: favorable / neutral / unfavorable] for {demand noun} demand. [APPRAISER: add market-area life-cycle conclusion, if any, with supporting evidence from permits, vacancy or sale activity, not from demographics alone]" Demand noun by profile: multifamily → "rental housing", retail → "retail", office → "office", industrial → "industrial", land → "residential".

**Flood Zone Data (page 5).** Outside the SFHA: "According to the FEMA National Flood Hazard Layer retrieved on {date}, the subject's location lies in Flood Zone {X}, an {area of minimal flood hazard}, and is not within a Special Flood Hazard Area." Inside: "…lies in Flood Zone {AE}, {description}, and is within a Special Flood Hazard Area, with a base flood elevation of {n} feet NAVD88; flood insurance will be required by a federally regulated lender." Always followed by: "This reflects FEMA's digital mapping at the subject's approximate location, not a flood zone determination; the lender's Standard Flood Hazard Determination governs any flood-insurance requirement. Letters of Map Amendment or Revision may not be reflected. [APPRAISER: confirm against the FIRMette panel and effective date; for sites larger than one acre confirm the zone across the full parcel]". The page ends with the Summary of Salient Facts line: "Flood Zone: {X} – {Area of Minimal Flood Hazard} (FEMA NFHL, retrieved {date}; panel per FIRMette)."

**Workforce Profile (page 6).** "Esri estimates {EMP_CY 3} employed civilian residents within three miles of the subject with a modeled {V} unemployment rate of {UNEMPRT_CY 3}%, versus {county}% for the county; these modeled rates are not directly comparable to Bureau of Labor Statistics rates. White collar occupations account for {white_collar_pct 3}% of employed residents within three miles compared with {county}% county-wide, and {bachelors_plus_pct 3}% of adults 25 and over hold a bachelor's degree or higher versus {county}%. Esri Business Locations data identifies approximately {N01_BUS 3} businesses employing {N01_EMP 3} persons within three miles. The largest industries of resident employment within three miles are {top three: name (share%)}."

### Language

| Use | Never |
|---|---|
| above / below the county median; exceeds / trails; in line with | superior / inferior neighborhood; better / worse area |
| favorable / neutral / unfavorable for {property type} demand (appraiser's placeholder only) | desirable, undesirable, good location, bad area |
| predominantly renter-occupied; predominantly owner-occupied; mixed tenure | transient, unstable, stable |
| projected growth of x% annually | booming, declining, stagnant, up-and-coming, gentrifying, transitional, changing |
| the Esri total crime index is 145 versus 100 nationally (addenda table only) | high-crime, unsafe, dangerous, rough |
| x% of adults hold a bachelor's degree | well-educated, educated workforce |
| median household income is $x | affluent, upscale, low-income area, poor area |
| not within a Special Flood Hazard Area per the NFHL | not in a floodplain; flood insurance is not required; FEMA has determined; no flood risk; the site has never flooded |
| rent is generally higher to the south of the subject | any level of the subject block group's rent; any comparison with the subject's rents |

The governing test: every sentence states a number and names the comparator; no sentence characterises the people who live there.

## Chart — the sample-style trend chart (page 3)

An inline SVG, dual-axis like the charts appraisers already use, built from the four anchors only (never an implied annual series):

- Title "Population Trend Comparison – 1-Mile Radius vs. {County Name}". Category axis: "2010 (Census)", "2020 (Census)", "{V} (Esri est.)", "{FY} (Esri proj.)".
- Navy columns (`.bar`) = 1-mile population at each anchor, value on the cap; the projection column in the tint `#8FA3C4`; the projection span shaded `#F2F2F2` and labelled "Projected". Left axis starts at zero, titled "Population, 1-mile radius", gridlines at clean steps.
- Lines with 4px markers (white ring) on the right axis = compound annual growth rate for the period *ending* at that anchor (2010–20 at 2020, 2020–26 at {V}, {V}–{FY} at {FY}; no 2010 point): blue `#2E75B6` = 1-Mile, orange `#C55A11` = County. Right axis titled "Annual growth rate, period ending (%)" with a drawn zero line; the last point of each line carries its value.
- Legend row under the title: column swatch "Population, 1-mile radius (left axis)", line keys "Annual growth, 1-mile" and "Annual growth, county". No third line (a third hue fails colour-vision checks).
- Source line beneath the box: "Source: U.S. Census 2010 and 2020 counts; Esri {V} estimate and {FY} projection via VestMap. Growth rates are compound annual rates for the period ending in the year shown; the {V}–{FY} rate is Esri's projection."
- The chart supersedes a projected-growth body map; that map goes to the addenda map exhibits.

## Maps — two ring maps, three or four block-group maps, one flood frame

- **Radius Map** (page 1): Call 1's `mapImageUrl`, a 1120×560 JPG of block-group **population density** with the 1 mi (orange), 3 mi (blue) and 5 mi (purple) rings and the pin at centre, legend baked top-right. A count field is useless under rings (block groups hold similar populations), so the shade is always `POPDENS_CY`. Caption "Radius Map – 1-, 3- and 5-Mile Rings from Subject (Population Density by Block Group)"; HTML legend swatches `#F7FAFF #C8DAF0 #6BAFD6 #296FAA #073265`, labels "≤ {b1} · {b1}–{b2} · … · > {b4}" as whole persons per square mile. (The ring map's ramp is the connector's and cannot be set to greys.)
- **Immediate Area Profile pair** (page 2): Call 2's `mapImageUrl` (rings over **median household income**) used twice so both panels share one set of class breaks: the left panel is the same image enlarged 2.4× about its centre (`.zoomw` + `.zoom`, the neighbourhood-scale view), the right panel the full image. One shared HTML legend (`#F7FAFF … #073265`, nearest $1k) between them. Captions "Subject Block Group – Median Household Income, {V} (Neighbourhood Scale)" and "1-Mile Radius – Median Household Income by Block Group, {V}". Never pair two separately classified renders: their breaks differ and the same block group would colour differently.
- **Block-group maps**, each one `custom_map_screenshot` call with `classification_method: "quantile"`, `class_breaks_count: 5`, the subject address, and the ramp for its data category (light = low, dark = high; never red on a demographic map):

| Page | Map | Arguments | Ramp (`colors`) | Caption | HTML legend labels |
|---|---|---|---|---|---|
| 3 | Median household income | `service_url` `https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer/12`, `field_name` `MEDHINC_CY`, `legend_title` `Median HHI` | blues `#eff3ff #bdd7e7 #6baed6 #3182bd #08519c` | "Median Household Income by Block Group, {V}" | `≤ $39k · $39k–$56k · … · > $99k` (nearest $1k) |
| 4 (multifamily only) | Median contract rent | same `service_url`, `field_name` `MEDCRNT_CY`, `legend_title` `Median Rent` | golds `#fff8d6 #fde88f #f5c443 #cf9a1b #8a6508` | "Median Contract Rent by Block Group, {V} (Esri; Rent Paid by Existing Tenants)" | `≤ $845 · $845–$1,069 · … · > $1,554`; a top class ending at 3,501 reads "$x–$3,501+" |
| Addenda | Property-type map — multifamily: `derived_metric` `renter_occupied_pct`, `legend_title` `Renter Share` · retail: `field_name` `DPOP_CY`, `Daytime Pop` · office: `derived_metric` `white_collar_pct`, `White Collar` · industrial: `field_name` `DPOPWRK_CY`, `Daytime Wkrs` · land: `field_name` `MEDVAL_CY`, `Median Value` | purples `#f2f0f7 #cbc9e2 #9e9ac8 #756bb1 #54278f` (tenure, workforce), teals `#edf8fb #b2e2e2 #66c2a4 #2ca25f #006d2c` (home value, daytime counts) | "Renter-Occupied Share of Housing Units by Block Group, {V}" / "Daytime Population …" / "White Collar Share of Employed Residents …" / "Daytime Workers …" / "Median Home Value …" | percents 1dp / counts / dollars |
| Addenda | Projected population growth | same `service_url`, `field_name` `POPGRWCYFY`, `legend_title` `Pop Growth` | greens `#edf8e9 #bae4b3 #74c476 #31a354 #006d2c` | "Projected Annual Population Growth {V}–{FY} by Block Group" | signed 2dp: `≤ −0.44% · −0.44%–−0.22% · … · > +0.50%`; note "classes are cut on the map extent and do not break at zero" |

The reply's **Data year** must read "2026 (Esri GeoEnrichment)" (the vintage year); if it names another year, leave that map out. The baked legend is titled "{year} {legend_title} (Esri GeoEnrichment)"; keep `legend_title` ≤ 12 characters.

- **Flood map** (page 5): attempt once `custom_map_screenshot(address, service_url "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28", field_name "FLD_ZONE", field_type "esriFieldTypeString", legend_title "Flood Zone", colors ["#2b6cb0","#63b3ed","#f6ad55","#e53e3e","#a0aec0","#d4d4d4"])` and retry once on a transport error. On connector 1.8.0-beta.10 this render fails with a server "Failed to execute query" every time; when it fails, the page shows the same 2:1 frame with `[APPRAISER: insert FEMA FIRMette]` and the caption "FEMA Flood Hazard Zones – Vicinity of Subject (National Flood Hazard Layer)". When it renders, its source line is "NFHL retrieved {date}. Context exhibit; not a FIRMette and not a flood zone determination." Never substitute an NRI risk choropleth.
- **Transcribe each legend.** Download the returned image and view it. Read the five rows top→bottom (highest class first) and write the five HTML labels low→high as in the table, using the exact breaks; the image's own legend stays visible, the HTML row is the legible copy. If a legend shows fewer than five rows or two equal adjacent breaks, retry once with identical arguments, then switch to `classification_method: "equal-interval"`. If you cannot view the image, keep the map and omit the HTML legend row and the "in the … class" clauses.
- **Never rendered, regardless of request:** crime, unemployment, educational attainment, NRI risk, any Tapestry or race layer.
- Every demographic map's source line: "Source: Esri Updated Demographics {V}, block groups; map by VestMap. Five quantile classes within the map extent." plus the map's own note. Map images are shown whole (the attribution strip stays), bordered 1.5px navy, at `.mapw.m` 57% width (pages 1 and 3), `.mapw.s` 66% (addenda exhibits) and `.mapw.xs` 46% (the rent map).
- **Transport errors** retry once; a map that still fails is dropped with its caption and legend (the flood frame excepted), nothing else moves.

## Appraiser inputs

The user may supply any of these in the request; each replaces its placeholder tag:

| Input | Replaces |
|---|---|
| "market area: …" | the boundary paragraph |
| "best radius: 1 / 3 / 5" | `{best}` and its confirm tag |
| "rating: favorable / neutral / unfavorable" | the rating tag in the Outlook |
| "conclusions: …" | the life-cycle tag in the Outlook |
| "FIRM panel: 29095C0261G effective 1/20/2017" | the panel row on the flood page |
| "FIRMette: <image path or URL>" | the FIRMette frame |
| "final" | strips `[verify: …]` flags, the Draft review flags box and the Firm logo / footer placeholders; refused while any `[APPRAISER: …]` tag remains ("Final build needs: …") |

## Template — the self-contained pages

Reproduce the `<style>` block **byte-for-byte**; it is the locked style layer. The page skeleton and every table class are shown once below (page 1, real values for 4339 Roanoke Parkway, Kansas City, MO 64111 as markup illustration); pages 2–10 reuse the same elements in the order given in §Pages.

```html
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Market Area Analysis &middot; {{ADDRESS}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
<style>
@page{ size:Letter; margin:0; }
*{ box-sizing:border-box; margin:0; padding:0; }
:root{ --navy:#1F3F6B; --head:#1F3F6B; --tint:#DCE6F1; --sub:#EEF2F7; --ink:#1A1A1A; --muted:#595959; --hair:#D9D9D9; }
html,body{ background:#fff; color:var(--ink); font-family:'Source Sans 3','Segoe UI','Open Sans',Helvetica,Arial,sans-serif;
  font-size:10.5pt; line-height:1.27; -webkit-font-smoothing:antialiased; font-variant-numeric:tabular-nums; }
.page{ width:8.5in; height:11in; padding:0.45in 1in 0.7in; position:relative; overflow:hidden; page-break-after:always; background:#fff; }
.page:last-child{ page-break-after:auto; }
.rh{ display:flex; justify-content:space-between; align-items:flex-end; height:0.45in; margin-bottom:0.18in;
  font-size:8pt; letter-spacing:.05em; text-transform:uppercase; color:#7F7F7F; }
.rh .l{ font-size:7pt; color:#BFBFBF; border:1px dashed #D0D0D0; padding:2px 8px; align-self:center; }
.rh .r{ text-align:right; line-height:1.35; }
.rf{ position:absolute; left:1in; right:1in; bottom:0.4in; border-top:1px solid var(--navy); padding-top:4px;
  display:flex; justify-content:space-between; font-size:8pt; letter-spacing:.05em; text-transform:uppercase; color:#7F7F7F; }
.rf .l{ color:#BFBFBF; }
h1{ font-size:22pt; font-weight:700; color:var(--navy); letter-spacing:-0.01em; line-height:1.15;
  border-bottom:1px solid var(--navy); padding-bottom:3px; margin-bottom:0.07in; }
h2{ font-size:13pt; font-weight:400; color:var(--navy); margin:0.08in 0 0.02in; }
p{ text-align:justify; margin-bottom:5pt; }
.cap{ font-weight:700; font-size:10pt; letter-spacing:.01em; text-transform:uppercase; color:var(--navy); text-align:center; margin:0.07in 0 0.04in; }
.mapw{ margin:0 auto; } .mapw.m{ width:57%; } .mapw.s{ width:66%; } .mapw.xs{ width:46%; }
.mapw .leg{ white-space:nowrap; } .mapw.xs .leg, .mapw.xs .src{ width:150%; margin-left:-25%; }
.map{ display:block; width:100%; border:1.5px solid var(--navy); }
.leg{ display:flex; justify-content:center; gap:0.14in; margin-top:3px; font-size:7.5pt; color:var(--ink); }
.leg .li{ display:inline-flex; align-items:center; gap:4px; } .leg .li i{ width:11px; height:11px; display:inline-block; border:1px solid #777; }
.tt{ font-size:9pt; font-weight:700; color:var(--navy); margin:0.08in 0 2px; }
table{ width:100%; border-collapse:collapse; font-size:8.5pt; }
th{ background:var(--head); color:#fff; font-weight:700; padding:3px 5px; text-align:right; vertical-align:bottom; line-height:1.15; }
th:first-child, td:first-child{ text-align:left; }
td{ padding:2px 5px; text-align:right; vertical-align:middle; }
tbody tr:last-child td{ border-bottom:1px solid var(--navy); }
tr.sub td{ background:var(--sub); font-weight:700; color:var(--navy); padding-top:3px; }
tr.hl td{ background:var(--tint); font-weight:700; }
tr.tot td{ font-weight:700; border-top:1px solid var(--hair); }
table.six th:last-child, table.six td:last-child{ text-align:center; background:var(--tint); width:0.72in; }
table.six th:last-child{ background:var(--head); }
.cmp{ color:var(--navy); font-size:8pt; }
table.nine{ font-size:7.2pt; table-layout:fixed; } table.nine th, table.nine td{ padding:1.5px 3px; overflow:hidden; }
table.nine td:last-child, table.nine th:last-child{ text-align:left; }
.code{ font-family:Menlo,Consolas,monospace; font-size:6.3pt; color:var(--muted); }
.src{ font-size:7.5pt; color:var(--muted); font-style:italic; margin-top:3px; line-height:1.25; }
.note{ font-size:8.5pt; line-height:1.3; margin-top:0.12in; text-align:justify; }
.tag{ background:#FFF2A8; color:#5A4A00; font-style:italic; padding:0 3px; }
.flags{ margin-top:0.12in; font-size:8.5pt; background:#FFF8D6; border:1px solid #E6D37A; padding:5px 8px; }
sup{ font-size:70%; vertical-align:super; line-height:0; }
.chartbox{ border:1.5px solid var(--navy); padding:0.06in 0.1in 0.02in; width:84%; margin:0 auto; }
.tchart{ display:block; width:100%; height:auto; }
.tchart .ct{ font-size:10px; font-weight:700; fill:var(--navy); font-family:inherit; }
.tchart .cl{ font-size:7.5px; fill:var(--ink); font-family:inherit; }
.tchart .cv{ font-size:7.5px; fill:var(--ink); font-family:inherit; }
.tchart .ax{ font-size:7px; fill:var(--muted); font-family:inherit; }
.tchart .bar{ fill:#1F3F6B; }
.tchart .grid{ stroke:#E3E3E3; stroke-width:1; } .tchart .axis{ stroke:#9A9A9A; stroke-width:1; }
.tchart .l1{ stroke:#2E75B6; stroke-width:2; fill:none; stroke-linejoin:round; stroke-linecap:round; }
.tchart .l2{ stroke:#C55A11; stroke-width:2; fill:none; stroke-linejoin:round; stroke-linecap:round; }
.tchart circle.l1{ fill:#2E75B6; stroke:#fff; stroke-width:2; } .tchart circle.l2{ fill:#C55A11; stroke:#fff; stroke-width:2; }
.pair{ display:flex; gap:0.16in; margin-top:0.06in; align-items:flex-start; }
.pair .pc{ flex:1; min-width:0; } .pair .cap{ font-size:8pt; margin:0 0 0.04in; line-height:1.2; height:0.32in; display:flex; align-items:flex-end; justify-content:center; }
.zoomw{ position:relative; width:100%; aspect-ratio:2/1; overflow:hidden; border:1.5px solid var(--navy); }
.zoomw .zoom{ position:absolute; width:240%; height:auto; left:50%; top:50%; transform:translate(-50%,-50%); display:block; }
.frame{ width:100%; aspect-ratio:2/1; border:1.5px solid var(--navy); display:flex; align-items:center; justify-content:center; background:#FAFAFA; }
.tchart .proj{ fill:#F2F2F2; } .tchart .projl{ font-size:7px; fill:var(--muted); font-style:italic; font-family:inherit; }
.tchart .axt{ font-size:7px; fill:var(--muted); font-family:inherit; }
.tchart .bar.tint{ fill:#8FA3C4; }
.tchart .zero{ stroke:#9A9A9A; stroke-width:1; stroke-dasharray:3 2; }
p.after{ margin-top:0.06in; }
table.two td:last-child, table.two th:last-child{ text-align:left; }
</style></head><body>
<div class="page">
  <div class="rh"><div class="l">Firm logo</div><div class="r">The Stones<br/>Regional and Market Area Analysis</div></div>
  
<h1>Regional and Market Area Analysis</h1>
<h2>Location</h2>
<p>The subject is located in Kansas City, Jackson County, Missouri. According to Esri 2026 estimates, the population within one mile of the subject is 22,538, within three miles 114,872, and within five miles 285,006. Jackson County has an estimated 2026 population of 735,484 and a projected annual growth rate of 0.29% through 2031, compared with 0.24% for Missouri and 0.48% nationally.</p>
<h2>Market Area Overview</h2>
<p><span class="tag">[APPRAISER: define the market area boundaries and the rationale (physical barriers, land-use pattern, competitive properties)]</span></p>
<p>The market area described above does not coincide with a census geography. The demographic analysis that follows therefore relies on 1-, 3- and 5-mile radii from the subject, shown on the radius map below, supplemented by county, state and national figures for context. The 3-mile radius most closely approximates the market area. <span class="tag">[APPRAISER: confirm which radius best approximates the market area]</span></p>
<div class="cap">Radius Map &ndash; 1-, 3- and 5-Mile Rings from Subject (Population Density by Block Group)</div><div class="mapw m"><img class="map" src="https://storage.googleapis.com/vestmap-data/maps/radius/1792090377205-gotkc7rllr5.jpg" alt="Radius Map &amp;ndash; 1-, 3- and 5-Mile Rings from Subject (Population Density by Block Group)"/><div class="leg"><span class="li"><i style="background:#F7FAFF"></i>&le; 2,671</span><span class="li"><i style="background:#C8DAF0"></i>2,671&ndash;3,897</span><span class="li"><i style="background:#6BAFD6"></i>3,897&ndash;5,049</span><span class="li"><i style="background:#296FAA"></i>5,049&ndash;7,106</span><span class="li"><i style="background:#073265"></i>&gt; 7,106</span></div><div class="src">Source: Esri Updated Demographics 2026, block groups; map by VestMap. Five quantile classes within the map extent. Persons per square mile. Rings: 1 mile (orange), 3 miles (blue), 5 miles (purple).</div></div>
<div class="tt">Area Comparison &ndash; Demographic Summary</div><table class="six"><colgroup><col style="width:2.6in"/></colgroup><thead><tr><th></th><th>1-Mile</th><th>3-Mile</th><th>5-Mile</th><th>Jackson County</th><th>Missouri</th><th>U.S.</th><th>1-Mile vs. County</th></tr></thead><tbody><tr class=""><td>Population, 2020 Census</td><td>21,032</td><td>111,132</td><td>277,075</td><td>717,204</td><td>6,154,913</td><td>331,449,281</td><td><span class="cmp">&ndash;</span></td></tr><tr class=""><td>Population, 2026 estimate</td><td>22,538</td><td>114,872</td><td>285,006</td><td>735,484</td><td>6,272,929</td><td>343,528,394</td><td><span class="cmp">&ndash;</span></td></tr><tr class=""><td>Population, 2031 projection</td><td>23,412</td><td>117,837</td><td>292,878</td><td>746,347</td><td>6,348,837</td><td>351,813,408</td><td><span class="cmp">&ndash;</span></td></tr><tr class=""><td>Annual population growth, 2020&ndash;2026</td><td>+1.11%</td><td>+0.53%</td><td>+0.45%</td><td>+0.40%</td><td>+0.30%</td><td>+0.57%</td><td><span class="cmp">&#9650;</span></td></tr><tr class="hl"><td>Annual pop. growth, 2026&ndash;2031 (proj.)</td><td>+0.76%</td><td>+0.51%</td><td>+0.55%</td><td>+0.29%</td><td>+0.24%</td><td>+0.48%</td><td><span class="cmp">&#9650;</span></td></tr><tr class=""><td>Households, 2026</td><td>13,365</td><td>56,585</td><td>131,260</td><td>311,216</td><td>2,570,086</td><td>134,397,562</td><td><span class="cmp">&ndash;</span></td></tr><tr class=""><td>Annual HH growth, 2026&ndash;2031 (proj.)</td><td>+0.86%</td><td>+0.76%</td><td>+0.84%</td><td>+0.50%</td><td>+0.40%</td><td>+0.71%</td><td><span class="cmp">&#9650;</span></td></tr><tr class=""><td>Average household size</td><td>1.62</td><td>1.97</td><td>2.11</td><td>2.33</td><td>2.38</td><td>2.49</td><td><span class="cmp">&#9660;</span></td></tr><tr class=""><td>Median age</td><td>34.7</td><td>35.1</td><td>35.8</td><td>38.0</td><td>39.9</td><td>39.6</td><td><span class="cmp">&#9660;</span></td></tr><tr class="hl"><td>Median household income, 2026</td><td>$75,239</td><td>$76,973</td><td>$72,018</td><td>$75,657</td><td>$75,934</td><td>$85,893</td><td><span class="cmp">&#9658;</span></td></tr><tr class=""><td>Median HH income growth, 2026&ndash;2031 (proj.)</td><td>+2.03%</td><td>+2.33%</td><td>+2.52%</td><td>+2.57%</td><td>+2.53%</td><td>+3.10%</td><td><span class="cmp">&#9660;</span></td></tr><tr class=""><td>Per capita income</td><td>$64,274</td><td>$60,056</td><td>$50,048</td><td>$42,747</td><td>$43,159</td><td>$48,241</td><td><span class="cmp">&#9650;</span></td></tr><tr class=""><td>Median home value (owner-occupied)</td><td>$355,027</td><td>$354,320</td><td>$297,062</td><td>$259,003</td><td>$264,642</td><td>$376,272</td><td><span class="cmp">&#9650;</span></td></tr></tbody></table><div class="src">Source: Esri Updated Demographics, 2026 estimates / 2031 projections (2020 Census base), via VestMap, retrieved 10/15/2026. Radius figures are apportioned by Esri from block groups; county shown in lieu of city/MSA. &#9650;&#9660; higher/lower than the county; &#9658; within band (rates &plusmn;0.3 pt, shares &plusmn;3.0 pt, dollars and indexes &plusmn;5%). Direction only, not favorability; counts are not compared.</div>

  <div class="rf"><span class="l">Firm footer</span><span>Page 1</span></div>
</div>
<!-- pages 2–10: a .page each, same .rh header and .rf footer, contents per §Pages -->
</body></html>
```

Element notes:
- `.rh` header: `<div class="l">Firm logo</div>` (dropped in a final build) and `.r` = `{PROJECT}<br/>{SECTION}` where SECTION is "Regional and Market Area Analysis" (pages 1–4), "Site Description" (page 5), "Employment Analysis" (page 6), "Addenda &ndash; Map Exhibits" (page 7), "Addenda &ndash; Demographic Data Detail" (pages 8–10). `.rf` footer: `<span class="l">Firm footer</span>` (dropped in final) and `Page N`.
- Tables: `.tt` title → `<table class="six">` with a `<colgroup><col style="width:2.6in"/></colgroup>` (2.75in for the workforce table), `<thead>` of the column labels, rows `<tr>`/`<tr class="sub">` (group label row) /`<tr class="hl">` (highlighted key row) /`<tr class="tot">` (total row); the last cell of every `.six` row is `<span class="cmp">▲|▼|►|–</span>`. The profile table is a `.six` table with four value columns. Addenda tables are `<table class="nine">` with the eleven `<col>` widths `1.52in, 0.4in ×5, 0.44in ×2, 0.5in, 0.58in, 0.9in` and the code in `<span class="code">`. The industry body table is `<table class="ind">` with a 3.2in first column; the crime table `<table class="six">` with a 2.2in first column and the code as its last cell; the flood table `<table class="two">` (label / value, 3.1in first column). `.src` under every table.
- Maps: `.cap` caption → `<div class="mapw m|s|xs"><img class="map" …/><div class="leg">…</div><div class="src">…</div></div>`; legend items `<span class="li"><i style="background:#…"></i>label</span>`. The profile pair: `<div class="pair"><div class="pc">caption + <div class="zoomw"><img class="zoom" …/></div></div><div class="pc">caption + <img class="map" …/></div></div>` then one `.leg` and one `.src`. The FIRMette placeholder: `<div class="mapw m"><div class="frame">[APPRAISER: insert FEMA FIRMette]</div></div>`.
- Chart: `<div class="chartbox"><svg class="tchart" viewBox="0 0 460 250">…</svg></div>` with the classes `.ct .cl .cv .ax .axt .bar .bar.tint .proj .projl .grid .axis .zero .l1 .l2 .mk` as styled below, then a `.src`.
- Draft tags: `<span class="tag">[APPRAISER: …]</span>` / `<span class="tag">[verify: …]</span>`; the addenda flags box `<div class="flags">`; the data note `<div class="note">`.

### Pages

1. **Regional and Market Area Analysis** — `h1`; `h2` Location + paragraph; `h2` Market Area Overview + boundary paragraph + bridging paragraph; Radius Map (`.mapw.m`); **Table 1 "Area Comparison – Demographic Summary"** (six columns + comparison) rows: Population, 2020 Census (count) · Population, {V} estimate (count) · Population, {FY} projection (count) · Annual population growth, 2020–{V} (rate) · **Annual pop. growth, {V}–{FY} (proj.)** (rate, `.hl`) · Households, {V} (count) · Annual HH growth, {V}–{FY} (proj.) (rate) · Average household size (index) · Median age (index) · **Median household income, {V}** (money, `.hl`) · Median HH income growth, {V}–{FY} (proj.) (rate) · Per capita income (money) · Median home value (owner-occupied) (money) · [retail/office only: Daytime population (count)]. Source: the standard source line + the comparison note.
2. **Immediate Area Profile – Subject Block Group and 1-Mile Radius** — `h2` + the framing paragraph; **table "Subject Block Group vs. 1-Mile Radius"** (Block Group · 1-Mile · {County} · Block Group vs. 1-Mile) rows: Land area (sq. mi., computed) · Population density (per sq. mi.) · Population, {V} · Households, {V} (counts, `–`) · Annual pop. growth, {V}–{FY} (proj.) (rate) · Median age (index) · **Median household income** (money, `.hl`) · Per capita income (money) · Median home value (owner-occupied) (money) · Renter-occupied (% of total units) · Vacant (% of total units) · White collar occupations (% of employed) · Bachelor's degree or higher (% of 25+) (shares). No crime, rent or income growth rows. Source + the note "▲▼ block group higher/lower than the 1-mile radius; ► within band (…). Direction only, not favorability; counts, areas and densities are not compared." Then the paired maps, shared legend and source, and the closing sentence.
3. **Trends and income** — `h2` Population and Household Trends + paragraph; the chart (§Chart) + its source; `h2` Household Income + paragraph; income map (`.mapw.m`).
4. **Housing and outlook** — `h2` Housing Characteristics + paragraph (+ the rent-pattern sentence, multifamily); **Table 2 "Household Income and Housing Profile"**: `.sub` "Households by income, {V}" · Under $50,000 · $50,000–$99,999 · $100,000–$149,999 · $150,000 and over (shares) · `.sub` "Housing, {V}" · Total housing units (count) · Owner-occupied (% of total units) · **Renter-occupied (% of total units)** (`.hl` for multifamily) · Vacant (% of total units) (shares) · Median contract rent, monthly <sup>a</sup> (money; `$3,501+` when top-coded) · [multifamily/land: Housing Affordability Index <sup>b</sup> (index)]. Source + comparison note + rounding note + footnote a "Census-based measure of rent paid by existing tenants; not a measure of current asking rents and not used in the Income Capitalization Approach; top-coded at $3,501." + footnote b "Esri index; 100 means the median household income qualifies for the median-priced home under standard lending ratios; below 100 indicates lower affordability of ownership." Then (multifamily) the rent map (`.mapw.xs`) with, directly beneath it as a `.src`, the verbatim caveat: "Median contract rent is a census-based estimate of rent paid by existing renter households, excluding utilities; it lags current asking rents and includes subsidized and long-term tenancies. It is shown to illustrate the relative rent pattern of the surrounding area and is not used to estimate market rent, which is developed in the Income Capitalization Approach from the rent comparables. Values of $3,501 or more are top-coded." Then `h2` Outlook and Conclusions + template paragraph.
5. **Site Description – Flood Hazard** — `h1`; `h2` Flood Zone Data + paragraph; **table "Flood Hazard"** (label / Subject): FEMA flood zone at subject (NFHL) "Zone {X}" (`.hl`) · Zone description (FEMA's wording in title case) · Special Flood Hazard Area "Yes"/"No" · [SFHA only: Base flood elevation "{n} ft NAVD88" · Flood depth] — never print "Not applicable" rows · FEMA Flood Insurance Study "{DFIRM_ID} ({County}, {ST} and Incorporated Areas)" · FIRM panel / effective date `[APPRAISER: enter from FEMA FIRMette]` · NFHL data retrieved {date} · FEMA NRI riverine flooding, expected annual loss (census tract) "{IFLD_EALR}" (omit when "Not Applicable" or missing) · [coastal row likewise]. Source: "FEMA National Flood Hazard Layer (NFHL) at the subject's geocoded location and FEMA National Risk Index ({NRI_VER} release) for the census tract containing the subject, via VestMap, retrieved {date}. The expected annual loss rating is a tract-level statistic, not a property-level finding." Then the flood map or FIRMette frame, then the Salient Facts line in a `.note`.
6. **Employment Analysis** — `h1`; `h2` "Workforce Profile – Subject Radii (Esri)" + paragraph; **Table 3 "Workforce and Employment Profile"**: Employed civilian population 16+ (count) · **Unemployment rate, {V} (Esri modeled) <sup>c</sup>** (rate, `.hl`) · White collar / Blue collar / Services occupations (% of employed) (shares) · Bachelor's degree or higher (% of population 25+) (share) · Businesses (count) · Employees at those businesses (count) · Daytime population ÷ resident population (index). Source adds "Business and employee counts: Esri Business Locations (Data Axle)." and footnote c "Esri modeled estimate derived from ACS and current-year models; not comparable to the Bureau of Labor Statistics LAUS rates." Then **Table 4 "Share of Employed Residents by Industry, {V}"** (3-Mile · County · U.S.): top eight, All other industries (`.tot`), Employed residents 16+ (count) (`.tot`); source adds "Reflects the industry of employment of residents, not the location of jobs. Industries ranked by 3-mile share."
7. **Addenda – Map Exhibits** — `h1`; the property-type map and the projected-growth map, both `.mapw.s`, with their HTML legends and source lines.
8. **Addenda – Demographic Data Detail** — `h1`; **"Population, Households, Age and Income – All Geographies"** (`.nine`): Population (2010 Census, 2020 Census, {V} estimate, {FY} projection, Annual growth 2010–2020 (calc.), Annual growth 2020–{V}, Annual growth {V}–{FY} (proj.), Pop. density (per sq. mi.), Daytime population, workers, residents) · Households (2010, 2020, {V}, {FY}, the three growth rows, Average household size) · Age, {V} (Median age, the five bands "(% of pop., calc.)") · Income, {V} (Median household income, Median HH income {FY} proj., Median HH income growth {V}–{FY}, Avg. household income, Per capita income, the four HH income bands, Wealth index (U.S. = 100)). Source adds "Computed rows name their inputs. Lowercase shares are computed by VestMap from the Esri variables shown."
9. **"Housing and Workforce – All Geographies"** (`.nine`): Housing (Total housing units, Owner-occupied units, Renter-occupied units, Vacant units, the three "(% of units, calc.)" rows, Median home value (owner-occ.), Median home value {FY} proj., Median contract rent (monthly), Housing Affordability Index, Percent of income for mortgage) · Workforce (Employed civilian pop. 16+, Unemployment rate (Esri modeled), White collar / Blue collar / Services (% of employed), Bachelor's or higher (% of 25+), Businesses (Business Locations), Employees at those businesses). Then **"Crime Index, {V} (U.S. = 100)"** (`.six`, 2.2in first column, code column): Total Crime Index (`.hl`) · Personal Crime Index (`.tot`) · Murder · Rape · Robbery · Assault · Property Crime Index (`.tot`) · Burglary · Larceny · Motor vehicle theft; source "Applied Geographic Solutions CrimeRisk indexes licensed through Esri, via VestMap, retrieved {date}; 100 = national average. Modeled from reported offense data at the block-group level; not a count of incidents at or near the subject."
10. **"Resident Employment by Industry, {V} – All Geographies (share of employed residents 16+)"** (`.nine`, all twenty industries in 3-mile order, then Employed residents 16+ `.tot`; code column = the `IND*_CY` code; source adds "Each share is the variable shown divided by INDBASE_CY."). Then the **Demographic Data Note** (`.note`), the **Scope of Work reference** (`.note`), and in draft builds the **Draft review flags** box.

**Demographic Data Note** (verbatim, with the vintage, forecast year and retrieval date filled): "Demographic, housing, workforce and crime-index figures in this report are {V} current-year estimates and {FY} five-year projections published by Esri (Esri Updated Demographics, 2020 Census base), obtained through VestMap on {date}. Radius figures are apportioned by Esri from block-group estimates and describe the area within the stated distance of the subject, which may not coincide with the market area defined in this report. Esri figures are modeled estimates subject to revision and are not census counts. The Esri unemployment rate is a modeled estimate and is not comparable to Bureau of Labor Statistics data reported in this report. Median contract rent is a census-based measure of rent paid by existing tenants and is not a measure of current asking rents. Crime indexes are Applied Geographic Solutions CrimeRisk indexes licensed through Esri in which 100 represents the national average; they are modeled from reported offense data and are not counts of incidents at the subject. Business and employee counts are from Esri Business Locations (Data Axle). We have relied on these data as published and have not independently verified them; this reliance is subject to the General Assumptions and Limiting Conditions of this report."

**Scope of Work reference:** "Scope of Work reference (add under "Type and Extent of Data Researched"): Esri Updated Demographics ({V} estimates and {FY} projections), Esri Business Locations data and the FEMA National Flood Hazard Layer, obtained through VestMap, a subscription location-data service."

**Standard table source line:** "Source: Esri Updated Demographics, {V} estimates / {FY} projections (2020 Census base), via VestMap, retrieved {MM/DD/YYYY}. Radius figures are apportioned by Esri from block groups; county shown in lieu of city/MSA." **Comparison note** (every `.six` body table): "▲▼ higher/lower than the county; ► within band (rates ±0.3 pt, shares ±3.0 pt, dollars and indexes ±5%). Direction only, not favorability; counts are not compared."

## PDF export

Write the filled HTML to `vestmap-market-area-{zip}-{YYYYMMDD-HHMMSS}.html`, then (macOS; the `perl` alarm stops Chrome once the PDF is written — a non-empty PDF is success regardless of exit code):

```bash
perl -e 'alarm shift @ARGV; exec @ARGV' 50 \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --virtual-time-budget=25000 \
  --user-data-dir="$(mktemp -d)" \
  --print-to-pdf="vestmap-market-area-{zip}-{YYYYMMDD-HHMMSS}.pdf" \
  "file:///ABSOLUTE/PATH/vestmap-market-area-{zip}-{YYYYMMDD-HHMMSS}.html"
```

On Linux use `chromium`/`google-chrome` with the same flags. The budget covers the hosted map images and the webfont. Confirm the PDF has ten pages (`pdfinfo`, or open it); if a page's content reaches its footer rule, shrink that page's map one step and rebuild. Delete the intermediate `.html`. If Chrome is missing, output the HTML and say once that the PDF needs Chrome.

## Respond

Print the PDF path and one sentence naming the address and the profile. In a draft build add one line: "Draft: the yellow [APPRAISER: …] passages (market area boundary, best radius, rating, conclusions, FIRM panel, FIRMette) are yours to fill — send them and say "final" for the clean build." Do not list sections, do not mention dropped rows or maps, do not describe the layout, and do not add any interpretation of the figures.
