# Data Model

`build_proforma.py` consumes one JSON object. Extract the source documents into this shape, then
run the script. Everything below is what the script reads — fields not listed are ignored.

All money is **annual dollars** unless noted. Percentages may be written as `0.05` or `"5%"` (both
parse). Numbers may include `$`/`,` (e.g. `"$1,234"`). Missing/blank → treated as 0.

## Top-level shape

```json
{
  "property":   { ... },
  "rent_roll":  [ { per-unit }, ... ],
  "income":     { ... },
  "expenses":   { ... },
  "financing":  { ... },
  "assumptions":{ ... },
  "t12":        { ... },        // optional: renders the T12 tab
  "notes":      { ... },        // optional: inline note per expense key
  "data_completeness": { ... }  // optional: tier + missing list
}
```

## `property`
```json
{ "address": "6331 N Wyandotte St", "name": "", "property_type": "Fourplex",
  "units": 4, "analysis_date": "2026-05-20" }
```
`units` = door count (drives price/door and cash flow/unit). `analysis_date` defaults to today.

## `rent_roll` (array, one object per unit)
```json
{ "unit": "101", "type": "2 bd 1 ba", "sqft": 1050,
  "current_rent": 1585, "market_rent": 1675, "status": "occupied", "notes": "" }
```
- `current_rent` / `market_rent` are **monthly**. Vacant units: `current_rent: 0`, `status: "vacant"`.
- Include commercial units too (e.g. a ground-floor retail tenant) — just set their rents.
- The script sums these: **Proforma rental income = Σ market_rent × 12** (used when
  `income.rental_income.proforma` is not given).

## `income`
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

## `expenses`
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

Map raw T12 line items into these buckets with `expense-map.md`.

## `financing`
```json
{ "purchase_price": 499000, "ltv": 0.75, "loan_amount": null,
  "interest_rate": 0.065, "amortization_years": 30, "interest_only_months": 0,
  "closing_costs": 0, "repair_costs": 0, "loan_fees": 0 }
```
- `loan_amount` — give it directly (e.g. from the loan-amortization tab) **or** leave `null` to
  compute `purchase_price × ltv`.
- Down payment = price − loan. Total cash needed = down + closing + repair + loan fees.
- Debt service = monthly P&I × 12 (interest-only if `interest_only_months ≥ 12`).

## `assumptions`
```json
{ "vacancy_rate": 0.05, "management_pct": 0.08, "repairs_pct": 0.05,
  "income_growth": 0.02, "expense_growth": 0.02, "appreciation": 0.03,
  "projection_years": [1, 2, 5, 10, 15, 20, 30] }
```
Defaults shown; override only when the user gives different numbers.

## `t12` (optional — renders the T12 tab)
```json
{ "period": "Apr 2025 – Mar 2026 (Trailing 12)",
  "rows": [ { "label": "Total Revenue", "annual": 486141.64, "total": true },
            { "label": "Management Fees", "annual": 26710.35 } ] }
```
`total: true` bolds the row. Include it so the workbook shows the trailing-12 evidence base.

## `notes` (optional)
`{ "management": "actuals; 8% of gross", "general_admin": "incl. dues offset by parking" }` — keys
match expense bucket names; the note prints in the Proforma's notes column.

## `data_completeness` (optional)
`{ "tier": 1, "missing": [], "flags": [] }` — set `tier` 2/3 and list `missing` items when inputs are
incomplete; the script stamps a visible note on the workbook and PDF.

## Computation summary (what the script derives)

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
