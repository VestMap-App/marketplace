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

The numbers are computed **once** by `scripts/build_proforma.py`; the workbook writes live formulas
and the PDF draws the computed values, so the two always agree.

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
run `scripts/dump_xlsx.py <file>` to dump every cell as text, then read it.

## Workflow

1. **Confirm you have the inputs.** If the user only described the deal, ask for the rent roll, T12,
   and loan/purchase terms. If they don't have them, follow **Missing-input handling** below — do not
   invent numbers.

2. **Parse the documents into the model.** Read each file (use `dump_xlsx.py` for Excel) and extract
   into the normalized JSON in `references/data-model.md`. Map messy T12 line items / GL accounts to
   the standard expense buckets using `references/expense-map.md`. Use `references/sample-model.json`
   as a copy-and-edit template.
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

4. **Ensure dependencies, then build.** The script needs `openpyxl` (always) and `matplotlib` (for
   the PDF). Install quietly if missing, then run:
   ```bash
   python3 -m pip install --quiet openpyxl matplotlib
   python3 scripts/build_proforma.py MODEL.json --outdir .
   ```
   It prints `XLSX:`, `PDF:`, and a `HEADLINE:` JSON of the key numbers.

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
you may pull median rent, property-tax, and market context for the address and use them to fill the
`market_rent` column or annotate assumptions. Always label these as estimates in the notes, and
never block the build waiting on VestMap. If it's not connected, ignore this entirely.

## Output files

- `<address-slug>-proforma.xlsx` — Summary (dashboard) · Proforma · Rent Roll · T12 · Loan · Assumptions.
- `<address-slug>-proforma.pdf` — 2-page visual report.

Both land in the working directory (or `--outdir`).

## Reference files

| File | Load when |
|---|---|
| `references/data-model.md` | Always — the JSON schema + computation rules the script expects. |
| `references/expense-map.md` | When parsing a T12 — maps GL accounts / line-item names to standard buckets. |
| `references/sample-model.json` | A complete, runnable example to copy and adapt. |

## What this skill does NOT do

- Does not fabricate rents, expenses, or deal terms to fill a gap (it guides the user to the source).
- Does not require any API, MCP, or internet — pure local parse → compute → render.
- Does not give buy/sell advice or qualitative verdicts — it lays out the numbers; the investor decides.
- Does not depend on Chrome or LibreOffice (the PDF is built with matplotlib).
