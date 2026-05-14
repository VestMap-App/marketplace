# OM Fields Manifest

Frozen, validated list of every field the **default** OM uses, scoped to
the layer where each field is verified to exist. This file is the source
of truth — `data-spec.md` references it instead of hardcoding field names
inline. Modify the manifest, never inline the spec.

Custom-mode runs (user uploaded a screenshot/OM, or named non-default
fields) are NOT constrained by this manifest. See `SKILL.md §Custom Mode`.

Conventions:
- `tier` follows `vestmap/references/fields.md` (Tier 1 most reliable, higher tiers progressively riskier).
- `scales` lists the layer paths where the field is verified queryable.
- `om_label` is the on-page label.

---

## Layer: `demographics_2024`

Base URL: `…/USA_Demographics_and_Boundaries_2024/MapServer`

Scale paths:

| Scale | Path |
|---|---|
| Block | `/12` |
| Tract | `/11` |
| ZIP | `/9` |
| County | `/7` |

### Population

| Field | Tier | Scales | OM label |
|---|---|---|---|
| `TOTPOP_CY` | 2 | block, tract, zip, county | Total population |
| `MEDAGE_CY` | 3 | block, tract, zip, county | Median age |
| `POPDENS_CY` | 2 | block, tract, zip, county | Density (per sq mi) |
| `AVGHHSZ_CY` | 3 | block, tract, zip, county | Avg household size |

### Income

| Field | Tier | Scales | OM label |
|---|---|---|---|
| `MEDHINC_CY` | 1 | block, tract, zip, county | Median HHI |
| `MEDHINC_FY` | X | block, tract, zip, county | HHI 2029 (forecast) |
| `MHIGRWCYFY` | X | block, tract, zip, county | 5-yr HHI growth |
| `PCI_CY` | 3 | block, tract, zip, county | Per capita income |
| `UNEMPRT_CY` | 2 | block, tract, zip, county | Unemployment rate |
| `EMP_CY` | 1 | block, tract, zip, county | Employed (fallback for unemployment compute) |
| `UNEMP_CY` | 1 | block, tract, zip, county | Unemployed (fallback for unemployment compute) |
| `TOTHH_CY` | 1 | block, tract, zip, county | Total households |

### Housing values

| Field | Tier | Scales | OM label |
|---|---|---|---|
| `MEDVAL_CY` | 2 | block, tract, zip, county | Median home value (County uses `/7`) |
| `MEDVAL_FY` | X | block, tract, zip, county | HV 2029 (forecast) |

### Rental market

| Field | Tier | Scales | OM label |
|---|---|---|---|
| `MEDCRNT_CY` | 2 | block, tract, zip, county | Median rent (canonical — Esri "Median Contract Rent") |
| `RENTER_CY` | 3 | block, tract, zip, county | Renter units |
| `OWNER_CY` | 3 | block, tract, zip, county | Owner units |
| `RENTER_FY` | X | block, tract, zip, county | 2029 renter units |

### Workforce

| Field | Tier | Scales | OM label |
|---|---|---|---|
| `OCCMGMT_CY` | 1 | block, tract, zip, county | Management |
| `OCCSALE_CY` | 1 | block, tract, zip, county | Sales |
| `OCCPROD_CY` | 1 | block, tract, zip, county | Production |
| `OCCCONS_CY` | 1 | block, tract, zip, county | Construction |
| `OCCCOMP_CY` | 1 | block, tract, zip, county | Computer / engineering (collar share) |
| `OCCEDUC_CY` | 1 | block, tract, zip, county | Education / legal (collar share) |
| `OCCHLTH_CY` | 1 | block, tract, zip, county | Healthcare (collar share) |
| `OCCFARM_CY` | 1 | block, tract, zip, county | Farming (collar share) |
| `OCCTRAN_CY` | 1 | block, tract, zip, county | Transportation (collar share) |
| `OCCFOOD_CY` | 1 | block, tract, zip, county | Food svc (collar share) |
| `OCCPROT_CY` | 1 | block, tract, zip, county | Protective svc (collar share) |
| `OCCPERS_CY` | 1 | block, tract, zip, county | Personal svc (collar share) |
| `OCCBLDG_CY` | 1 | block, tract, zip, county | Building / grounds (collar share) |

### Deprecated — do NOT query

| Field | Reason |
|---|---|
| `MEDRENT_CY` | Does not exist on the 2024 service. The canonical name is `MEDCRNT_CY`. Including this in any batched `query_gis_field` call **poisons the entire batch** (all-or-nothing API). See `SKILL.md §Gotchas`. |

---

## Layer: `msa_cbsa`

Base URL: `https://services5.arcgis.com/9fQmObndozAJu9f5/arcgis/rest/services/Enriched_USA_Metropolitan_Statistical_Areas/FeatureServer/0`

Name-field candidates (verify with `search_real_estate_data("Metropolitan Statistical Area")` once per session):

| Field | Status |
|---|---|
| `NAME` | Verified working — returns the full CBSA name string |
| `NAMELSAD` | Fallback |
| `MSA_NAME` | Fallback |

Business-count fields (used only when the user opts into the Business / MSA module):

| Field | OM label |
|---|---|
| `N01_BUS` | Businesses |
| `N01_EMP` | Employees |

---

## Layer: `fema_nri` (opt-in only)

Source: `search_real_estate_data("National Risk Index")` → Tract FeatureServer.

Scale: Tract only.

| Field | OM label |
|---|---|
| `RISK_SCORE` | Risk score |
| `RISK_RATNG` | Risk rating |
| `SOVI_SCORE` | Social vulnerability |
| `RESL_SCORE` | Resilience |
| `<HAZARD>_RISKS` | Per-hazard risk score (top 5 by score) |
| `<HAZARD>_RISKR` | Per-hazard rating |

Per-hazard nulls (e.g., riverine flood on a barrier island) trigger the
poison-pill fallback because the API treats nulls the same as missing
fields. The acquisition recipe handles this automatically — see
`data-spec.md §Block Acquisition`.
