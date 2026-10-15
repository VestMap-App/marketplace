---
name: vestmap-market-area-pages
description: Render the demographic, housing, flood and workforce pages of a narrative appraisal report (the Regional and Market Area Analysis, a Site Description flood-hazard page, the Employment Analysis insert, and addenda map exhibits and data detail) for any US address, as a fully generated Letter PDF styled to slot into a USPAP/FIRREA report — navy headings, white pages, source-lined tables, text-width maps, a sample-style trend chart, no branding. Every figure comes from one vintage of 2026 Esri GeoEnrichment read at 1 / 3 / 5-mile rings, county, state and nation (block group, tract and ZIP in a one-page Immediate Area Profile and in the addenda), plus the FEMA National Flood Hazard Layer at the subject. Every comparative statement is produced by a disclosed rule — a density-selected study radius, fixed comparison bands, a six-indicator tally — and the pages open with a Basis of Comparative Statements paragraph; nothing on them is an opinion. Use when the user asks for "appraisal demographics", "market area analysis pages", "market area section", "neighborhood analysis for an appraisal", "demographic pages for a report", "flood zone page", "employment analysis pages", or a "market area / demographic section" for a property. Not an Offering Memorandum: for an OM, investor page or one-pager use vestmap-om-pages. Self-contained.
user-invocable: true
---

# VestMap Market Area Pages

Generate the pages an appraiser drops into a narrative report: **five body pages for Regional and Market Area Analysis, one page that closes with the Summary of Demographic Indicators and opens the Site Description flood-hazard block, one Employment Analysis page, and four addenda pages (map exhibits and data detail)** — eleven Letter pages for a single US address, as one PDF. Nothing is left for the appraiser to fill in: every sentence is a published figure, the arithmetic result of a rule stated on the page, or a standing caveat. This file is **self-contained**: the layout, the full HTML/CSS template, the chart, the rules, the sentence patterns and the PDF command are all below.

## Hard rules

- **PDF is the default output.** Write the HTML to a temp file, convert with headless Chrome (§PDF), print the PDF path. Output HTML only if the user says "HTML".
- **Every number traces to a VestMap tool call** (`get_radius_demographics` for every demographic figure, `query_gis_field` for the county name and the FEMA flood attributes, `custom_map_screenshot` for the block-group maps, the radius calls' own `mapImageUrl` for the ring maps) or to a computation in §Computations over those values. No inference, no memory, no fabrication. A narrative figure is always the same value, formatted the same way, as its table cell.
- **Nothing is an opinion.** No "we" or "our" anywhere. No rating of demand, marketability, value or neighbourhood quality; no market-area life-cycle stage; no "favorable"; no "market area" defined by the page (it is a "Demographic Study Area" chosen by the density rule). The only comparative language is the §Language table, and every comparison is one of the disclosed rules. The page opens with the Basis of Comparative Statements paragraph (§Narrative) that says so.
- **Missing data:** a single missing cell prints `n/a` (never a dash that reads as zero). A row with fewer than two values is dropped. A narrative fragment whose inputs are missing is dropped. An indicator whose inputs are missing leaves the tally (the sentence then says "of {n} indicators"). Never substitute a value from another scale.
- **One vintage.** Read `blockTractZipVintage` and `radiusVintage` from a call whose first field is a `_CY` code; print that year everywhere the template shows `2026` and the forecast year (`vintage + 5`) wherever it shows `2031`. If the ring and B/T/Z vintages differ, stop and say so once; do not build.
- **No protected-class data and no neighborhood adjectives.** Never request or print race, ethnicity, ancestry, language, nativity, religion, familial status, disability, Tapestry segments, school ratings, livability or walkability scores, or the FEMA NRI *composite* index (its social-vulnerability component carries protected-class inputs). Median age and household size appear as numbers only, with no inference drawn from them.
- **Crime, unemployment, education and flood risk are numbers, never maps.** The crime index table lives in the addenda only; no crime, unemployment, education or NRI risk choropleth is ever rendered. The only flood exhibit is the FEMA NFHL zone map, when it renders.
- **No VestMap branding on the page.** No logo, no brand colours, no cards or KPI tiles. VestMap appears only in source lines, the Basis paragraph and the Demographic Data Note. The header carries a faint `Firm logo` placeholder left and `{PROJECT} / {SECTION}` right; the footer a `Firm footer` placeholder left and `Page N` right — the firm's template replaces them. A `final` build drops the two placeholders and the draft flags box.
- **Style is locked** to the `<style>` block in §Template: navy `#1F3F6B` headings, table heads and chart columns, light tint `#DCE6F1`, Source Sans 3 (fallback Segoe UI), 10.5pt justified body, 8.5pt tables, captions in bold caps above maps, maps at the text width (or the stated fraction of it), one single-hue ramp per data category (§Maps). Never restyle per market or per user.
- **Eleven fixed pages.** Each `.page` is 8.5×11in with `overflow:hidden`; the template's sizes are tuned so every page lands above the footer rule. If content grows (a long county name, a long project name), shrink that page's map one step (`.mapw.rad` 72% → 64%, `.inc` 80% → 72%, `.rent` 68% → 60%, `.m`/`.s` 100% → 90%) rather than letting anything reach the footer.

## Workflow

1. **Parse** the address; note street line, city, state, ZIP. Note the optional **project name** (the report's property name, e.g. "The Stones"; default = the street line) and the **property-type profile**: `multifamily` (default), `retail`, `office`, `industrial`, `land`.
2. **Acquire — fire all of these in parallel in one turn** (VestMap is free and unlimited; never warn about volume): the five `get_radius_demographics` calls and the four `query_gis_field` calls in §Data, and the `custom_map_screenshot` calls in §Maps.
3. **View the maps** and transcribe each legend (§Maps); read the rent map's pattern (§Narrative).
4. **Compute** per §Computations — the primary study radius first, because every comparison column and most sentences depend on it; gate every computation on its inputs.
5. **Fill** the template (§Template) page by page.
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
  ["MEDHINC_CY","TOTPOP10","TOTHH10","TOTHH20","HHGRW20CY","TOTHU10","TOTHU20","MEDVAL_FY","INCMORT_CY","DPOP_CY",
   "DPOPWRK_CY","DPOPRES_CY","EMP_CY","UNEMPRT_CY","white_collar_pct","blue_collar_pct","services_pct",
   "bachelors_plus_pct","N01_BUS","N01_EMP","income_under_50k_pct","income_50k_100k_pct","income_100k_150k_pct",
   "CRMCYTOTC","CRMCYPERC"]
Call 3 (industry):
  ["INDBASE_CY","INDAGRI_CY","INDMIN_CY","INDCONS_CY","INDMANU_CY","INDWHTR_CY","INDRTTR_CY","INDTRAN_CY","INDUTIL_CY",
   "INDINFO_CY","INDFIN_CY","INDRE_CY","INDTECH_CY","INDMGMT_CY","INDADMN_CY","INDEDUC_CY","INDHLTH_CY","INDARTS_CY",
   "INDFOOD_CY","INDOTSV_CY","INDPUBL_CY"]
Call 4 (age cohorts):
  ["POP0_CY","POP5_CY","POP10_CY","POP15_CY","POP20_CY","POP25_CY","POP30_CY","POP35_CY","POP40_CY","POP45_CY",
   "POP50_CY","POP55_CY","POP60_CY","POP65_CY","POP70_CY","POP75_CY","POP80_CY","POP85_CY"]
Call 5 (crime detail, addenda only):
  ["CRMCYPROC","CRMCYMURD","CRMCYRAPE","CRMCYROBB","CRMCYASST","CRMCYBURG","CRMCYLARC","CRMCYMVEH"]

query_gis_field(address, "https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer/7", ["NAME"])
  → the county name (the payload carries no place names). Take only NAME from that boundary layer, never a number.
query_gis_field(address, "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28", ["FLD_ZONE","ZONE_SUBTY","SFHA_TF"])
query_gis_field(address, "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28", ["STATIC_BFE","DEPTH","DFIRM_ID"])
  → the FEMA flood zone at the subject's geocoded point (−9999 means not applicable).
query_gis_field(address, "https://services.arcgis.com/XG15cJAlne2vxtgt/arcgis/rest/services/National_Risk_Index_Census_Tracts/FeatureServer/0", ["IFLD_EALR","CFLD_EALR","NRI_VER"])
  → the tract's inland (riverine) and coastal flooding Expected Annual Loss ratings and the NRI release.
```

Field facts:
- `POPGRW20CY` / `HHGRW20CY` are Esri's annual 2020–current rates; `POPGRWCYFY` / `HHGRWCYFY` / `MHIGRWCYFY` the annual current–forecast rates, all already in percent. `POPGRW10CY` and `HHGRW10CY` **do not exist**; 2010–2020 growth and housing-unit growth are computed (§Computations).
- The call that starts with `TOTPOP20` reports vintage "2020" and one starting with `TOTPOP_FY` reports "2031": the vintage field follows the first code. Read the vintage from Call 1 (first code `POPDENS_CY`).
- Tenure: `OWNER_CY + RENTER_CY + VACANT_CY = TOTHU_CY`, so the three shares of total units sum to 100%. Use total units as the denominator everywhere (not occupied units).
- `MEDCRNT_CY` is top-coded at 3,501 → print `$3,501+` and raise a verify flag. `MEDVAL_CY` is top-coded at 2,000,001 → `$2,000,000+`.
- The lowercase codes are the connector's derived shares, already in percent. The occupation shares equal Esri's 22 `OCC*_CY` groups summed (12 white-collar, 5 service, 5 blue-collar); never request or re-sum `OCC*_CY`.
- **FEMA NFHL.** `FLD_ZONE` (X, A, AE, AO, VE, D …), `ZONE_SUBTY` (FEMA's wording, e.g. "AREA OF MINIMAL FLOOD HAZARD"), `SFHA_TF` ("T"/"F"), `STATIC_BFE` and `DEPTH` (−9999 = not applicable), `DFIRM_ID` (the county study, e.g. "29095C"). **Never query or print the FIRM panel layer** (`NFHL/MapServer/3`): for a subject near a county or state line it returns the neighbouring county's panel. The panel number and effective date come only from the FEMA FIRMette, which the page says should accompany the report.
- **FEMA NRI.** The December 2025 release renamed riverine flooding to **inland flooding**: the codes are `IFLD_*` (the catalog's `RFLD_*` fail with "field does not exist"). Print only the Expected Annual Loss rating word (`IFLD_EALR`, and `CFLD_EALR` where it is not "Not Applicable"); never the composite `RISK_SCORE` / `RISK_RATNG`, never a score as a site-level finding.
- An unknown code fails the whole call and names it: fix the code; never fall back to older layers for a demographic figure. A transport error (not valid JSON, timeout, 502/503) retries once; if Call 1 or 2 still fails there is no page — say so once. If Call 3, 4 or 5 or a flood query fails, drop the table(s) or rows it feeds.
- **Older connector.** If the tool takes only a single `fieldName` or rejects `fieldNames`, build nothing: "These pages need the latest VestMap connector. Install it from app.vestmap.com/mcp, then ask again."

### Scales and labels

| Role | Keys | Column label |
|---|---|---|
| Body tables (six columns + comparison) | `radius.1`, `radius.3`, `radius.5`, `county`, `state`, `national` | `1-Mile` · `3-Mile` · `5-Mile` · `{County Name}` · `{State name}` · `U.S.` · `{Primary} vs. County` |
| Immediate Area Profile | `block`, `radius.1`, `county` | `Block Group` · `1-Mile` · `{County Name}` · `Block Group vs. 1-Mile` |
| Addenda tables (nine columns) | `block`, `tract`, `zip`, then the six above | `Block Group` · `Tract` · `ZIP {zip}` · … · `U.S.` |
| Industry body table | the primary radius, `county`, `national` | `{Primary}` · `{County Name}` · `U.S.` |
| Indicator Summary | `block` (shown only), `radius.1`, the primary radius (or `radius.3` when the primary is 1 mile), `county` | `Block Group` · `1-Mile` · `{R2}` · `{County Name}` · three "vs. Co." columns · `Rings agree` |
| Crime table | the six body keys | `1-Mile` … `U.S.` |

`{Primary}` is the study radius chosen in §Computations (`1-Mile`, `3-Mile` or `5-Mile`). County is shown **in lieu of city and MSA** and every table source line says so. Block group, tract and ZIP never appear in a six-column body table; the block group appears only on the Immediate Area Profile page, with its framing sentence, and in the addenda. The addenda carry no Esri variable codes.

## Computations

- **Primary study radius** (compute first). 1-mile density = `TOTPOP_CY (1-mile) / 3.1416` persons per square mile (not Esri's `POPDENS_CY`, and never the block group). Rule: ≥ 10,000 → 1 mile; 2,500–9,999 → 3 miles; < 2,500 → 5 miles; if the selected ring holds fewer than 5,000 persons, step up one ring. The result is `{Primary}` (`1-Mile` / `3-Mile` / `5-Mile`, "one / three / five miles" in prose). It drives every body comparison column, the Indicator Summary, the chart, the workforce and industry tables and every narrative figure except the Location paragraph (all three rings) and the Immediate Area Profile (always 1 mile).
- **Annual growth 2010–2020** = `((X20 / X10)^(1/10) − 1) × 100` from the census counts (`TOTPOP10`/`TOTPOP20`, `TOTHH10`/`TOTHH20`), 2dp; the addenda labels it "(calc.)". **Housing-unit growth** = `((TOTHU_CY / TOTHU20)^(1/(V−2020)) − 1) × 100` at the primary radius. Every other growth rate is Esri's own field.
- **Tenure shares** = `OWNER_CY / TOTHU_CY`, `RENTER_CY / TOTHU_CY`, `VACANT_CY / TOTHU_CY` × 100, 1dp.
- **Land area** (Immediate Area Profile) = `TOTPOP_CY / POPDENS_CY` square miles, 2dp, labelled "(computed)".
- **Age bands** (% of `TOTPOP_CY`, 1dp): Under 20 = POP0+POP5+POP10+POP15 · 20 to 34 = POP20+POP25+POP30 · 35 to 54 = POP35…POP50 · 55 to 64 = POP55+POP60 · 65 and over = POP65…POP85.
- **Industry shares** = `IND*_CY / INDBASE_CY` × 100, 1dp. Body table: rank by the primary-radius share, show the top eight, then "All other industries" (the sum of the rest) and the `INDBASE_CY` count row. Addenda: all twenty, same order.
- **Daytime ÷ resident** = `DPOP_CY / TOTPOP_CY`, 2dp.
- **Legend class** of a value: compare it with the five breaks transcribed from the map (§Maps) and print "in the ${lo}–${hi} class" only when both bounds exist.
- **Comparison bands** (every comparison column, the Indicator Summary and every comparative verb): let d = subject scale − reference scale (primary radius − county in the body; block group − 1-mile on the profile page).
  - *rate* (growth rates, unemployment): in line when |d| ≤ 0.3 pt
  - *share* (tenure, occupation, education, income brackets): in line when |d| ≤ 3.0 pt
  - *money / index* (dollar medians, averages, per capita, HAI, household size, median age, the daytime ratio): in line when |d| ≤ 5% of the reference value
  - *count* (population, households, units, businesses, employees, land area, density): never compared — the cell prints `–`
  - Symbols, navy, one colour: `▲` higher · `▼` lower · `►` in line. Verbs for rates: *exceeds / trails / is in line with*; for medians: *{x.x}% above / below the county median of $Y* or *in line with the county median of $Y* (relative difference 1dp).
- **Indicator Summary** (six rows, equal weight, the bands above, computed **separately at two ring scales**: the 1-mile radius and the primary radius, or the 3-mile radius when the primary is 1 mile): projected annual population growth {V}–{FY} (rate) · projected annual household growth (rate) · median household income (money) · projected annual median HH income growth (rate) · unemployment rate (rate; **lower counts as "Exceeds"**) · the profile row: multifamily → renter-occupied share of housing units (share); land → owner-occupied share (share); retail/office/industrial → daytime population ÷ resident population (index). For each indicator and scale the result against the county is ▲ exceeds, ▼ trails or ► in line; "Rings agree" is Consistent when the two ring results match, else Mixed. **The block group is shown, never counted:** its value and its own ▲▼► against the county are printed for comparison, except unemployment and projected income growth, which print `n/a` at the block group (noise at that size); block-group agreement with the 1-mile radius is reported as a count out of the four reported indicators. Per scale, count E, T, I: if I ≥ 4 → "in line with"; else E > T → "above"; T > E → "below"; E = T → "in line with". Combine: identical verdicts → one statement "at both scales", naming the indicators on which the scales differ; different verdicts → report both and name the differing indicators, with no single statement. Adding scales makes the summary more robust (a sensitivity test of the radius), not more exact; say nothing that implies otherwise. When the user gives the subject's unit count, add "The subject's {n} units represent approximately {x}% of the {TOTHH_CY block} households in its block group."
- **Tenure pattern** = "predominantly rental" when the primary-radius renter share ≥ 55%, "predominantly owner-occupied" when the owner share ≥ 55%, else "mixed". For `multifamily` it is "consistent with the subject's use" when the renter share ≥ 45%, otherwise "a departure from"; for `land` the same test on the owner share; other profiles omit the clause.
- **Profile closing sentence:** list the non-count profile rows whose band is ▲ as "{a, b and c} are above the 1-mile radius", those ▼ as "{d} is below", then "and the remaining indicators are in line." (or "every indicator is in line with the 1-mile radius." when none differ).
- **Verify flags** (draft build only; listed in the addenda "Draft review flags" box): `MEDCRNT_CY` = 3,501 at any body scale; 1-mile population < 1,000; any printed growth rate > +5% or < −3%. When none trips, the box says so.
- **Formatting:** counts with thousands separators and no rounding to thousands; dollars to the nearest dollar; percents 1dp; growth rates signed 2dp with a true minus sign (−); indexes whole; household size and the daytime ratio 2dp; median age 1dp; density whole. Retrieval date `MM/DD/YYYY` = today. Tables carry "Shares may not sum to 100% due to rounding" where shares appear. Number words for the tally: none, one, two … six.

## Narrative — the sentence patterns

Data sentences are third-person factual; never "we". Every figure is a table value; omit any fragment whose inputs are missing. `{V}` = vintage, `{FY}` = forecast year, `{P}` = the primary radius in prose ("three miles"), `{PL}` = its label ("3-Mile").

**Basis of Comparative Statements (page 1, directly under the section title, in a `.note.basis` block, verbatim with the fields filled):** "The figures in this section and the related addenda are published estimates and projections of Esri ({V} estimates, {FY} projections, 2020 Census base) and mapping data of the Federal Emergency Management Agency, obtained through VestMap on {date}. Statements comparing one geography with another, the selection of the study radius, and the Indicator Summary are generated by VestMap from those figures by fixed rules stated where each appears: comparison bands of ±0.3 percentage points for rates, ±3.0 points for shares and ±5% for dollar amounts and indexes; a study radius selected from 1-mile population density; and an equal-weight count of six indicators computed separately at the 1-mile radius and the primary study radius, with agreement between the two scales reported, the subject's census block group being shown for comparison and excluded from the counts. These statements are arithmetic summaries of the data, involve no judgment, and can be reproduced by any reader from the Esri estimates listed in the Addenda. They are not opinions of value, marketability, demand or neighbourhood quality. The appraiser has reviewed these pages and is responsible for their inclusion in this report. The appraiser's own analysis, reasoning and conclusions regarding the market area, demand for the subject property and highest and best use are stated in the appraiser's words in the Market Analysis, Highest and Best Use and Reconciliation sections and are not derived from the Indicator Summary."

**Location (page 1).** "The subject is located in {City}, {County Name}, {State name}. According to Esri {V} estimates, the population within one mile of the subject is {TOTPOP_CY 1}, within three miles {3}, and within five miles {5}. {County Name} has an estimated {V} population of {TOTPOP_CY county} and a projected annual growth rate of {POPGRWCYFY county}% through {FY}, compared with {state}% for {State name} and {national}% nationally."

**Demographic Study Area (page 1), two paragraphs.** "For the demographic analysis in this section the study area is the area within {P} of the subject, selected by the density rule stated below, with the other radii, {County Name}, {State name} and the United States shown for context. The study area lies in {County Name} and is centred on ZIP code {zip}; it contains an estimated {TOTPOP_CY P} persons and {TOTHH_CY P} households (Esri {V}). It is a radial proxy: it does not follow streets, physical barriers, political boundaries or the competitive supply of {demand noun}, which are addressed, where applicable, in the Market Analysis." Then: "The study radius is selected by a fixed rule from 1-mile population density: 1 mile at 10,000 persons per square mile or more, 3 miles from 2,500 to 9,999, and 5 miles below 2,500, stepping up one ring where the selected ring holds fewer than 5,000 persons. The 1-mile density here is {density} persons per square mile; the {n}-mile radius is therefore the primary study area, and the comparison column in each table measures it against {County Name}. The thresholds are VestMap conventions for classifying urban form and are not a definition of the subject's market area." Demand noun by profile: multifamily → "rental housing", retail → "retail", office → "office", industrial → "industrial", land → "residential". (A list of the ZIP codes the ring crosses would need ring geometry the connector does not return; name only the subject's ZIP.)

**Immediate Area Profile (page 2), framing paragraph, verbatim:** "The following compares the subject's census block group, the smallest geography for which Esri publishes estimates, with the 1-mile radius shown in the Area Comparison. Block-group estimates describe a small population and carry greater estimation error than radius or county figures; they are presented to illustrate the subject's immediate surroundings and are not relied upon for the conclusions in this report. The paired maps on the following page shade the same field, median household income, with one set of class breaks: the upper panel is the neighbourhood-scale view around the subject, the lower panel the same map with the 1-, 3- and 5-mile rings." Then the table and the closing sentence from §Computations. Nothing else.

**Population and Household Trends (page 4).** "Population within {P} of the subject grew at an annual rate of {POPGRW20CY P}% between 2020 and {V}, which {exceeds/trails/is in line with} the county rate of {county}%. Esri projects annual growth of {POPGRWCYFY P}% within {P} through {FY} versus {county}% for the county. Household growth within {P} is projected at {HHGRWCYFY P}% annually. Average household size within {P} is {AVGHHSZ_CY P} persons compared with {county} in the county, and median age is {MEDAGE_CY P} years versus {county}." Stop there. The chart follows (§Chart).

**Household Income (page 4).** "Median household income within {P} is ${MEDHINC_CY P}, {median phrase vs county} and {median phrase vs national}. Within {other ring A} the median is ${A} and within {other ring B} ${B}. Esri projects median household income within {P} to grow {MHIGRWCYFY P}% annually through {FY}. {income_150k_plus_pct P}% of households within {P} report income of $150,000 or more, compared with {county}% county-wide. The map below shows median household income by census block group; the subject's own block group has a median of ${MEDHINC_CY block}, in the ${lo}–${hi} class."

**Housing Characteristics (page 5).** "Of {TOTHU_CY P} housing units within {P}, {renter}% are renter-occupied, {owner}% owner-occupied and {vacant}% vacant, compared with {county renter}% renter-occupied in the county. The tenure pattern within {P} is {pattern}, which is {consistent with / a departure from} the subject's use. Median owner-occupied home value within {P} is ${MEDVAL_CY P} versus ${county} county-wide. Housing units within {P} increased from {TOTHU20 P} in 2020 to {TOTHU_CY P} in {V} (Esri), an annual rate of {signed}%; this is a census-based count of units and is not a measure of permits or construction activity. The Housing Affordability Index within {P} is {HAI_CY P}. Esri sets 100 at the level at which the median household income qualifies for the median-priced home under standard lending ratios; values below 100 indicate that the median household would not qualify for the median-priced home." (HAI sentences for multifamily and land only; no demand clause, ever.) Multifamily only, after viewing the rent map: " Median contract rent by block group is generally higher to the {direction(s)} of the subject and lower to the {direction(s)}." — pattern only; never the subject block group's rent figure, never a comparison with the subject's rents.

**Summary of Demographic Indicators (page 6).** The Indicator Summary table (columns Indicator · Block Group · 1-Mile · {R2} · {County} · BG vs. Co. · 1-Mile vs. Co. · {R2} vs. Co. · Rings agree; `{R2}` = the primary radius, or 3-Mile when the primary is 1 mile), whose source line ends with the caveat: "The on-balance statements are equal-weight counts of the comparisons shown, computed separately at each radius. Agreement between scales indicates that the comparison is not sensitive to the radius chosen; disagreement indicates that it is, and the reader should give weight to the radius that best corresponds to the subject's competitive area. Block-group figures describe a small population with greater estimation error and, for larger properties, may consist substantially of the subject's own residents; they are shown for comparison and are excluded from the counts." Then one of three sentences:
  - *Verdicts agree (above or below):* "Of six indicators compared with {County Name}, {four} exceed the county at the 1-mile scale and {five} at the {3-mile} scale; the demographic indicators are, on balance, above the county at both scales. The two scales agree on {five} of six indicators and differ on {tenure}." ("trail" wording for below.)
  - *Both in line:* "At both the 1-mile and {3-mile} scales, at least four of six indicators fall within the stated bands of {County Name}; the demographic indicators are, on balance, in line with the county at both scales."
  - *Verdicts differ:* "Of six indicators compared with {County Name}, the 1-mile radius exceeds the county on {four}, trails on {one} and is in line on {one}, while the {3-mile} radius exceeds on {two}, trails on {none} and is in line on {four}. The indicators are, on balance, above the county at the 1-mile scale and in line with the county at the {3-mile} scale; the result depends on the radius considered and no single on-balance statement is made. The scales differ on {projected population growth, median household income and projected income growth}."
  Always followed by: "The subject's block group agrees with the 1-mile radius on {n} of the {four} indicators reported at that geography." Indicator short names for the "differ on" list: projected population growth · projected household growth · median household income · projected income growth · unemployment · tenure (or "the daytime population ratio"). Number words: none, one … six; singular verbs for one.

**Flood Zone Data (page 6).** Outside the SFHA: "According to the FEMA National Flood Hazard Layer retrieved on {date}, the subject's location lies in Flood Zone {X}, an {area of minimal flood hazard}, and is not within a Special Flood Hazard Area." Inside: "…lies in Flood Zone {AE}, {description}, and is within a Special Flood Hazard Area, with a base flood elevation of {n} feet NAVD88; flood insurance will be required by a federally regulated lender." Always followed by: "The FEMA FIRMette for the subject, which identifies the effective FIRM panel and date, is the exhibit of record for flood zone and should accompany this report." The table's source line ends with the standing caveat: "The flood zone above is read from the FEMA National Flood Hazard Layer at the subject's approximate location on {date}. It is not a flood zone determination, does not identify the effective FIRM panel, and may not reflect Letters of Map Amendment or Revision; the lender's Standard Flood Hazard Determination governs any flood insurance requirement. Where a site exceeds one acre, or a Special Flood Hazard Area lies within 250 feet of the subject point, the zone may vary across the parcel." The page ends with the Summary of Salient Facts line: "Flood Zone: {X} – {Area of Minimal Flood Hazard} (FEMA NFHL, retrieved {date}; panel per FIRMette)."

**Workforce Profile (page 7).** "Esri estimates {EMP_CY P} employed civilian residents within {P} of the subject with a modeled {V} unemployment rate of {UNEMPRT_CY P}%, versus {county}% for the county; these modeled rates are not directly comparable to Bureau of Labor Statistics rates. White collar occupations account for {white_collar_pct P}% of employed residents within {P} compared with {county}% county-wide, and {bachelors_plus_pct P}% of adults 25 and over hold a bachelor's degree or higher versus {county}%. Esri Business Locations data identifies approximately {N01_BUS P} businesses employing {N01_EMP P} persons within {P}. The largest industries of resident employment within {P} are {top three: name (share%)}."

### Language

| Use | Never |
|---|---|
| above / below the county median; exceeds / trails; in line with; on balance above / below / in line with the county | superior / inferior neighborhood; better / worse area; favorable / unfavorable; demand |
| predominantly renter-occupied; predominantly owner-occupied; mixed tenure | transient, unstable, stable |
| projected growth of x% annually | booming, declining, stagnant, up-and-coming, gentrifying, transitional, changing, life cycle, revitalization |
| the Esri total crime index is 145 versus 100 nationally (addenda table only) | high-crime, unsafe, dangerous, rough |
| x% of adults hold a bachelor's degree | well-educated, educated workforce |
| median household income is $x | affluent, upscale, low-income area, poor area |
| not within a Special Flood Hazard Area per the NFHL | not in a floodplain; flood insurance is not required; FEMA has determined; no flood risk; the site has never flooded |
| rent is generally higher to the south of the subject | any level of the subject block group's rent; any comparison with the subject's rents |
| the demographic study area; the primary study radius | the market area (as something the page defines) |

The governing test: every sentence states a number and names the comparator, or states the rule that produced it; no sentence characterises the people who live there and no sentence is an opinion.

## Chart — the sample-style trend chart (page 4)

An inline SVG, dual-axis like the charts appraisers already use, built from the four anchors only (never an implied annual series), at the primary radius:

- Title "Population Trend Comparison – {PL} Radius vs. {County Name}". Category axis: "2010 (Census)", "2020 (Census)", "{V} (Esri est.)", "{FY} (Esri proj.)".
- Navy columns (`.bar`) = primary-radius population at each anchor, value on the cap; the projection column in the tint `#8FA3C4`; the projection span shaded `#F2F2F2` and labelled "Projected". Left axis starts at zero, titled "Population, {pl} radius", gridlines at clean steps.
- Lines with 4px markers (white ring) on the right axis = compound annual growth rate for the period *ending* at that anchor (2010–20 at 2020, 2020–26 at {V}, {V}–{FY} at {FY}; no 2010 point): blue `#2E75B6` = the primary radius, orange `#C55A11` = County. Right axis titled "Annual growth rate, period ending (%)" with a drawn zero line; the last point of each line carries its value.
- Legend row under the title: column swatch "Population, {pl} radius (left axis)", line keys "Annual growth, {pl}" and "Annual growth, county". No third line (a third hue fails colour-vision checks).
- Source line beneath the box: "Source: U.S. Census 2010 and 2020 counts; Esri {V} estimate and {FY} projection via VestMap, {pl} radius. Growth rates are compound annual rates for the period ending in the year shown; the {V}–{FY} rate is Esri's projection."
- The chart supersedes a projected-growth body map; that map goes to the addenda map exhibits.

## Maps — two ring maps, three or four block-group maps

- **Radius Map** (page 1, `.mapw.rad` 72%): Call 1's `mapImageUrl`, a 1120×560 JPG of block-group **population density** with the 1 mi (orange), 3 mi (blue) and 5 mi (purple) rings and the pin at centre, legend baked top-right. A count field is useless under rings (block groups hold similar populations), so the shade is always `POPDENS_CY`. Caption "Radius Map – 1-, 3- and 5-Mile Rings from Subject (Population Density by Block Group)"; HTML legend swatches `#F7FAFF #C8DAF0 #6BAFD6 #296FAA #073265`, labels "≤ {b1} · {b1}–{b2} · … · > {b4}" as whole persons per square mile. (The ring map's ramp is the connector's and cannot be set to greys.)
- **Immediate Area Profile pair** (page 3, both at the text width, stacked): Call 2's `mapImageUrl` (rings over **median household income**) used twice so both panels share one set of class breaks: the upper panel is the same image enlarged 2.4× about its centre (`.zoomw` + `.zoom`, aspect 2.2:1, the neighbourhood-scale view), the lower panel the full image. One shared HTML legend (`#F7FAFF … #073265`, nearest $1k) beneath. Captions "Subject Block Group – Median Household Income, {V} (Neighbourhood Scale)" and "1-Mile Radius – Median Household Income by Block Group, {V}". Never pair two separately classified renders: their breaks differ and the same block group would colour differently.
- **Block-group maps**, each one `custom_map_screenshot` call with `classification_method: "quantile"`, `class_breaks_count: 5`, the subject address, and the ramp for its data category (light = low, dark = high; never red on a demographic map):

| Page | Map | Arguments | Ramp (`colors`) | Caption | HTML legend labels |
|---|---|---|---|---|---|
| 4 (`.mapw.inc` 80%) | Median household income | `service_url` `https://demographics5.arcgis.com/arcgis/rest/services/USA_Demographics_and_Boundaries_2024/MapServer/12`, `field_name` `MEDHINC_CY`, `legend_title` `Median HHI` | blues `#eff3ff #bdd7e7 #6baed6 #3182bd #08519c` | "Median Household Income by Block Group, {V}" | `≤ $39k · $39k–$56k · … · > $99k` (nearest $1k) |
| 5 (`.mapw.rent` 68%, multifamily only) | Median contract rent | same `service_url`, `field_name` `MEDCRNT_CY`, `legend_title` `Median Rent` | golds `#fff8d6 #fde88f #f5c443 #cf9a1b #8a6508` | "Median Contract Rent by Block Group, {V} (Esri; Rent Paid by Existing Tenants)" | `≤ $845 · $845–$1,069 · … · > $1,554`; a top class ending at 3,501 reads "$x–$3,501+" |
| 8 (`.mapw.s` 100%) | Property-type map — multifamily: `derived_metric` `renter_occupied_pct`, `legend_title` `Renter Share` · retail: `field_name` `DPOP_CY`, `Daytime Pop` · office: `derived_metric` `white_collar_pct`, `White Collar` · industrial: `field_name` `DPOPWRK_CY`, `Daytime Wkrs` · land: `field_name` `MEDVAL_CY`, `Median Value` | purples `#f2f0f7 #cbc9e2 #9e9ac8 #756bb1 #54278f` (tenure, workforce), teals `#edf8fb #b2e2e2 #66c2a4 #2ca25f #006d2c` (home value, daytime counts) | "Renter-Occupied Share of Housing Units by Block Group, {V}" / "Daytime Population …" / "White Collar Share of Employed Residents …" / "Daytime Workers …" / "Median Home Value …" | percents 1dp / counts / dollars |
| 8 (`.mapw.s` 100%) | Projected population growth | same `service_url`, `field_name` `POPGRWCYFY`, `legend_title` `Pop Growth` | greens `#edf8e9 #bae4b3 #74c476 #31a354 #006d2c` | "Projected Annual Population Growth {V}–{FY} by Block Group" | signed 2dp: `≤ −0.44% · −0.44%–−0.22% · … · > +0.50%`; note "classes are cut on the map extent and do not break at zero" |

The reply's **Data year** must read "2026 (Esri GeoEnrichment)" (the vintage year); if it names another year, leave that map out. The baked legend is titled "{year} {legend_title} (Esri GeoEnrichment)"; keep `legend_title` ≤ 12 characters.

- **Flood map** (page 6): attempt once `custom_map_screenshot(address, service_url "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28", field_name "FLD_ZONE", field_type "esriFieldTypeString", legend_title "Flood Zone", colors ["#2b6cb0","#63b3ed","#f6ad55","#e53e3e","#a0aec0","#d4d4d4"])` and retry once on a transport error. On connector 1.8.0-beta.10 this render fails with a server "Failed to execute query" every time; when it fails, the flood block stands alone (no frame, no placeholder) and the narrative's FIRMette sentence carries. When it renders, place it full width with the caption "FEMA Flood Hazard Zones – Vicinity of Subject (National Flood Hazard Layer)" and the source line "NFHL retrieved {date}. Context exhibit; not a FIRMette and not a flood zone determination." Never substitute an NRI risk choropleth.
- **Transcribe each legend.** Download the returned image and view it. Read the five rows top→bottom (highest class first) and write the five HTML labels low→high as in the table, using the exact breaks; the image's own legend stays visible, the HTML row is the legible copy. If a legend shows fewer than five rows or two equal adjacent breaks, retry once with identical arguments, then switch to `classification_method: "equal-interval"`. If you cannot view the image, keep the map and omit the HTML legend row and the "in the … class" clauses.
- **Never rendered, regardless of request:** crime, unemployment, educational attainment, NRI risk, any Tapestry or race layer.
- Every demographic map's source line: "Source: Esri Updated Demographics {V}, block groups; map by VestMap. Five quantile classes within the map extent." plus the map's own note. Map images are shown whole (the attribution strip stays), bordered 1.5px navy, at the width stated for each.
- **Transport errors** retry once; a map that still fails is dropped with its caption and legend, nothing else moves.

## Template — the self-contained pages

Reproduce the `<style>` block **byte-for-byte**; it is the locked style layer. The page skeleton and every table class are shown once below (page 1, real values for 4339 Roanoke Parkway, Kansas City, MO 64111 as markup illustration); pages 2–11 reuse the same elements in the order given in §Pages.

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
.mapw{ margin:0 auto; } .mapw.m{ width:100%; } .mapw.s{ width:100%; } .mapw.xs{ width:84%; }
.mapw .leg{ white-space:nowrap; }
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
table.six.plain th:last-child, table.six.plain td:last-child{ text-align:right; background:transparent; width:auto; }
table.six.plain th:last-child{ background:var(--head); }
table.indic{ font-size:7.8pt; table-layout:fixed; } table.indic td, table.indic th{ padding:2px 3px; }
table.indic td:first-child{ white-space:normal; } table.indic td:last-child, table.indic th:last-child{ text-align:center; }
.cmp{ color:var(--navy); font-size:8pt; }
table.nine{ font-size:7.2pt; table-layout:fixed; } table.nine th, table.nine td{ padding:1.5px 3px; overflow:hidden; }
.code{ font-family:Menlo,Consolas,monospace; font-size:6.3pt; color:var(--muted); }
.src{ font-size:7.5pt; color:var(--muted); font-style:italic; margin-top:3px; line-height:1.25; }
.note{ font-size:8.5pt; line-height:1.3; margin-top:0.12in; text-align:justify; }
.tag{ background:#FFF2A8; color:#5A4A00; font-style:italic; padding:0 3px; }
.flags{ margin-top:0.12in; font-size:8.5pt; background:#FFF8D6; border:1px solid #E6D37A; padding:5px 8px; }
sup{ font-size:70%; vertical-align:super; line-height:0; }
.chartbox{ border:1.5px solid var(--navy); padding:0.06in 0.1in 0.02in; width:84%; margin:0 auto; }
.mapw.inc{ width:80%; } .mapw.rent{ width:68%; } .mapw.rad{ width:72%; }
.note.basis{ margin:0.04in 0 0.02in; font-size:8.5pt; line-height:1.28; }
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
.zoomw{ position:relative; width:100%; aspect-ratio:2.2/1; overflow:hidden; border:1.5px solid var(--navy); }
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
<div class="note basis"><b>Basis of Comparative Statements.</b> The figures in this section and the related addenda are published estimates and projections of Esri (2026 estimates, 2031 projections, 2020 Census base) and mapping data of the Federal Emergency Management Agency, obtained through VestMap on 10/15/2026. Statements comparing one geography with another, the selection of the study radius, and the Indicator Summary are generated by VestMap from those figures by fixed rules stated where each appears: comparison bands of &plusmn;0.3 percentage points for rates, &plusmn;3.0 points for shares and &plusmn;5% for dollar amounts and indexes; a study radius selected from 1-mile population density; and an equal-weight count of six indicators computed separately at the 1-mile radius and the primary study radius, with agreement between the two scales reported, the subject&rsquo;s census block group being shown for comparison and excluded from the counts. These statements are arithmetic summaries of the data, involve no judgment, and can be reproduced by any reader from the Esri estimates listed in the Addenda. They are not opinions of value, marketability, demand or neighbourhood quality. The appraiser has reviewed these pages and is responsible for their inclusion in this report. The appraiser&rsquo;s own analysis, reasoning and conclusions regarding the market area, demand for the subject property and highest and best use are stated in the appraiser&rsquo;s words in the Market Analysis, Highest and Best Use and Reconciliation sections and are not derived from the Indicator Summary.</div>
<h2>Location</h2>
<p>The subject is located in Kansas City, Jackson County, Missouri. According to Esri 2026 estimates, the population within one mile of the subject is 22,538, within three miles 114,872, and within five miles 285,006. Jackson County has an estimated 2026 population of 735,484 and a projected annual growth rate of 0.29% through 2031, compared with 0.24% for Missouri and 0.48% nationally.</p>
<h2>Demographic Study Area</h2>
<p>For the demographic analysis in this section the study area is the area within three miles of the subject, selected by the density rule stated below, with the other radii, Jackson County, Missouri and the United States shown for context. The study area lies in Jackson County and is centred on ZIP code 64111; it contains an estimated 114,872 persons and 56,585 households (Esri 2026). It is a radial proxy: it does not follow streets, physical barriers, political boundaries or the competitive supply of rental housing, which are addressed, where applicable, in the Market Analysis.</p>
<p>The study radius is selected by a fixed rule from 1-mile population density: 1 mile at 10,000 persons per square mile or more, 3 miles from 2,500 to 9,999, and 5 miles below 2,500, stepping up one ring where the selected ring holds fewer than 5,000 persons. The 1-mile density here is 7,174 persons per square mile; the 3-mile radius is therefore the primary study area, and the comparison column in each table measures it against Jackson County. The thresholds are VestMap conventions for classifying urban form and are not a definition of the subject&rsquo;s market area.</p>
<div class="cap">Radius Map &ndash; 1-, 3- and 5-Mile Rings from Subject (Population Density by Block Group)</div><div class="mapw rad"><img class="map" src="https://storage.googleapis.com/vestmap-data/maps/radius/1792090377205-gotkc7rllr5.jpg" alt="Radius Map &amp;ndash; 1-, 3- and 5-Mile Rings from Subject (Population Density by Block Group)"/><div class="leg"><span class="li"><i style="background:#F7FAFF"></i>&le; 2,671</span><span class="li"><i style="background:#C8DAF0"></i>2,671&ndash;3,897</span><span class="li"><i style="background:#6BAFD6"></i>3,897&ndash;5,049</span><span class="li"><i style="background:#296FAA"></i>5,049&ndash;7,106</span><span class="li"><i style="background:#073265"></i>&gt; 7,106</span></div><div class="src">Source: Esri Updated Demographics 2026, block groups; map by VestMap. Five quantile classes within the map extent. Persons per square mile. Rings: 1 mile (orange), 3 miles (blue), 5 miles (purple).</div></div>

  <div class="rf"><span class="l">Firm footer</span><span>Page 1</span></div>
</div>
<!-- pages 2–11: a .page each, same .rh header and .rf footer, contents per §Pages -->
</body></html>
```

Element notes:
- `.rh` header: `<div class="l">Firm logo</div>` (dropped in a final build) and `.r` = `{PROJECT}<br/>{SECTION}` where SECTION is "Regional and Market Area Analysis" (pages 1–5), "Site Description" (page 6), "Employment Analysis" (page 7), "Addenda &ndash; Map Exhibits" (page 8), "Addenda &ndash; Demographic Data Detail" (pages 9–11). `.rf` footer: `<span class="l">Firm footer</span>` (dropped in final) and `Page N`.
- Tables: `.tt` title → `<table class="six">` with a `<colgroup><col style="width:2.6in"/></colgroup>` (2.75in for the workforce table), `<thead>` of the column labels, rows `<tr>`/`<tr class="sub">` (group label row) /`<tr class="hl">` (highlighted key row) /`<tr class="tot">` (total row); the last cell of every `.six` row is `<span class="cmp">▲|▼|►|–</span>`. The profile table is a `.six` table with four value columns; the Indicator Summary and the crime table are `<table class="six plain">` (no tinted last column). Addenda tables are `<table class="nine">` with the ten `<col>` widths `1.9in, 0.42in ×5, 0.47in ×2, 0.55in, 0.62in`. The industry body table is `<table class="ind">` with a 3.2in first column; the flood table `<table class="two">` (label / value, 3.1in first column). `.src` under every table.
- Maps: `.cap` caption → `<div class="mapw m|s|inc|rent|rad"><img class="map" …/><div class="leg">…</div><div class="src">…</div></div>`; legend items `<span class="li"><i style="background:#…"></i>label</span>`. The profile pair: `.cap` + `<div class="zoomw"><img class="zoom" …/></div>`, then `.cap` + `<img class="map" …/>`, then one `.leg` and one `.src`.
- Chart: `<div class="chartbox"><svg class="tchart" viewBox="0 0 460 250">…</svg></div>` with the classes `.ct .cl .cv .ax .axt .bar .bar.tint .proj .projl .grid .axis .zero .l1 .l2 .mk` as styled below, then a `.src`.
- The Basis paragraph is `<div class="note basis">`; the data note and the Salient Facts line are `<div class="note">`; the draft flags box `<div class="flags">`; verify flags `<span class="tag">[verify: …]</span>`.

### Pages

1. **Regional and Market Area Analysis** — `h1`; the Basis of Comparative Statements block; `h2` Location + paragraph; `h2` Demographic Study Area + its two paragraphs; Radius Map (`.mapw.rad`).
2. **Table 1 and the profile** — **Table 1 "Area Comparison – Demographic Summary"** (six columns + "{Primary} vs. County") rows: Population, 2020 Census (count) · Population, {V} estimate (count) · Population, {FY} projection (count) · Annual population growth, 2020–{V} (rate) · **Annual pop. growth, {V}–{FY} (proj.)** (rate, `.hl`) · Households, {V} (count) · Annual HH growth, {V}–{FY} (proj.) (rate) · Average household size (index) · Median age (index) · **Median household income, {V}** (money, `.hl`) · Median HH income growth, {V}–{FY} (proj.) (rate) · Per capita income (money) · Median home value (owner-occupied) (money) · [retail/office only: Daytime population (count)]; source = the standard source line + the comparison note. Then `h2` "Immediate Area Profile – Subject Block Group and 1-Mile Radius" + the framing paragraph; **table "Subject Block Group vs. 1-Mile Radius"** (Block Group · 1-Mile · {County} · Block Group vs. 1-Mile) rows: Land area (sq. mi., computed) · Population density (per sq. mi.) · Population, {V} · Households, {V} (counts, `–`) · Annual pop. growth, {V}–{FY} (proj.) (rate) · Median age (index) · **Median household income** (money, `.hl`) · Per capita income (money) · Median home value (owner-occupied) (money) · Renter-occupied (% of total units) · Vacant (% of total units) · White collar occupations (% of employed) · Bachelor's degree or higher (% of 25+) (shares); source + the note "▲▼ block group higher/lower than the 1-mile radius; ► within band (…). Direction only, not favorability; counts, areas and densities are not compared."; then the closing sentence.
3. **Profile maps** — the neighbourhood-scale panel, the ring panel, the shared legend and source line.
4. **Trends and income** — `h2` Population and Household Trends + paragraph; the chart (§Chart) + its source; `h2` Household Income + paragraph; income map (`.mapw.inc`).
5. **Housing** — `h2` Housing Characteristics + paragraph (+ the rent-pattern sentence, multifamily); **Table 2 "Household Income and Housing Profile"**: `.sub` "Households by income, {V}" · Under $50,000 · $50,000–$99,999 · $100,000–$149,999 · $150,000 and over (shares) · `.sub` "Housing, {V}" · Total housing units (count) · Owner-occupied (% of total units) · **Renter-occupied (% of total units)** (`.hl` for multifamily) · Vacant (% of total units) (shares) · Median contract rent, monthly <sup>a</sup> (money; `$3,501+` when top-coded) · [multifamily/land: Housing Affordability Index <sup>b</sup> (index)]. Source + comparison note + rounding note + footnote a "Census-based measure of rent paid by existing tenants; not a measure of current asking rents and not used in the Income Capitalization Approach; top-coded at $3,501." + footnote b "Esri index; 100 means the median household income qualifies for the median-priced home under standard lending ratios; below 100 indicates lower affordability of ownership." Then (multifamily) the rent map (`.mapw.rent`) with, directly beneath it as a `.src`, the verbatim caveat: "Median contract rent is a census-based estimate of rent paid by existing renter households, excluding utilities; it lags current asking rents and includes subsidized and long-term tenancies. It is shown to illustrate the relative rent pattern of the surrounding area and is not used to estimate market rent, which is developed in the Income Capitalization Approach from the rent comparables. Values of $3,501 or more are top-coded."
6. **Summary and flood** — `h2` Summary of Demographic Indicators; **"Indicator Summary – 1-Mile and {R2} Radius vs. County, with the Subject Block Group for Comparison"** (`<table class="six plain indic">`, nine `<col>` widths `2.0in, 0.56in ×4, 0.44in ×3, 0.66in`) with the six rows of §Computations (block-group `n/a` for unemployment and projected income growth), source "Computed by VestMap from Tables 1–3 and the Immediate Area Profile by the rule stated in the Basis of Comparative Statements: ±0.3 pt for rates, ±3.0 pt for shares, ±5% for dollar figures and indexes; ▲ exceeds, ▼ trails, ► in line with the county; "Consistent" when the two ring scales give the same result." + the caveat; then the tally sentence and the block-group agreement sentence. Then `h1` "Site Description – Flood Hazard"; `h2` Flood Zone Data + paragraph; **table "Flood Hazard"** (label / Subject): FEMA flood zone at subject (NFHL) "Zone {X}" (`.hl`) · Zone description (FEMA's wording in title case) · Special Flood Hazard Area "Yes"/"No" · [SFHA only: Base flood elevation "{n} ft NAVD88" · Flood depth] — never print "Not applicable" rows · FEMA Flood Insurance Study (DFIRM ID) "{DFIRM_ID} – {County}, {ST} and Incorporated Areas" · NFHL data retrieved {date} · FEMA NRI riverine flooding, expected annual loss (census tract) "{IFLD_EALR}" (omit when "Not Applicable" or missing) · [coastal row likewise]. Source: "FEMA National Flood Hazard Layer (NFHL) at the subject's geocoded location and FEMA National Risk Index ({NRI_VER} release) for the census tract containing the subject, via VestMap, retrieved {date}. The expected annual loss rating is a tract-level statistic, not a property-level finding." + the standing caveat. Then the flood map when it rendered, then the Salient Facts line in a `.note`.
7. **Employment Analysis** — `h1`; `h2` "Workforce Profile – Subject Radii (Esri)" + paragraph; **Table 3 "Workforce and Employment Profile"**: Employed civilian population 16+ (count) · **Unemployment rate, {V} (Esri modeled) <sup>c</sup>** (rate, `.hl`) · White collar / Blue collar / Services occupations (% of employed) (shares) · Bachelor's degree or higher (% of population 25+) (share) · Businesses (count) · Employees at those businesses (count) · Daytime population ÷ resident population (index). Source adds "Business and employee counts: Esri Business Locations (Data Axle)." and footnote c "Esri modeled estimate derived from ACS and current-year models; not comparable to the Bureau of Labor Statistics LAUS rates." Then **Table 4 "Share of Employed Residents by Industry, {V}"** ({Primary} · County · U.S.): top eight, All other industries (`.tot`), Employed residents 16+ (count) (`.tot`); source adds "Reflects the industry of employment of residents, not the location of jobs. Industries ranked by {primary} share."
8. **Addenda – Map Exhibits** — `h1`; the property-type map and the projected-growth map, both `.mapw.s`, with their HTML legends and source lines.
9. **Addenda – Demographic Data Detail** — `h1`; **"Population, Households, Age and Income – All Geographies"** (`.nine`): Population (2010 Census, 2020 Census, {V} estimate, {FY} projection, Annual growth 2010–2020 (calc.), Annual growth 2020–{V}, Annual growth {V}–{FY} (proj.), Pop. density (per sq. mi.), Daytime population, workers, residents) · Households (2010, 2020, {V}, {FY}, the three growth rows, Average household size) · Age, {V} (Median age, the five bands "(% of pop., calc.)") · Income, {V} (Median household income, Median HH income {FY} proj., Median HH income growth {V}–{FY}, Avg. household income, Per capita income, the four HH income bands, Wealth index (U.S. = 100)). Source adds "Rows marked (calc.) and the percentage shares are computed by VestMap from the Esri estimates shown."
10. **"Housing and Workforce – All Geographies"** (`.nine`): Housing (Total housing units, Owner-occupied units, Renter-occupied units, Vacant units, the three "(% of units, calc.)" rows, Median home value (owner-occ.), Median home value {FY} proj., Median contract rent (monthly), Housing Affordability Index, Percent of income for mortgage) · Workforce (Employed civilian pop. 16+, Unemployment rate (Esri modeled), White collar / Blue collar / Services (% of employed), Bachelor's or higher (% of 25+), Businesses (Business Locations), Employees at those businesses). Then **"Crime Index, {V} (U.S. = 100)"** (`.six.plain`, 2.2in first column): Total Crime Index (`.hl`) · Personal Crime Index (`.tot`) · Murder · Rape · Robbery · Assault · Property Crime Index (`.tot`) · Burglary · Larceny · Motor vehicle theft; source "Applied Geographic Solutions CrimeRisk indexes licensed through Esri, via VestMap, retrieved {date}; 100 = national average. Modeled from reported offense data at the block-group level; not a count of incidents at or near the subject."
11. **"Resident Employment by Industry, {V} – All Geographies (share of employed residents 16+)"** (`.nine`, all twenty industries in primary-radius order, then Employed residents 16+ `.tot`; source adds "Shares of employed civilian residents 16+. Reflects the industry of employment of residents, not the location of jobs."). Then the **Demographic Data Note** (`.note`), the **Scope of Work reference** (`.note`), and in draft builds the **Draft review flags** box.

**Demographic Data Note** (verbatim, with the vintage, forecast year and retrieval date filled): "Demographic, housing, workforce and crime-index figures in this report are {V} current-year estimates and {FY} five-year projections published by Esri (Esri Updated Demographics, 2020 Census base), obtained through VestMap on {date}. Radius figures are apportioned by Esri from block-group estimates and describe the area within the stated distance of the subject, which may not coincide with the market area defined in this report. Esri figures are modeled estimates subject to revision and are not census counts. The Esri unemployment rate is a modeled estimate and is not comparable to Bureau of Labor Statistics data reported in this report. Median contract rent is a census-based measure of rent paid by existing tenants and is not a measure of current asking rents. Crime indexes are Applied Geographic Solutions CrimeRisk indexes licensed through Esri in which 100 represents the national average; they are modeled from reported offense data and are not counts of incidents at the subject. Business and employee counts are from Esri Business Locations (Data Axle). These data are relied upon as published and have not been independently verified; this reliance is subject to the General Assumptions and Limiting Conditions of this report."

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

On Linux use `chromium`/`google-chrome` with the same flags. The budget covers the hosted map images and the webfont. Confirm the PDF has eleven pages (`pdfinfo`, or open it); if a page's content reaches its footer rule, shrink that page's map one step and rebuild. Delete the intermediate `.html`. If Chrome is missing, output the HTML and say once that the PDF needs Chrome.

## Respond

Print the PDF path and one sentence naming the address, the profile and the primary study radius the density rule selected. Say "final" builds drop the Firm logo / Firm footer placeholders and the draft flags box. Do not list sections, do not mention dropped rows or maps, do not describe the layout, and do not add any interpretation of the figures.
