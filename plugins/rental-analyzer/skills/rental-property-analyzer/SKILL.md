---
name: rental-property-analyzer
description: Build an investor-grade rental-property pro forma from a rent roll + T12 (trailing-12 income statement) + loan/purchase terms. Produces BOTH an editable Excel model (Current vs. Proforma columns — itemized income/expenses, NOI, financing, cap rate, DSCR, cash-on-cash, free cash flow per door, live loan amortization, multi-year projection) AND a polished PDF report with a KPI dashboard and income/expense/projection charts. Use whenever someone wants to analyze, underwrite, or evaluate a rental property or real-estate deal — single-family, duplex, multifamily, or mixed-use/commercial — or asks for a "pro forma", "rental analysis", "deal analysis", "underwrite this", "cash flow / cap rate / NOI / DSCR / cash-on-cash", a "BRRRR" or "buy-and-hold" model, or to turn a rent roll and T12 into numbers. Inputs are a rent roll, a T12, and loan/purchase terms; if the user lacks them, the skill guides them to get them from the brokerage rather than fabricating numbers. Standalone — no external API or MCP required.
user-invocable: true
---

# Rental Property Analyzer

Turn a property's **rent roll + T12 + loan/purchase terms** into an investor-grade pro forma,
delivered two ways from one computed model:

1. **An editable Excel workbook** (`*-proforma.xlsx`) — live formulas, **Current vs. Proforma**
   columns, itemized income/expense, NOI, financing, returns (cap rate, DSCR, cash-on-cash, free
   cash flow per door), a live loan-amortization sheet, and a multi-year projection. The analyst
   can change any assumption and everything recalculates.
2. **A polished PDF report** (`*-proforma.pdf`) — a KPI dashboard, income/expense pie charts, a
   projection chart, the Current-vs-Proforma table, a financing summary, and a long-term
   equity/value projection page.

The numbers are computed **once** by the builder script; the workbook writes live formulas and the
PDF draws the computed values, so the two always agree.

**This file is self-contained.** The builder (§Builder), the Excel dump helper (§Excel dump helper),
the JSON data model (§Data model), the T12 mapping guide (§T12 mapping) and a runnable sample
(§Sample model) are all below. There are no `scripts/` or `references/` files to look for: write the
two scripts from their blocks when you need them.

## When to use

Trigger whenever the user wants to analyze / underwrite / evaluate a **rental property or deal**:
"pro forma", "rental analysis", "deal analysis", "underwrite this", "is this a good deal",
"cash flow / cap rate / NOI / DSCR / cash-on-cash", "BRRRR", "buy-and-hold", "rent roll", "T12",
"analyze this multifamily / fourplex / SFR / mixed-use". Single asset of any size or type.

Do **not** use for: market/demographic questions about an address (that's the `vestmap` skill),
portfolio roll-ups, or generic spreadsheet help.

## Required inputs

| Input | What it is | Drives |
|---|---|---|
| **Rent Roll** | Per-unit current + market rent, type, sqft, occupancy | The rental-income lines; Proforma rent = market rent × 12 |
| **T12** | Trailing-12-month income statement (revenue + itemized expenses → NOI) | The "Current" column actuals; the expense breakdown |
| **Loan / purchase terms** | Purchase price + loan amount, rate, amortization, IO months (often a loan-amortization tab) | Financing, debt service, DSCR, cash-on-cash, projection |

Any file format is fine — PDF, Excel (`.xlsx`), CSV, or even a photo/screenshot. For Excel inputs,
save §Excel dump helper as `dump_xlsx.py` and run `python3 dump_xlsx.py <file>` to dump every cell
as text, then read it.

## Workflow

1. **Confirm you have the inputs.** If the user only described the deal, ask for the rent roll, T12,
   and loan/purchase terms. If they don't have them, follow **Missing-input handling** below — do not
   invent numbers.

2. **Parse the documents into the model.** Read each file (use `dump_xlsx.py` for Excel) and extract
   into the normalized JSON in §Data model. Map messy T12 line items / GL accounts to the standard
   expense buckets using §T12 mapping. Use §Sample model as a copy-and-edit template.
   - **Current** column = T12 actuals (the real trailing-12 performance).
   - **Proforma** column = market rents × 12 with stabilized assumptions (the script applies vacancy,
     management %, and R&M % automatically; all other expenses default to actuals held flat).
   - Group many tiny "other income" / "other expense" lines into a few clean categories so the pie
     charts stay legible (e.g., roll small fees into "Fees & Other Income"). Keep the big drivers
     itemized.

3. **Confirm the extraction (quick sanity check).** Before building, show the user a compact summary —
   not field-by-field. Roughly:
   > Units: 28 · In-place rent: $34,697/mo · Market rent: $39,208/mo · T12 revenue: $486,142 ·
   > T12 NOI: $299,266 · Purchase price: $4,000,000 · Loan: $2,880,000 @ 6.75% / 30 yr.
   > "Look right? I'll build the pro forma."
   Fix anything they flag, then proceed. (Skip the wait only if the user said "just build it".)

4. **Write the builder, ensure dependencies, then build.** Save the §Builder block **verbatim** as
   `build_proforma.py` (a scratch directory is fine; it is a tool, not a deliverable). Copy it exactly
   as written: it is tested as is, so never retype it from memory, shorten it or "improve" it. It
   needs `openpyxl` (always) and `matplotlib` (for the PDF). Install quietly if missing, then run:
   ```bash
   python3 -m pip install --quiet openpyxl matplotlib
   python3 build_proforma.py MODEL.json --outdir .
   ```
   It prints `XLSX:`, `PDF:`, and a `HEADLINE:` JSON of the key numbers. `--outdir` is where the two
   deliverables land; keep the script and the model JSON outside it so only the deliverables do.

5. **Report concisely.** Give the two file paths and a one-line headline (Proforma NOI, cap rate,
   DSCR, cash-on-cash, cash flow/yr). Note the Current vs. Proforma split in a sentence. If data was
   incomplete, state plainly what's still needed. Don't dump the whole model into chat — it's in the
   files.

## Missing-input handling (tiered)

Work down this ladder — never fabricate to fill a gap.

1. **Ask for the real docs.** Rent roll and T12 are almost always available from the **listing
   broker / brokerage** (they prepare them for every marketed deal). Tell the user to request the
   "rent roll and T12 (trailing-12 operating statement)" from the broker — that's the single best
   path to an accurate analysis.
2. **Guided collection (if they truly can't get the docs).** Collect a smaller set interactively:
   per-unit rents (or just unit count + average rent), the big expense lines (taxes, insurance,
   management, utilities, R&M) as annual figures, and purchase price + loan terms. This yields a
   real, if rougher, pro forma.
3. **Best-effort with flags.** If even that is partial, build with standard ratios for what's
   missing, set `data_completeness.tier` to 2 or 3, and list what's missing in
   `data_completeness.missing`. The script stamps a visible "Data completeness" note on both the
   workbook and the PDF, and you state the gaps in chat. The model runs, but everyone can see what
   needs firming up.

## Default assumptions (editable on the Assumptions sheet)

| Assumption | Default | Applies to |
|---|---|---|
| Vacancy | 5% | Proforma (gross market rent); Current vacancy is embedded in T12 actuals |
| Management | 8% of EGI | Proforma; Current uses the T12 actual |
| Repairs & Maintenance | 5% of EGI | Proforma; Current uses the T12 actual |
| Income growth | 2% / yr | Projection |
| Expense growth | 2% / yr | Projection |
| Appreciation | 3% / yr | Projection |
| Projection horizon | Years 1, 2, 5, 10, 15, 20, 30 | Projection table + charts |

These come from standard underwriting and match the source pro formas. To change them, edit the
`assumptions` block in the JSON (or tell the user they can edit the Assumptions sheet afterward).

## Optional: VestMap enrichment (only if the MCP is connected)

This skill is fully standalone. **But** if VestMap MCP tools (`mcp__*vestmap*` / the `vestmap` skill)
are available and the rent roll is missing market rents — or the user wants a market sanity-check —
you may pull area rent, tax and market context for the address and use it to fill the `market_rent`
column or sanity-check assumptions. Always flag these as estimates to the user, and never block the
build waiting on VestMap. If it's not connected, ignore this entirely.

Make **one** `get_radius_demographics` call (2026 Esri GeoEnrichment):

```
address:    <the property address>
fieldNames: ["MEDCRNT_CY","MEDHINC_CY","MEDVAL_CY","RENTER_CY","OWNER_CY","X3007_A","POPGRWCYFY","UNEMPRT_CY"]
shadeField: "MEDCRNT_CY"
```

Each field's `blockTractZip` holds block group / tract / ZIP / county / state / national values and
`radius."1"` / `"3"` / `"5"` the ring values; state the `blockTractZipVintage` year with any figure you use.

| Code | What it is | Use |
|---|---|---|
| `MEDCRNT_CY` | Median monthly contract rent, all unit sizes, excluding utilities. `3501` is Esri's top code ($3,500 or more) | Reference point for `market_rent` (block group first; tract, ZIP or 1-mile alongside) |
| `MEDHINC_CY` | Median household income | Rent-to-income check: proforma rent × 12 / income |
| `MEDVAL_CY` | Median home value | Context for the purchase price |
| `RENTER_CY`, `OWNER_CY` | Renter- and owner-occupied units | Renter share = renter / (renter + owner) |
| `X3007_A` | Average annual property taxes per household (Esri Consumer Spending, averaged over all households, renters included) | Context only, never the subject's tax line; taxes come from the T12 or the county assessor |
| `POPGRWCYFY`, `UNEMPRT_CY` | Annual population growth 2026–2031 (%), unemployment rate (%) | Market context for income-growth and vacancy assumptions |

An area median across all unit sizes is not a unit-level comp: when it fills `market_rent`, set
`data_completeness.tier` to 2 or 3 and list "market rents from area median contract rent" in
`data_completeness.missing`. Use only this call for area data. The connector's older
`query_gis_field` layers are a 2024 vintage. If the tool takes only a single `fieldName`, skip the
enrichment and build from the documents.

## Output files

- `<address-slug>-proforma.xlsx` — Summary (dashboard) · Proforma · Rent Roll · T12 · Loan · Assumptions.
- `<address-slug>-proforma.pdf` — 2-page visual report.

Both land in the working directory (or `--outdir`).

## What this skill does NOT do

- Does not fabricate rents, expenses, or deal terms to fill a gap (it guides the user to the source).
- Does not require any API, MCP, or internet — pure local parse → compute → render.
- Does not give buy/sell advice or qualitative verdicts — it lays out the numbers; the investor decides.
- Does not depend on Chrome or LibreOffice (the PDF is built with matplotlib).

## Data model

`build_proforma.py` consumes one JSON object. Extract the source documents into this shape, then
run the script. Everything below is what the script reads — fields not listed are ignored.

All money is **annual dollars** unless noted. Percentages may be written as `0.05` or `"5%"` (both
parse). Numbers may include `$`/`,` (e.g. `"$1,234"`). Missing/blank → treated as 0.

### Top-level shape

```json
{
  "property":   { ... },
  "rent_roll":  [ { per-unit }, ... ],
  "income":     { ... },
  "expenses":   { ... },
  "financing":  { ... },
  "assumptions":{ ... },
  "t12":        { ... },        // optional: renders the T12 tab
  "data_completeness": { ... }  // optional: tier + missing list
}
```

### `property`
```json
{ "address": "6331 N Wyandotte St", "name": "", "property_type": "Fourplex",
  "units": 4, "analysis_date": "2026-05-20" }
```
`units` = door count (drives price/door and cash flow/unit). `analysis_date` defaults to today.

### `rent_roll` (array, one object per unit)
```json
{ "unit": "101", "type": "2 bd 1 ba", "sqft": 1050,
  "current_rent": 1585, "market_rent": 1675, "status": "occupied", "notes": "" }
```
- `current_rent` / `market_rent` are **monthly**. Vacant units: `current_rent: 0`, `status: "vacant"`.
- Include commercial units too (e.g. a ground-floor retail tenant) — just set their rents.
- The script sums these: **Proforma rental income = Σ market_rent × 12** (used when
  `income.rental_income.proforma` is not given).

### `income`
```json
{
  "rental_income": { "current": 431366.82, "proforma": null },
  "current_vacancy_loss": 0,
  "other_income": [
    { "label": "Parking", "current": 24132.02, "proforma": 24132.02 },
    { "label": "Utility Reimbursements", "current": 20117.80, "proforma": 20117.80 }
  ]
}
```
- `rental_income.current` = the **T12 net rental revenue** (it already reflects real vacancy/loss-to-
  lease/concessions). If omitted, the script uses Σ rent_roll `current_rent` × 12.
- `rental_income.proforma` = leave `null` to compute from the rent roll's market column, or set
  explicitly.
- `current_vacancy_loss` = a **negative** number if you want a separate current vacancy line; usually
  `0` because T12 net rent already embeds it. (Proforma vacancy is computed: `-vacancy% × proforma rent`.)
- `other_income[]` — parking, pet rent, fees, utility reimbursements, etc. Each has `current` and
  `proforma` (proforma defaults to current if omitted). **Group small lines** into a few clean
  categories so the income pie stays readable.

### `expenses`
Each standard bucket is `{ "current": <T12 actual>, "proforma": <optional override> }`.
```json
{
  "management":          { "current": 26710.35 },
  "property_taxes":      { "current": 28755, "proforma": 28755 },
  "insurance":           { "current": 23126.20 },
  "water_sewer":         { "current": 15165.71 },
  "electric":            { "current": 7234.73 },
  "gas":                 { "current": 0 },
  "trash":               { "current": 10797.07 },
  "repairs_maintenance": { "current": 11194.06 },
  "payroll":             { "current": 12768.75 },
  "landscaping":         { "current": 810 },
  "make_ready":          { "current": 1082 },
  "general_admin":       { "current": 50041.91 },
  "reserves":            { "current": 0 },
  "other": [ { "label": "Lease Up Fees", "current": 1768.75, "proforma": 0 } ]
}
```
**Proforma rules the script applies automatically:**
- `management` proforma = `management_pct × EGI` (default 8%).
- `repairs_maintenance` proforma = `repairs_pct × EGI` (default 5%).
- Every other bucket: proforma = explicit `proforma` if given, else **held flat at `current`**.
- `other[]` are extra named lines (current-only items like lease-up fees → set `proforma: 0`).
- Lines that are 0 in **both** columns (and aren't management/R&M) are dropped to keep it clean.

Map raw T12 line items into these buckets with §T12 mapping.

### `financing`
```json
{ "purchase_price": 499000, "ltv": 0.75, "loan_amount": null,
  "interest_rate": 0.065, "amortization_years": 30, "interest_only_months": 0,
  "closing_costs": 0, "repair_costs": 0, "loan_fees": 0 }
```
- `loan_amount` — give it directly (e.g. from the loan-amortization tab) **or** leave `null` to
  compute `purchase_price × ltv`.
- Down payment = price − loan. Total cash needed = down + closing + repair + loan fees.
- Debt service = monthly P&I × 12 (interest-only if `interest_only_months ≥ 12`).

### `assumptions`
```json
{ "vacancy_rate": 0.05, "management_pct": 0.08, "repairs_pct": 0.05,
  "income_growth": 0.02, "expense_growth": 0.02, "appreciation": 0.03,
  "projection_years": [1, 2, 5, 10, 15, 20, 30] }
```
Defaults shown; override only when the user gives different numbers.

### `t12` (optional — renders the T12 tab)
```json
{ "period": "Apr 2025 – Mar 2026 (Trailing 12)",
  "rows": [ { "label": "Total Revenue", "annual": 486141.64, "total": true },
            { "label": "Management Fees", "annual": 26710.35 } ] }
```
`total: true` bolds the row. Include it so the workbook shows the trailing-12 evidence base.

### `data_completeness` (optional)
`{ "tier": 1, "missing": [], "flags": [] }` — set `tier` 2/3 and list `missing` items when inputs are
incomplete; the script stamps a visible note on the workbook and PDF.

### Computation summary (what the script derives)

```
EGI            = rental_income + vacancy + Σ other_income          (per column)
Total OpEx     = Σ expense buckets                                  (per column)
NOI            = EGI − Total OpEx                                   (per column)
Cap Rate       = NOI / purchase_price
Annual Debt Svc= monthly P&I × 12   (PMT on loan amount/rate/term)
DSCR           = NOI / Annual Debt Service
Free Cash Flow = NOI − Annual Debt Service   (year / ÷12 month / ÷units per-unit-month)
Cash-on-Cash   = Free Cash Flow / Total Cash Needed
GRM            = purchase_price / gross rental income
Projection yr n: income×(1+g_inc)^(n-1), expenses×(1+g_exp)^(n-1),
                 value=price×(1+appr)^n, loan balance from amortization, equity=value−balance
```

## T12 mapping

A T12 (trailing-12 operating statement) comes in many formats — RealPage, Yardi, AppFolio,
QuickBooks, or a broker's spreadsheet — often with GL account numbers and dozens of sub-lines. Map
each line into the standard model buckets below. Use the **annual total** column (the trailing-12
sum), not a single month.

### Revenue → `income`

| T12 line items (any of these names) | Goes to |
|---|---|
| Gross Potential Rent, Scheduled Rent, Market Rent, Rental Income, Total Rental Revenue (net of loss-to-lease / concessions / vacancy) | `income.rental_income.current` |
| Loss to Lease, Vacancy Loss, Concessions, Bad Debt, Uncollected Rent | already inside net Total Rental Revenue → leave `current_vacancy_loss: 0` (don't double-count) |
| Parking, Garage, Storage | `other_income[]` "Parking" |
| Utility Reimbursement, RUBS, Utility Income | `other_income[]` "Utility Reimbursements" |
| Pet Rent, Pet Fee | `other_income[]` "Pet Rent & Fees" |
| Late Fees, NSF, Application Fees, Admin Fees, Damages, Interest Income, Misc/Other Income | roll up into one `other_income[]` "Fees & Other Income" |

**Rule:** keep the 2–4 biggest other-income sources as their own lines; lump the rest into "Fees &
Other Income" so the income pie stays readable.

### Expenses → `expenses`

| T12 line items (any of these names) | Bucket key |
|---|---|
| Management Fee, Property Management, Asset Management | `management` |
| Payroll, Salaries, On-site Staff, Maintenance Payroll/Labor, Temporary Maintenance | `payroll` |
| Water, Sewer, Water & Sewer | `water_sewer` |
| Electric, Electricity (common + vacant), Power | `electric` |
| Gas, Natural Gas | `gas` |
| Trash, Garbage, Waste Removal, Recycling | `trash` |
| Repairs & Maintenance, R&M, HVAC, Plumbing, Electrical repairs, Appliances, Parts/Supplies, Pest Control, Fire/Safety | `repairs_maintenance` |
| Make Ready, Turnover, Apartment/Carpet Cleaning, Painting | `make_ready` |
| Landscaping, Grounds, Snow Removal, Sweeping | `landscaping` |
| Property Insurance, Liability Insurance | `insurance` |
| Property Taxes, Real Estate Taxes | `property_taxes` |
| Advertising, Marketing, Office, Bank Fees, Legal/Professional, Dues, Telephone/Internet, Software, Accounting, Eviction, Resident Relations, Postage | `general_admin` |
| Replacement Reserves, CapEx Reserve | `reserves` |
| Anything that doesn't fit (e.g. a one-off Lease-Up Fee) | `expenses.other[]` with a `label` |

#### Notes & judgment calls

- **Sum the sub-lines.** A T12 often lists 15 repair sub-accounts (HVAC, plumbing, appliances…). Add
  them into one `repairs_maintenance.current`. Same for utilities (Water + Electric + Trash often sit
  under one "Utilities" header — split them by sub-line if shown, else put the total under the closest
  bucket and note it).
- **Exclude below-NOI items.** Mortgage/Debt Service, Depreciation, Amortization, Capital
  Improvements, Owner Distributions, and Income Taxes are **not** operating expenses — leave them out
  of `expenses` (financing is handled separately in `financing`). Including them would understate NOI.
- **Management & R&M:** put the **T12 actual** in `current`. The script overrides the **proforma**
  column with the % assumptions (8% / 5%), so you don't compute those.
- **Offsetting items:** if a line is offset by income (e.g. tenant-charged garage dues offset by
  parking revenue), keep both gross and add a `notes` entry — don't silently net them.
- **Watch for partial years or one-time spikes.** If the T12 has a one-time tax catch-up or a month
  of $0 for a recurring bill, flag it in `notes` rather than smoothing it yourself.

### Quick worked example (RealPage-style export → buckets)

```
TOTAL RENTAL REVENUE        431,366.82  → income.rental_income.current
Parking Revenue              24,132.02  → other_income "Parking"
Utility Reimbursements       20,117.80  → other_income "Utility Reimbursements"
Pet Rent + Pet Fee            3,284.35  → other_income "Pet Rent & Fees"
Late/App/Admin/Interest/...   7,240.65  → other_income "Fees & Other Income"
Management Fees              26,710.35  → management
Payroll - Temp Maintenance   12,768.75  → payroll
Water                        15,165.71  → water_sewer
Electricity (vacant+common)   7,234.73  → electric
Waste Removal                10,797.07  → trash
Repairs & Maintenance        11,194.06  → repairs_maintenance
Make Ready / Turn             1,082.00  → make_ready
General & Administrative     50,041.91  → general_admin
Property Insurance           23,126.20  → insurance
Property Taxes               28,755.00  → property_taxes
                            -----------
TOTAL EXPENSES              186,875.78   (ties to T12)  →  NOI = 299,265.86
```

## Sample model

A complete, runnable model (a fourplex). Copy it as the starting point for a new deal.

```json
{
  "property": {
    "address": "6331 N Wyandotte St",
    "property_type": "Fourplex",
    "units": 4,
    "analysis_date": "2026-05-20"
  },
  "rent_roll": [
    { "unit": "6631", "type": "2 bd 1 ba", "current_rent": 995,  "market_rent": 1095, "status": "occupied" },
    { "unit": "6633", "type": "2 bd 1 ba", "current_rent": 1050, "market_rent": 1050, "status": "occupied", "notes": "just finished make ready" },
    { "unit": "6635", "type": "2 bd 1 ba", "current_rent": 1025, "market_rent": 1095, "status": "occupied" },
    { "unit": "6637", "type": "2 bd 1 ba", "current_rent": 1000, "market_rent": 1095, "status": "occupied" }
  ],
  "income": {
    "rental_income": { "current": 46176, "proforma": null },
    "current_vacancy_loss": 0,
    "other_income": [
      { "label": "Utility Fees", "current": 0,   "proforma": 1200 },
      { "label": "Pet Rent",     "current": 150, "proforma": 840 }
    ]
  },
  "expenses": {
    "management":          { "current": 3562.16 },
    "property_taxes":      { "current": 4070, "proforma": 4070 },
    "insurance":           { "current": 2423, "proforma": 2423 },
    "water_sewer":         { "current": 0, "proforma": 0 },
    "trash":               { "current": 1708.58, "proforma": 1708.58 },
    "landscaping":         { "current": 810, "proforma": 810 },
    "repairs_maintenance": { "current": 2316.30 },
    "other": [
      { "label": "Lease Up Fees", "current": 1768.75, "proforma": 0 }
    ]
  },
  "financing": {
    "purchase_price": 499000,
    "ltv": 0.75,
    "loan_amount": 374250,
    "interest_rate": 0.065,
    "amortization_years": 30,
    "interest_only_months": 0,
    "closing_costs": 0,
    "repair_costs": 0,
    "loan_fees": 0
  },
  "assumptions": {
    "vacancy_rate": 0.05,
    "management_pct": 0.08,
    "repairs_pct": 0.05,
    "income_growth": 0.02,
    "expense_growth": 0.02,
    "appreciation": 0.03,
    "projection_years": [1, 2, 5, 10, 15, 20, 30]
  },
  "data_completeness": { "tier": 1, "missing": [], "flags": [] }
}
```

## Builder

Save this block verbatim as `build_proforma.py` (Workflow step 4). Usage:
`python3 build_proforma.py MODEL.json [--outdir DIR] [--no-pdf] [--basename NAME]`.

```python
#!/usr/bin/env python3
"""
Rental Property Analyzer — pro forma builder.

Input : a normalized JSON model (see the skill's Data model section).
Output: an editable .xlsx workbook (live formulas + native charts) and a
        polished .pdf report (BiggerPockets-style visuals).

Usage:
    python3 build_proforma.py MODEL.json [--outdir DIR] [--no-pdf] [--basename NAME]

The .xlsx always builds (needs openpyxl). The .pdf builds when matplotlib is
importable; otherwise the script prints a one-line note and ships the xlsx alone.

Single source of truth: every number is computed once in compute_model().
The workbook writes live formulas (so the model stays editable) and the PDF
draws the computed values, so both always agree.
"""
import argparse
import datetime as _dt
import json
import os
import re
import shutil
import sys
import tempfile


# --------------------------------------------------------------------------
# Math model
# --------------------------------------------------------------------------
def _num(x, default=0.0):
    """Coerce to float, tolerating None / "" / "$1,234" / "5%" style inputs."""
    if x is None or x == "":
        return float(default)
    if isinstance(x, (int, float)):
        return float(x)
    s = str(x).strip().replace(",", "").replace("$", "")
    pct = s.endswith("%")
    s = s.rstrip("%")
    try:
        v = float(s)
    except ValueError:
        return float(default)
    return v / 100.0 if pct else v


def pmt(rate_monthly, n_months, principal):
    """Level monthly payment (positive number)."""
    if n_months <= 0:
        return 0.0
    if rate_monthly == 0:
        return principal / n_months
    return principal * rate_monthly / (1 - (1 + rate_monthly) ** (-n_months))


def amortization_balances(principal, annual_rate, years, io_months=0):
    """Return {month: ending_balance} plus the level payment, computed monthly."""
    r = annual_rate / 12.0
    n = int(round(years * 12))
    amort_n = max(n - io_months, 0)
    level = pmt(r, amort_n, principal)
    bal = principal
    out = {0: principal}
    for m in range(1, n + 1):
        interest = bal * r
        if m <= io_months:
            payment = interest          # interest-only period
        else:
            payment = level
        principal_paid = payment - interest
        bal = max(bal - principal_paid, 0.0)
        out[m] = bal
    return out, level


def compute_model(model):
    """Turn the input JSON into a fully computed result dict used by both renderers."""
    a = model.get("assumptions", {})
    vac = _num(a.get("vacancy_rate", 0.05), 0.05)
    mgmt_pct = _num(a.get("management_pct", 0.08), 0.08)
    rm_pct = _num(a.get("repairs_pct", 0.05), 0.05)
    inc_g = _num(a.get("income_growth", 0.02), 0.02)
    exp_g = _num(a.get("expense_growth", 0.02), 0.02)
    appr = _num(a.get("appreciation", 0.03), 0.03)
    proj_years = a.get("projection_years", [1, 2, 5, 10, 15, 20, 30])

    prop = model.get("property", {})
    units = int(_num(prop.get("units", 1), 1)) or 1

    # ----- rent roll roll-ups -----
    roll = model.get("rent_roll", []) or []
    rr_current_mo = sum(_num(u.get("current_rent")) for u in roll)
    rr_market_mo = sum(_num(u.get("market_rent")) for u in roll)

    # ----- income -----
    inc = model.get("income", {})
    ri = inc.get("rental_income", {}) if isinstance(inc.get("rental_income"), dict) else {}
    rent_current = _num(ri.get("current")) or rr_current_mo * 12
    rent_proforma = _num(ri.get("proforma")) or rr_market_mo * 12

    vac_current = _num(inc.get("current_vacancy_loss"))          # negative or 0 (often embedded in T12 actuals)
    vac_proforma = -vac * rent_proforma

    other = []
    for o in (inc.get("other_income") or []):
        oc = _num(o.get("current"))
        op = _num(o.get("proforma")) if o.get("proforma") not in (None, "") else oc
        other.append({"label": o.get("label", "Other Income"), "current": oc, "proforma": op})
    other_cur = sum(o["current"] for o in other)
    other_pro = sum(o["proforma"] for o in other)

    egi_current = rent_current + vac_current + other_cur
    egi_proforma = rent_proforma + vac_proforma + other_pro

    # ----- expenses -----
    exp = model.get("expenses", {})

    def exp_pair(key, label, proforma_pct=None):
        e = exp.get(key, {}) if isinstance(exp.get(key), dict) else {}
        cur = _num(e.get("current"))
        if proforma_pct is not None:
            pro = proforma_pct * egi_proforma
        elif e.get("proforma") not in (None, ""):
            pro = _num(e.get("proforma"))
        else:
            pro = cur                                   # held flat at actuals
        return {"key": key, "label": label, "current": cur, "proforma": pro}

    expense_lines = [
        exp_pair("management", "Property Management", proforma_pct=mgmt_pct),
        exp_pair("property_taxes", "Property Taxes"),
        exp_pair("insurance", "Property Insurance"),
        exp_pair("water_sewer", "Water / Sewer"),
        exp_pair("electric", "Electricity"),
        exp_pair("gas", "Gas"),
        exp_pair("trash", "Trash / Waste"),
        exp_pair("repairs_maintenance", "Repairs & Maintenance", proforma_pct=rm_pct),
        exp_pair("payroll", "Payroll / On-site Labor"),
        exp_pair("landscaping", "Landscaping / Grounds"),
        exp_pair("make_ready", "Make Ready / Turnover"),
        exp_pair("general_admin", "General & Administrative"),
        exp_pair("reserves", "Replacement Reserves"),
    ]
    for o in (exp.get("other") or []):
        oc = _num(o.get("current"))
        op = _num(o.get("proforma")) if o.get("proforma") not in (None, "") else oc
        expense_lines.append({"key": None, "label": o.get("label", "Other Expense"),
                              "current": oc, "proforma": op})

    # Drop lines that are zero in BOTH columns AND carry no proforma rule, to keep it clean.
    rule_keys = {"management", "repairs_maintenance"}
    expense_lines = [e for e in expense_lines
                     if e["current"] or e["proforma"] or e["key"] in rule_keys]

    opex_current = sum(e["current"] for e in expense_lines)
    opex_proforma = sum(e["proforma"] for e in expense_lines)

    noi_current = egi_current - opex_current
    noi_proforma = egi_proforma - opex_proforma

    # ----- financing / returns -----
    fin = model.get("financing", {})
    price = _num(fin.get("purchase_price"))
    closing = _num(fin.get("closing_costs"))
    repairs = _num(fin.get("repair_costs"))
    fees = _num(fin.get("loan_fees"))
    ltv = _num(fin.get("ltv", 0.75), 0.75)
    rate = _num(fin.get("interest_rate", 0.065), 0.065)
    years = _num(fin.get("amortization_years", 30), 30)
    io_months = int(_num(fin.get("interest_only_months", 0)))

    loan = _num(fin.get("loan_amount")) or price * ltv
    down = price - loan
    cash_needed = down + closing + repairs + fees

    balances, level_pmt = amortization_balances(loan, rate, years, io_months)
    annual_ds = (loan * rate) if io_months >= 12 else level_pmt * 12
    monthly_pi = level_pmt

    def returns(noi):
        cap = noi / price if price else 0.0
        dscr = noi / annual_ds if annual_ds else 0.0
        fcf_yr = noi - annual_ds
        coc = fcf_yr / cash_needed if cash_needed else 0.0
        return {"cap_rate": cap, "dscr": dscr, "fcf_year": fcf_yr,
                "fcf_month": fcf_yr / 12, "fcf_unit_month": fcf_yr / 12 / units,
                "cash_on_cash": coc}

    ret_current = returns(noi_current)
    ret_proforma = returns(noi_proforma)
    grm = price / rent_proforma if rent_proforma else 0.0

    # ----- multi-year projection (base = proforma) -----
    projection = []
    for n in proj_years:
        income_n = egi_proforma * (1 + inc_g) ** (n - 1)
        expense_n = opex_proforma * (1 + exp_g) ** (n - 1)
        noi_n = income_n - expense_n
        cf_n = noi_n - annual_ds
        value_n = price * (1 + appr) ** n
        bal_n = balances.get(int(round(n * 12)), 0.0)
        equity_n = value_n - bal_n
        projection.append({
            "year": n, "income": income_n, "expenses": expense_n, "noi": noi_n,
            "cash_flow": cf_n, "value": value_n, "loan_balance": bal_n,
            "equity": equity_n,
            "coc": (cf_n / cash_needed if cash_needed else 0.0),
        })

    return {
        "property": {"address": prop.get("address", "Rental Property"),
                     "name": prop.get("name", ""),
                     "type": prop.get("property_type", ""),
                     "units": units,
                     "date": prop.get("analysis_date") or _dt.date.today().isoformat()},
        "assumptions": {"vacancy": vac, "mgmt_pct": mgmt_pct, "rm_pct": rm_pct,
                        "income_growth": inc_g, "expense_growth": exp_g,
                        "appreciation": appr, "projection_years": proj_years},
        "rent_roll": roll, "rr_current_mo": rr_current_mo, "rr_market_mo": rr_market_mo,
        "income": {"rent_current": rent_current, "rent_proforma": rent_proforma,
                   "vac_current": vac_current, "vac_proforma": vac_proforma,
                   "other": other, "egi_current": egi_current, "egi_proforma": egi_proforma},
        "expense_lines": expense_lines, "opex_current": opex_current, "opex_proforma": opex_proforma,
        "noi_current": noi_current, "noi_proforma": noi_proforma,
        "financing": {"price": price, "closing": closing, "repairs": repairs, "fees": fees,
                      "ltv": ltv, "rate": rate, "years": years, "io_months": io_months,
                      "loan": loan, "down": down, "cash_needed": cash_needed,
                      "monthly_pi": monthly_pi, "annual_ds": annual_ds},
        "ret_current": ret_current, "ret_proforma": ret_proforma, "grm": grm,
        "price_per_door": (price / units if units else 0.0),
        "projection": projection,
        "notes": model.get("notes", {}),
        "completeness": model.get("data_completeness", {"tier": 1, "missing": [], "flags": []}),
        "t12": model.get("t12", {}),
    }


# --------------------------------------------------------------------------
# Excel workbook (live formulas + native charts)
# --------------------------------------------------------------------------
ACCENT = "1F4E46"      # deep green
ACCENT2 = "3E7D6A"
LIGHT = "EAF1EE"
GREY = "6B6B6B"
LINE = "D9D9D9"
WHITE = "FFFFFF"
USD = '$#,##0'
USD2 = '$#,##0.00'
PCT = '0.0%'
NUM = '#,##0'
PIE_COLORS = ["#1F4E46", "#3E7D6A", "#6FA292", "#A7C7BC", "#C9803A", "#D9A566",
              "#8A8D91", "#B9BCC0", "#5B6E8C", "#9FB0C9", "#7A5C7B", "#B49AB5"]


def _save_chart_pngs(M, outdir):
    """Render the 4 dashboard charts as PNGs for embedding. Returns {key: path} or None
    if matplotlib is unavailable (the workbook then ships without chart images)."""
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        import matplotlib.ticker as mticker
    except Exception:
        return None

    green, green2, orange = "#1F4E46", "#3E7D6A", "#C9803A"

    def finish(fig, name):
        path = os.path.join(outdir, name)
        fig.savefig(path, dpi=150, facecolor="white")
        plt.close(fig)
        return path

    out = {}

    def pie(slices, title, name):
        slices = [(lab, v) for lab, v in slices if v and v > 0]
        fig, ax = plt.subplots(figsize=(4.4, 3.0))
        if slices:
            ax.pie([v for _, v in slices], labels=[lab for lab, _ in slices],
                   autopct="%1.0f%%", colors=PIE_COLORS[:len(slices)],
                   textprops={"fontsize": 6.5}, pctdistance=0.78, labeldistance=1.08,
                   wedgeprops={"linewidth": 0.5, "edgecolor": "white"})
        ax.set_title(title, fontsize=10.5, color=green, fontweight="bold")
        fig.tight_layout()
        return finish(fig, name)

    exp = [(e["label"], e["proforma"]) for e in M["expense_lines"]]
    out["exp"] = pie(exp, "Operating Expenses (Proforma)", "chart_exp.png")

    inc = M["income"]
    islices = [("Net Rental", inc["rent_proforma"] + inc["vac_proforma"])] + \
              [(o["label"], o["proforma"]) for o in inc["other"]]
    out["income"] = pie(islices, "Income (Proforma)", "chart_income.png")

    proj = M["projection"]
    yrs = [pr["year"] for pr in proj]

    def line(series, title, name, dollar_axis=True):
        fig, ax = plt.subplots(figsize=(4.4, 3.0))
        for label, key, color in series:
            ax.plot(yrs, [pr[key] for pr in proj], marker="o", ms=3, color=color, label=label)
        ax.legend(fontsize=7, loc="upper left")
        ax.set_title(title, fontsize=10.5, color=green, fontweight="bold")
        ax.tick_params(labelsize=7)
        pre = "$" if dollar_axis else ""
        ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f"{pre}{v/1000:.0f}k"))
        ax.set_xlabel("Year", fontsize=7)
        for s in ("top", "right"):
            ax.spines[s].set_visible(False)
        fig.tight_layout()
        return finish(fig, name)

    out["cashflow"] = line([("Income", "income", green), ("Expenses", "expenses", orange),
                            ("Cash Flow", "cash_flow", green2)],
                           "Income · Expenses · Cash Flow ($/yr)", "chart_cashflow.png", dollar_axis=False)
    out["equity"] = line([("Property Value", "value", green), ("Equity", "equity", green2),
                          ("Loan Balance", "loan_balance", orange)],
                         "Equity · Loan Balance · Value", "chart_equity.png")
    return out


def build_workbook(M, path):
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
    from openpyxl.utils import get_column_letter

    wb = openpyxl.Workbook()
    wb.calculation.fullCalcOnLoad = True     # force Excel/Sheets/LibreOffice to recompute on open

    thin = Side(style="thin", color=LINE)
    box = Border(bottom=thin)

    def style(cell, *, bold=False, size=11, color="141414", fill=None,
              align=None, fmt=None, italic=False):
        cell.font = Font(bold=bold, size=size, color=color, italic=italic)
        if fill:
            cell.fill = PatternFill("solid", fgColor=fill)
        if align:
            cell.alignment = Alignment(horizontal=align, vertical="center", wrap_text=(align == "wrap"))
        if fmt:
            cell.number_format = fmt
        return cell

    # ===================== PROFORMA sheet =====================
    pf = wb.active
    pf.title = "Proforma"
    pf.sheet_view.showGridLines = False
    pf.column_dimensions["A"].width = 2
    pf.column_dimensions["B"].width = 34
    pf.column_dimensions["C"].width = 17
    pf.column_dimensions["D"].width = 17

    R = {}
    p = M["property"]
    style(pf["B1"], bold=True, size=16, color=WHITE, fill=ACCENT)
    pf["B1"] = p["address"]
    for c in ("C1", "D1"):
        pf[c].fill = PatternFill("solid", fgColor=ACCENT)
    pf.merge_cells("B1:D1")
    sub = f'{p["type"]} · {p["units"]} unit(s) · Analysis {p["date"]}'.strip(" ·")
    style(pf["B2"], size=9, color=GREY)
    pf["B2"] = sub

    style(pf["C4"], bold=True, align="center", color=ACCENT)
    pf["C4"] = "Current"
    style(pf["D4"], bold=True, align="center", color=ACCENT)
    pf["D4"] = "Proforma"

    row = 5

    def section(title):
        nonlocal row
        style(pf.cell(row=row, column=2, value=title), bold=True, size=11, color=WHITE, fill=ACCENT2)
        for col in (3, 4):
            pf.cell(row=row, column=col).fill = PatternFill("solid", fgColor=ACCENT2)
        row += 1

    def line(label, cur=None, pro=None, *, bold=False, fmt=USD, fill=None):
        nonlocal row
        style(pf.cell(row=row, column=2, value=label), bold=bold, fill=fill)
        if cur is not None:
            style(pf.cell(row=row, column=3, value=cur), bold=bold, fmt=fmt, align="right", fill=fill)
        if pro is not None:
            style(pf.cell(row=row, column=4, value=pro), bold=bold, fmt=fmt, align="right", fill=fill)
        r = row
        row += 1
        return r

    inc = M["income"]
    section("INCOME")
    R["rent"] = line("Rental Income", inc["rent_current"], inc["rent_proforma"])
    R["vac"] = line("Vacancy & Credit Loss", inc["vac_current"], inc["vac_proforma"])
    R["other_first"] = row
    for o in inc["other"]:
        line(o["label"], o["current"], o["proforma"])
    R["other_last"] = row - 1
    # EGI = rent + vacancy + other income block
    egi_cur_f = f'=C{R["rent"]}+C{R["vac"]}'
    egi_pro_f = f'=D{R["rent"]}+D{R["vac"]}'
    if inc["other"]:
        egi_cur_f += f'+SUM(C{R["other_first"]}:C{R["other_last"]})'
        egi_pro_f += f'+SUM(D{R["other_first"]}:D{R["other_last"]})'
    R["egi"] = line("Effective Gross Income (EGI)", egi_cur_f, egi_pro_f, bold=True, fill=LIGHT)

    row += 1
    section("OPERATING EXPENSES")
    R["exp_first"] = row
    for e in M["expense_lines"]:
        if e["key"] == "management":
            pro = f'=D{R["egi"]}*{M["assumptions"]["mgmt_pct"]}'
        elif e["key"] == "repairs_maintenance":
            pro = f'=D{R["egi"]}*{M["assumptions"]["rm_pct"]}'
        else:
            pro = e["proforma"]
        line(e["label"], e["current"], pro)
    R["exp_last"] = row - 1
    R["opex"] = line("Total Operating Expenses",
                     f'=SUM(C{R["exp_first"]}:C{R["exp_last"]})',
                     f'=SUM(D{R["exp_first"]}:D{R["exp_last"]})', bold=True, fill=LIGHT)

    row += 1
    section("NET OPERATING INCOME")
    R["noi"] = line("NOI", f'=C{R["egi"]}-C{R["opex"]}', f'=D{R["egi"]}-D{R["opex"]}',
                    bold=True, fill=LIGHT)

    fin = M["financing"]
    row += 1
    section("ACQUISITION & FINANCING")
    R["price"] = line("Purchase Price", fin["price"], f'=C{row}')  # D mirrors C
    R["ppd"] = line("Price per Door", f'=C{R["price"]}/{p["units"]}', f'=D{R["price"]}/{p["units"]}')
    R["ltv"] = line("LTV", fin["ltv"], f'=C{row}', fmt=PCT)
    R["loan"] = line("Loan Amount", f'=C{R["price"]}*C{R["ltv"]}', f'=D{R["price"]}*D{R["ltv"]}')
    R["down"] = line("Down Payment", f'=C{R["price"]}-C{R["loan"]}', f'=D{R["price"]}-D{R["loan"]}')
    R["cash"] = line("Total Cash Needed", fin["cash_needed"], f'=C{row}')
    R["ds"] = line("Annual Debt Service", "=Loan!B10", "=Loan!B10")

    row += 1
    section("RETURNS")
    R["cap"] = line("Cap Rate (on price)", f'=C{R["noi"]}/C{R["price"]}',
                    f'=D{R["noi"]}/D{R["price"]}', fmt=PCT)
    R["dscr"] = line("DSCR", f'=C{R["noi"]}/C{R["ds"]}', f'=D{R["noi"]}/D{R["ds"]}', fmt='0.00')
    R["fcf_y"] = line("Free Cash Flow (Year)", f'=C{R["noi"]}-C{R["ds"]}', f'=D{R["noi"]}-D{R["ds"]}')
    R["fcf_m"] = line("Free Cash Flow (Month)", f'=C{R["fcf_y"]}/12', f'=D{R["fcf_y"]}/12')
    R["fcf_u"] = line("Cash Flow / Unit / Month", f'=C{R["fcf_m"]}/{p["units"]}',
                      f'=D{R["fcf_m"]}/{p["units"]}', fmt=USD2)
    R["coc"] = line("Cash-on-Cash Return", f'=C{R["fcf_y"]}/C{R["cash"]}',
                    f'=D{R["fcf_y"]}/D{R["cash"]}', fmt=PCT)
    R["grm"] = line("Gross Rent Multiplier", f'=C{R["price"]}/C{R["rent"]}',
                    f'=D{R["price"]}/D{R["rent"]}', fmt='0.0')

    pf.print_area = f"A1:D{row}"
    pf.page_setup.orientation = "portrait"
    pf.page_setup.fitToWidth = 1
    pf.page_setup.fitToHeight = 1
    pf.sheet_properties.pageSetUpPr = openpyxl.worksheet.properties.PageSetupProperties(fitToPage=True)
    M["_R"] = R  # expose proforma row map for the Summary sheet

    # ===================== RENT ROLL sheet =====================
    rr = wb.create_sheet("Rent Roll")
    rr.sheet_view.showGridLines = False
    headers = ["Unit", "Type", "Sq Ft", "Current Rent", "Market Rent", "Status", "Notes"]
    widths = [12, 16, 9, 14, 14, 12, 28]
    for i, (h, w) in enumerate(zip(headers, widths), start=1):
        style(rr.cell(row=1, column=i, value=h), bold=True, color=WHITE, fill=ACCENT)
        rr.column_dimensions[get_column_letter(i)].width = w
    r = 2
    for u in M["rent_roll"]:
        rr.cell(row=r, column=1, value=u.get("unit", ""))
        rr.cell(row=r, column=2, value=u.get("type", ""))
        style(rr.cell(row=r, column=3, value=_num(u.get("sqft")) or None), fmt=NUM, align="right")
        style(rr.cell(row=r, column=4, value=_num(u.get("current_rent")) or None), fmt=USD, align="right")
        style(rr.cell(row=r, column=5, value=_num(u.get("market_rent")) or None), fmt=USD, align="right")
        rr.cell(row=r, column=6, value=u.get("status", ""))
        style(rr.cell(row=r, column=7, value=u.get("notes", "")), size=9, color=GREY, italic=True)
        r += 1
    last = r - 1
    style(rr.cell(row=r, column=2, value="TOTAL (monthly)"), bold=True, fill=LIGHT)
    style(rr.cell(row=r, column=4, value=f"=SUM(D2:D{last})" if last >= 2 else 0), bold=True, fmt=USD, align="right", fill=LIGHT)
    style(rr.cell(row=r, column=5, value=f"=SUM(E2:E{last})" if last >= 2 else 0), bold=True, fmt=USD, align="right", fill=LIGHT)
    for col in (1, 3, 6, 7):
        rr.cell(row=r, column=col).fill = PatternFill("solid", fgColor=LIGHT)

    # ===================== T12 sheet =====================
    t12 = M.get("t12") or {}
    if t12.get("rows"):
        ts = wb.create_sheet("T12")
        ts.sheet_view.showGridLines = False
        style(ts.cell(row=1, column=1, value=t12.get("period", "Trailing 12 Months")), bold=True, color=WHITE, fill=ACCENT)
        ts.cell(row=1, column=2).fill = PatternFill("solid", fgColor=ACCENT)
        ts.column_dimensions["A"].width = 38
        ts.column_dimensions["B"].width = 16
        style(ts.cell(row=2, column=1, value="Line Item"), bold=True)
        style(ts.cell(row=2, column=2, value="Annual (T12)"), bold=True, align="right")
        rr2 = 3
        for item in t12["rows"]:
            label = item.get("label", "")
            amt = _num(item.get("annual"))
            is_total = item.get("total", False)
            style(ts.cell(row=rr2, column=1, value=label), bold=is_total, fill=(LIGHT if is_total else None))
            style(ts.cell(row=rr2, column=2, value=amt), bold=is_total, fmt=USD, align="right",
                  fill=(LIGHT if is_total else None))
            rr2 += 1

    # ===================== LOAN sheet =====================
    ln = wb.create_sheet("Loan")
    ln.sheet_view.showGridLines = False
    ln.column_dimensions["A"].width = 26
    ln.column_dimensions["B"].width = 16
    style(ln.cell(row=1, column=1, value="Loan Amortization"), bold=True, size=14, color=WHITE, fill=ACCENT)
    ln.cell(row=1, column=2).fill = PatternFill("solid", fgColor=ACCENT)

    def lrow(rr_, label, value, fmt=None):
        style(ln.cell(row=rr_, column=1, value=label))
        c = ln.cell(row=rr_, column=2, value=value)
        style(c, align="right", fmt=fmt)
        return rr_

    lrow(3, "Loan Amount", "=Proforma!C{}".format(R["loan"]), USD)
    lrow(4, "Interest Rate", fin["rate"], PCT)
    lrow(5, "Amortization (years)", int(fin["years"]), NUM)
    lrow(6, "Interest-Only (months)", int(fin["io_months"]), NUM)
    style(ln.cell(row=7, column=1, value="Monthly Payment (P&I)"), bold=True)
    style(ln.cell(row=7, column=2, value="=-PMT(B4/12,(B5*12)-B6,B3)"), bold=True, align="right", fmt=USD2)
    style(ln.cell(row=8, column=1, value="Monthly Payment (interest-only)"))
    style(ln.cell(row=8, column=2, value="=B3*B4/12"), align="right", fmt=USD2)
    style(ln.cell(row=10, column=1, value="Annual Debt Service"), bold=True, fill=LIGHT)
    # interest-only if IO covers the whole first year, else level P&I × 12
    style(ln.cell(row=10, column=2, value="=IF(B6>=12,B8*12,B7*12)"), bold=True, align="right", fmt=USD, fill=LIGHT)

    # End-of-year balance table (years 1..10) using FV/cumulative — simple, transparent.
    style(ln.cell(row=12, column=1, value="End of Year"), bold=True)
    style(ln.cell(row=12, column=2, value="Loan Balance"), bold=True, align="right")
    base = M["financing"]["loan"]
    bal_map, _ = amortization_balances(base, fin["rate"], fin["years"], fin["io_months"])
    for yr in range(1, 11):
        rr3 = 12 + yr
        style(ln.cell(row=rr3, column=1, value=yr), align="right")
        style(ln.cell(row=rr3, column=2, value=round(bal_map.get(yr * 12, 0.0), 2)), align="right", fmt=USD)

    # ===================== ASSUMPTIONS sheet =====================
    asm = wb.create_sheet("Assumptions")
    asm.sheet_view.showGridLines = False
    asm.column_dimensions["A"].width = 30
    asm.column_dimensions["B"].width = 14
    asm.column_dimensions["C"].width = 50
    style(asm.cell(row=1, column=1, value="Editable Assumptions"), bold=True, size=14, color=WHITE, fill=ACCENT)
    for col in (2, 3):
        asm.cell(row=1, column=col).fill = PatternFill("solid", fgColor=ACCENT)
    A = M["assumptions"]
    asm_rows = [
        ("Vacancy rate", A["vacancy"], PCT, "Applied to gross market rent in the Proforma column"),
        ("Management % of EGI", A["mgmt_pct"], PCT, "Proforma management fee"),
        ("Repairs & Maint % of EGI", A["rm_pct"], PCT, "Proforma R&M reserve"),
        ("Income growth / yr", A["income_growth"], PCT, "Projection: annual revenue growth"),
        ("Expense growth / yr", A["expense_growth"], PCT, "Projection: annual expense growth"),
        ("Appreciation / yr", A["appreciation"], PCT, "Projection: property value growth"),
    ]
    rr4 = 3
    for label, val, fmt, note in asm_rows:
        style(asm.cell(row=rr4, column=1, value=label))
        style(asm.cell(row=rr4, column=2, value=val), align="right", fmt=fmt)
        style(asm.cell(row=rr4, column=3, value=note), size=9, color=GREY, italic=True)
        rr4 += 1

    # ===================== SUMMARY sheet (dashboard) =====================
    sm = wb.create_sheet("Summary")
    wb.move_sheet("Summary", -(len(wb.sheetnames) - 1))  # make it first
    sm.sheet_view.showGridLines = False
    for col, w in zip("ABCDEFGHIJKLM", [2] + [12] * 12):
        sm.column_dimensions[col].width = w

    style(sm["B2"], bold=True, size=18, color=WHITE, fill=ACCENT)
    sm["B2"] = p["address"]
    for c in "CDEFGHIJKLM":
        sm[f"{c}2"].fill = PatternFill("solid", fgColor=ACCENT)
    sm.merge_cells("B2:M2")
    style(sm["B3"], size=10, color=GREY)
    sm["B3"] = sub
    sm.merge_cells("B3:M3")
    style(sm["B4"], size=8, italic=True, color=GREY)
    sm["B4"] = "Each card: large figure = Proforma · small figure = Current (T12 actual)"
    sm.merge_cells("B4:M4")

    # KPI band — six cards, each two columns wide: label (r6), Proforma value (r7), Current value (r8)
    kpis = [
        ("NOI", f'Proforma!D{R["noi"]}', f'Proforma!C{R["noi"]}', USD),
        ("Cap Rate", f'Proforma!D{R["cap"]}', f'Proforma!C{R["cap"]}', PCT),
        ("DSCR", f'Proforma!D{R["dscr"]}', f'Proforma!C{R["dscr"]}', '0.00'),
        ("Cash-on-Cash", f'Proforma!D{R["coc"]}', f'Proforma!C{R["coc"]}', PCT),
        ("Cash Flow / Yr", f'Proforma!D{R["fcf_y"]}', f'Proforma!C{R["fcf_y"]}', USD),
        ("Price / Door", f'Proforma!D{R["ppd"]}', f'Proforma!C{R["ppd"]}', USD),
    ]
    for i, (label, pro_ref, cur_ref, fmt) in enumerate(kpis):
        c1 = 2 + 2 * i
        c2 = c1 + 1
        L, Rr = get_column_letter(c1), get_column_letter(c2)
        for rr_, val, kw in (
            (6, label, dict(size=9, bold=True, color=GREY, align="center", fill=LIGHT)),
            (7, f'={pro_ref}', dict(size=15, bold=True, color=ACCENT, align="center", fill=LIGHT, fmt=fmt)),
            (8, f'={cur_ref}', dict(size=9, color=GREY, align="center", fill=LIGHT, fmt=fmt + '" cur"')),
        ):
            sm.merge_cells(f"{L}{rr_}:{Rr}{rr_}")
            style(sm.cell(row=rr_, column=c1, value=val), **kw)
            sm.cell(row=rr_, column=c2).fill = PatternFill("solid", fgColor=LIGHT)

    # --- dashboard charts (rendered as images → exact layout, no overlap) ---
    tmpdir = tempfile.mkdtemp(prefix="rpa_charts_")
    try:
        pngs = _save_chart_pngs(M, tmpdir)
        if pngs:
            try:
                from openpyxl.drawing.image import Image as XLImage
                grid = [("exp", "B10"), ("income", "H10"), ("cashflow", "B27"), ("equity", "H27")]
                for key, cell in grid:
                    if key in pngs:
                        img = XLImage(pngs[key])
                        img.width, img.height = 440, 300
                        img.anchor = cell
                        sm.add_image(img)
            except Exception:
                pass  # image support unavailable — ship the workbook without chart images

        # data-completeness banner (Tier 2/3)
        comp = M["completeness"]
        if comp.get("tier", 1) != 1 or comp.get("missing"):
            msg = "DATA COMPLETENESS · Tier {} — still needed: {}".format(
                comp.get("tier", "?"), ", ".join(comp.get("missing", [])) or "see notes")
            style(sm["B44"], bold=True, color="9A3B2E")
            sm["B44"] = msg
            sm.merge_cells("B44:M44")

        sm.print_area = "B2:M45"
        sm.page_setup.orientation = "landscape"
        sm.page_setup.fitToWidth = 1
        sm.page_setup.fitToHeight = 1
        sm.sheet_properties.pageSetUpPr = openpyxl.worksheet.properties.PageSetupProperties(fitToPage=True)

        wb.save(path)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
    return path


# --------------------------------------------------------------------------
# PDF report (matplotlib — BiggerPockets-style visuals)
# --------------------------------------------------------------------------
def _money(v):
    return ("-$" if v < 0 else "$") + "{:,.0f}".format(abs(v))


def build_pdf(M, path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.backends.backend_pdf import PdfPages
    from matplotlib.patches import FancyBboxPatch

    green = "#1F4E46"
    green2 = "#3E7D6A"
    light = "#EAF1EE"
    grey = "#6B6B6B"
    pie_colors = ["#1F4E46", "#3E7D6A", "#6FA292", "#A7C7BC", "#C9803A", "#D9A566",
                  "#8A8D91", "#B9BCC0", "#5B6E8C", "#9FB0C9", "#7A5C7B", "#B49AB5"]
    p = M["property"]

    with PdfPages(path) as pdf:
        # ---------- Page 1: dashboard ----------
        fig = plt.figure(figsize=(11, 8.5))
        fig.patch.set_facecolor("white")

        # header band
        hb = fig.add_axes([0, 0.92, 1, 0.08]); hb.axis("off")
        hb.add_patch(plt.Rectangle((0, 0), 1, 1, color=green))
        hb.text(0.04, 0.60, p["address"], color="white", fontsize=17, fontweight="bold", va="center")
        sub = " · ".join([x for x in [p["type"], f'{p["units"]} unit(s)', f'Analysis {p["date"]}'] if x and "unit" not in x or p["units"]])
        sub = " · ".join([x for x in [p["type"], f'{p["units"]} unit(s)', f'Analysis {p["date"]}'] if x])
        hb.text(0.04, 0.20, sub, color="#D5E3DD", fontsize=9, va="center")

        # KPI band (proforma headline, current as small sub-line)
        rc, rp = M["ret_current"], M["ret_proforma"]
        fin = M["financing"]
        kpis = [
            ("NOI", _money(M["noi_proforma"]), _money(M["noi_current"]) + " cur"),
            ("Cap Rate", f'{rp["cap_rate"]*100:.2f}%', f'{rc["cap_rate"]*100:.2f}% cur'),
            ("DSCR", f'{rp["dscr"]:.2f}', f'{rc["dscr"]:.2f} cur'),
            ("Cash-on-Cash", f'{rp["cash_on_cash"]*100:.2f}%', f'{rc["cash_on_cash"]*100:.2f}% cur'),
            ("Cash Flow/Yr", _money(rp["fcf_year"]), _money(rc["fcf_year"]) + " cur"),
            ("Price/Door", _money(M["price_per_door"]), f'{p["units"]} doors'),
        ]
        n = len(kpis)
        gap = 0.012
        w = (1 - 0.08 - (n - 1) * gap) / n
        for i, (lab, val, sub2) in enumerate(kpis):
            x = 0.04 + i * (w + gap)
            ax = fig.add_axes([x, 0.78, w, 0.11]); ax.axis("off")
            ax.add_patch(FancyBboxPatch((0, 0), 1, 1, boxstyle="round,pad=0.02",
                                        facecolor=light, edgecolor=green, linewidth=0.8))
            ax.text(0.5, 0.78, lab, ha="center", va="center", fontsize=8.5, color=grey)
            ax.text(0.5, 0.44, val, ha="center", va="center", fontsize=15, color=green, fontweight="bold")
            ax.text(0.5, 0.16, sub2, ha="center", va="center", fontsize=7, color=grey)

        # expense pie
        exp = [e for e in M["expense_lines"] if e["proforma"] > 0]
        axp = fig.add_axes([0.05, 0.43, 0.26, 0.30])
        if exp:
            axp.pie([e["proforma"] for e in exp], labels=[e["label"] for e in exp],
                    autopct="%1.0f%%", colors=pie_colors[:len(exp)],
                    textprops={"fontsize": 6.0}, pctdistance=0.75,
                    wedgeprops={"linewidth": 0.5, "edgecolor": "white"})
        axp.set_title("Operating Expenses (Proforma)", fontsize=9.5, color=green, fontweight="bold")

        # income pie
        inc = M["income"]
        islices = [("Net Rental", inc["rent_proforma"] + inc["vac_proforma"])] + \
                  [(o["label"], o["proforma"]) for o in inc["other"] if o["proforma"] > 0]
        axi = fig.add_axes([0.37, 0.43, 0.26, 0.30])
        axi.pie([s[1] for s in islices], labels=[s[0] for s in islices],
                autopct="%1.0f%%", colors=pie_colors[:len(islices)],
                textprops={"fontsize": 6.0}, pctdistance=0.75,
                wedgeprops={"linewidth": 0.5, "edgecolor": "white"})
        axi.set_title("Income (Proforma)", fontsize=9.5, color=green, fontweight="bold")

        # projection line chart (income/exp/cashflow)
        proj = M["projection"]
        yrs = [pr["year"] for pr in proj]
        axl = fig.add_axes([0.70, 0.46, 0.26, 0.27])
        axl.plot(yrs, [pr["income"] for pr in proj], marker="o", ms=3, color=green, label="Income")
        axl.plot(yrs, [pr["expenses"] for pr in proj], marker="o", ms=3, color="#C9803A", label="Expenses")
        axl.plot(yrs, [pr["cash_flow"] for pr in proj], marker="o", ms=3, color=green2, label="Cash Flow")
        axl.legend(fontsize=6.5, loc="upper left")
        axl.set_title("Projection ($/yr)", fontsize=9.5, color=green, fontweight="bold")
        axl.tick_params(labelsize=6.5)
        axl.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f'{v/1000:.0f}k'))
        for s in ("top", "right"):
            axl.spines[s].set_visible(False)

        # Current vs Proforma table
        axt = fig.add_axes([0.05, 0.05, 0.58, 0.33]); axt.axis("off")
        rows = [
            ["Rental Income", _money(inc["rent_current"]), _money(inc["rent_proforma"])],
            ["Vacancy & Credit Loss", _money(inc["vac_current"]), _money(inc["vac_proforma"])],
        ]
        for o in inc["other"]:
            rows.append([o["label"], _money(o["current"]), _money(o["proforma"])])
        rows.append(["Effective Gross Income", _money(inc["egi_current"]), _money(inc["egi_proforma"])])
        rows.append(["Total Operating Expenses", _money(M["opex_current"]), _money(M["opex_proforma"])])
        rows.append(["Net Operating Income", _money(M["noi_current"]), _money(M["noi_proforma"])])
        rows.append(["Annual Debt Service", _money(fin["annual_ds"]), _money(fin["annual_ds"])])
        rows.append(["Free Cash Flow", _money(rc["fcf_year"]), _money(rp["fcf_year"])])
        tbl = axt.table(cellText=rows, colLabels=["Line Item", "Current", "Proforma"],
                        loc="upper center", cellLoc="left", colWidths=[0.5, 0.25, 0.25])
        tbl.auto_set_font_size(False)
        tbl.set_fontsize(8)
        tbl.scale(1, 1.35)
        bold_rows = {"Effective Gross Income", "Net Operating Income", "Free Cash Flow"}
        for (r, cc), cell in tbl.get_celld().items():
            cell.set_edgecolor("#E2E2E2")
            if r == 0:
                cell.set_facecolor(green); cell.set_text_props(color="white", fontweight="bold")
            elif rows[r - 1][0] in bold_rows:
                cell.set_facecolor(light); cell.set_text_props(fontweight="bold")

        # financing summary box
        axf = fig.add_axes([0.66, 0.05, 0.30, 0.33]); axf.axis("off")
        axf.text(0, 1.0, "Acquisition & Financing", fontsize=9.5, color=green, fontweight="bold", va="top")
        flines = [
            ("Purchase Price", _money(fin["price"])),
            ("Loan Amount", _money(fin["loan"]) + f'  ({fin["ltv"]*100:.0f}% LTV)'),
            ("Down Payment", _money(fin["down"])),
            ("Total Cash Needed", _money(fin["cash_needed"])),
            ("Interest Rate", f'{fin["rate"]*100:.3f}%'),
            ("Amortization", f'{int(fin["years"])} yrs'),
            ("Monthly P&I", _money(fin["monthly_pi"])),
            ("GRM", f'{M["grm"]:.1f}'),
        ]
        y = 0.86
        for lab, val in flines:
            axf.text(0.0, y, lab, fontsize=8, color=grey, va="top")
            axf.text(1.0, y, val, fontsize=8, color="#141414", va="top", ha="right", fontweight="bold")
            y -= 0.11

        # completeness note
        comp = M["completeness"]
        if comp.get("tier", 1) != 1 or comp.get("missing"):
            fig.text(0.05, 0.018, "Data completeness: Tier {} — still needed: {}".format(
                comp.get("tier", "?"), ", ".join(comp.get("missing", [])) or "see notes"),
                fontsize=7.5, color="#9A3B2E", style="italic")
        fig.text(0.96, 0.018, "Generated " + p["date"], fontsize=7, color=grey, ha="right")
        pdf.savefig(fig, facecolor="white")
        plt.close(fig)

        # ---------- Page 2: equity build + projection table ----------
        fig2 = plt.figure(figsize=(11, 8.5))
        hb = fig2.add_axes([0, 0.92, 1, 0.08]); hb.axis("off")
        hb.add_patch(plt.Rectangle((0, 0), 1, 1, color=green))
        hb.text(0.04, 0.5, "Long-Term Projection", color="white", fontsize=16, fontweight="bold", va="center")

        ax2 = fig2.add_axes([0.07, 0.52, 0.86, 0.33])
        ax2.plot(yrs, [pr["value"] for pr in proj], marker="o", ms=3, color=green, label="Property Value")
        ax2.plot(yrs, [pr["equity"] for pr in proj], marker="o", ms=3, color=green2, label="Equity")
        ax2.plot(yrs, [pr["loan_balance"] for pr in proj], marker="o", ms=3, color="#C9803A", label="Loan Balance")
        ax2.legend(fontsize=8)
        ax2.set_title("Equity · Loan Balance · Property Value", fontsize=10, color=green, fontweight="bold")
        ax2.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f'${v/1000:.0f}k'))
        ax2.tick_params(labelsize=8)
        ax2.set_xlabel("Year", fontsize=8)
        for s in ("top", "right"):
            ax2.spines[s].set_visible(False)

        axt2 = fig2.add_axes([0.07, 0.07, 0.86, 0.38]); axt2.axis("off")
        cols = ["Year"] + [str(pr["year"]) for pr in proj]
        def fmt_row(label, key, money=True, pct=False):
            out = [label]
            for pr in proj:
                v = pr[key]
                out.append(_money(v) if money else (f'{v*100:.1f}%' if pct else f'{v:,.0f}'))
            return out
        trows = [
            fmt_row("Income", "income"),
            fmt_row("Expenses", "expenses"),
            fmt_row("NOI", "noi"),
            fmt_row("Cash Flow", "cash_flow"),
            fmt_row("Cash-on-Cash", "coc", money=False, pct=True),
            fmt_row("Property Value", "value"),
            fmt_row("Loan Balance", "loan_balance"),
            fmt_row("Equity", "equity"),
        ]
        tbl2 = axt2.table(cellText=trows, colLabels=cols, loc="upper center", cellLoc="center")
        tbl2.auto_set_font_size(False)
        tbl2.set_fontsize(7.5)
        tbl2.scale(1, 1.4)
        for (r, cc), cell in tbl2.get_celld().items():
            cell.set_edgecolor("#E2E2E2")
            if r == 0:
                cell.set_facecolor(green); cell.set_text_props(color="white", fontweight="bold")
            elif cc == 0:
                cell.set_text_props(fontweight="bold"); cell.set_facecolor(light)
        a = M["assumptions"]
        fig2.text(0.07, 0.03, "Assumptions: income +{:.0f}%/yr · expenses +{:.0f}%/yr · appreciation +{:.0f}%/yr · vacancy {:.0f}% · mgmt {:.0f}% · R&M {:.0f}%".format(
            a["income_growth"]*100, a["expense_growth"]*100, a["appreciation"]*100,
            a["vacancy"]*100, a["mgmt_pct"]*100, a["rm_pct"]*100), fontsize=7.5, color=grey, style="italic")
        pdf.savefig(fig2, facecolor="white")
        plt.close(fig2)
    return path


# --------------------------------------------------------------------------
def slugify(s):
    s = re.sub(r"[^A-Za-z0-9]+", "-", s or "").strip("-").lower()
    return s or "rental-property"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model", help="Path to the normalized JSON model")
    ap.add_argument("--outdir", default=".")
    ap.add_argument("--basename", default=None)
    ap.add_argument("--no-pdf", action="store_true")
    args = ap.parse_args()

    with open(args.model) as f:
        raw = json.load(f)
    M = compute_model(raw)

    os.makedirs(args.outdir, exist_ok=True)
    base = args.basename or slugify(M["property"]["address"]) + "-proforma"
    xlsx_path = os.path.join(args.outdir, base + ".xlsx")
    build_workbook(M, xlsx_path)
    print("XLSX:", os.path.abspath(xlsx_path))

    if not args.no_pdf:
        try:
            pdf_path = os.path.join(args.outdir, base + ".pdf")
            build_pdf(M, pdf_path)
            print("PDF:", os.path.abspath(pdf_path))
        except ImportError:
            print("PDF: skipped (matplotlib not installed — `pip install matplotlib`, or open the "
                  "workbook's Summary sheet and Print → Save as PDF)")

    # machine-readable echo of headline numbers (handy for the chat summary)
    print("HEADLINE:", json.dumps({
        "noi_current": round(M["noi_current"], 2), "noi_proforma": round(M["noi_proforma"], 2),
        "cap_current": round(M["ret_current"]["cap_rate"], 4), "cap_proforma": round(M["ret_proforma"]["cap_rate"], 4),
        "dscr_proforma": round(M["ret_proforma"]["dscr"], 3),
        "coc_proforma": round(M["ret_proforma"]["cash_on_cash"], 4),
        "fcf_year_proforma": round(M["ret_proforma"]["fcf_year"], 2),
    }))


if __name__ == "__main__":
    main()
```

## Excel dump helper

Save this block verbatim as `dump_xlsx.py` when an input arrives as `.xlsx`. Usage:
`python3 dump_xlsx.py FILE.xlsx [--sheet NAME] [--max-rows N]`.

```python
#!/usr/bin/env python3
"""
Dump an .xlsx (rent roll / T12 / loan tab) to plain text so it can be read and
mapped into the pro forma model.

Usage:
    python3 dump_xlsx.py FILE.xlsx [--sheet NAME] [--max-rows N]

Prints every non-empty cell as `COORD=value`, one row per line, per sheet.
Needs openpyxl:  python3 -m pip install --quiet openpyxl
"""
import argparse
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--sheet", default=None, help="Only dump this sheet")
    ap.add_argument("--max-rows", type=int, default=400)
    args = ap.parse_args()

    try:
        import openpyxl
    except ImportError:
        sys.exit("openpyxl not installed — run: python3 -m pip install --quiet openpyxl")

    wb_v = openpyxl.load_workbook(args.path, data_only=True)   # computed values
    wb_f = openpyxl.load_workbook(args.path, data_only=False)  # formulas
    print(f"FILE: {args.path}")
    print(f"SHEETS: {wb_v.sheetnames}")

    names = [args.sheet] if args.sheet else wb_v.sheetnames
    for name in names:
        if name not in wb_v.sheetnames:
            print(f"\n(skip — no sheet named {name!r})")
            continue
        ws, wsf = wb_v[name], wb_f[name]
        print(f"\n{'='*70}\nSHEET: {name!r}  dims={ws.dimensions}  rows={ws.max_row} cols={ws.max_column}\n{'='*70}")
        for i, row in enumerate(ws.iter_rows()):
            if i >= args.max_rows:
                print(f"... (truncated at {args.max_rows} rows; pass --max-rows to see more)")
                break
            cells = []
            for c in row:
                if c.value is None:
                    continue
                formula = wsf[c.coordinate].value
                if isinstance(formula, str) and formula.startswith("="):
                    cells.append(f"{c.coordinate}={c.value!r} [{formula}]")
                else:
                    cells.append(f"{c.coordinate}={c.value!r}")
            if cells:
                print(" | ".join(cells))


if __name__ == "__main__":
    main()
```
