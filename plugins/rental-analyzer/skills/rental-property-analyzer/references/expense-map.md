# T12 Mapping Guide

A T12 (trailing-12 operating statement) comes in many formats — RealPage, Yardi, AppFolio,
QuickBooks, or a broker's spreadsheet — often with GL account numbers and dozens of sub-lines. Map
each line into the standard model buckets below. Use the **annual total** column (the trailing-12
sum), not a single month.

## Revenue → `income`

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

## Expenses → `expenses`

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

### Notes & judgment calls

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

## Quick worked example (RealPage-style export → buckets)

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
