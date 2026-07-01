# OM Page Layout

Visual rules for turning data into a page that reads like an OM — not a dashboard, not a brief. Market-agnostic, PDF-first.

---

## 1. Page Structure

Self-contained HTML → exported to PDF via headless Chrome (§9). Letter-size, vertical. Default: **3 pages** — the per-section thematic maps (§3.5a) make each mapped section ~2.4in tall, so the comparison sections split across two sheets (page 1: hero + context; page 2: Population / Income / Housing; page 3: Rental / Workforce / Safety). Opt-in modules add page 4+. Rebalance the breaks if the R9/R11 sweep drops sections — never let a `.page` overflow (§3.5a, §6).

```
┌─ Page 1 ───────────────────────────────────────┐
│  Header strip: LOCATION BRIEF + address        │
│  (full-bleed --accent band)                    │
│                                                 │
│  Summary table │ Map (two-up, blank ESRI base) │
│                                                 │
│  Context band: HHI Block │ PopGr ZIP │ MSA      │
└─────────────────────────────────────────────────┘
┌─ Page 2 ───────────────────────────────────────┐
│  Population Profile   (4-col) │ Expansion map   │
│  Income Profile       (4-col) │ Income map      │
│  Housing Values       (4-col) │ HPI map         │
└─────────────────────────────────────────────────┘
┌─ Page 3 ───────────────────────────────────────┐
│  Rental Market        (4-col, no map)          │
│  Workforce            (4-col + stacked bars)   │
│  Safety / Crime       (3×3 grid) │ Crime map    │
│                                                 │
│  Minimal footer (sources + timestamp only)      │
└─────────────────────────────────────────────────┘
┌─ Page 4+ (opt-in only) ────────────────────────┐
│  Risk / Schools / Education / … modules        │
└─────────────────────────────────────────────────┘
```

CSS:
```css
@page { size: Letter; margin: 0.4in; }
.page { page-break-after: always; }
.page:last-of-type { page-break-after: auto; }
```

---

## 2. Cross-Scale Comparison Visualization (core pattern)

Every 4-scale default section uses the same comparison row.

### Pattern

Each metric = one horizontal strip:
- Label on the left (~18% of row width)
- Four equal-width cells: Block → Tract → ZIP → County
- One delta chip under each value cell (except the leftmost) showing Δ vs its left neighbor

```
┌──────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Median HHI       │  $72.5k  │  $68.2k  │  $65.4k  │  $64.9k  │
│                  │          │  −$4.3k  │  −$2.8k  │  −$0.5k  │
│                  │          │  −6.0%   │  −4.1%   │  −0.8%   │
└──────────────────┴──────────┴──────────┴──────────┴──────────┘
```

**Chip contents — one value per cell, one unit per metric type:**
- Currency / counts: relative Δ only, as a `%` signed (`+61%`, `−18%`). Never abs + rel together.
- Percentages / rates: absolute Δ in `pp` only, signed (`−8.3 pp`, `+1.9 pp`). `pp` because adding a `%` delta on top of a value that is already a `%` is ambiguous.

**Chip color — muted only.** Every chip uses the same neutral background (`--neutral-chip`) with muted text (`--muted`). No green, no red. The sign carries the direction; the reader's eye does the interpretation (R10 — no value judgments).

**Presence rule.** Every non-first-column **current-value comparable**
cell renders one chip when both the cell and its left-neighbor are
non-null. Forecast rows (HHI 2029, HV 2029, Renter 2029) and raw-count
rows (Renter units, Owner units, Per capita income) render values only
— no chips. The chip carries cross-scale comparison; for a forecast or
a raw count, the bare value is the signal.

**Population Profile is the exception.** That section renders raw values
only, no chips at all — the four-column spread alone carries the
comparison.

### Omission rules (strict)

- Null value cell → cell `display: none`, its chip dropped (R11)
- Row with fewer than 2 non-null cells → whole `<tr>` removed from DOM
- Section with fewer than 2 rows remaining → whole `<section>` removed
- **NEVER** show `—`, `N/A`, "data unavailable", or similar placeholder text
- **NEVER** annotate which cells dropped or why

### Scale header

At the top of each 4-col section: `Block · Tract · ZIP · County`. Same header across ALL 4-col sections in every OM.

---

## 3. Per-Section Layout Patterns

### 3.1 Header strip + summary/map row

Top of page 1 has two horizontal bands:

1. **Page-header strip** — full-bleed dark-green band (`background: var(--accent)`, `color:#fff`), ~1.4" tall. Contains uppercase label `LOCATION BRIEF` (28pt/700, letter-spacing 0.02em) and, directly below it, the address in 13pt/400 at 85% opacity white. Nothing else. See §Styling.
2. **Two-up row** — immediately below the header strip: summary table on the left (locality line + any subject-level identifiers the template surfaces), and on the right a Leaflet map on a **blank ESRI base** (`Canvas/World_Light_Gray_Base` — a clean, near-empty basemap so the subject pin/address reads clearly) in a neutral card. If geocoding fails the `.hero__map` div is removed AND the template's map script adds `.no-map` to `.summary-row`, collapsing it to a single column so the summary card spans the full width. Never leave the right column empty — the page reads as "off center" if you do.

**Map-ready signal (PDF capture timing).** The template script sets `document.documentElement.dataset.mapReady = 'true'` once the initial visible tile batch has rendered (via `L.TileLayer`'s `load` event, debounced by two `requestAnimationFrame` calls so the compositor has a frame to paint). It also fires the same signal immediately if geocoding fails or Leaflet is missing, and a hard 12-second failsafe is set on page load so the export can never stall forever. The headless-Chrome export waits for this attribute before snapshotting — without it, the PDF captures a blank tile grid. See §9.

**Header strip must NOT contain:** "Offering Memorandum" or any document-type label; Tapestry pill / segment name; safety label pill.

### 3.2 Context band (3 callouts)

Immediately below the hero.

Fixed slot content per `SKILL.md §O7`:

1. **Median HHI · Block** — value: `${{HHI_BLOCK}}`, source: `get_section_data("income").median_household_income.block`
2. **Pop Growth · ZIP, 5-yr CAGR** — value: `{{POPGR_ZIP}}%`, source: `get_section_data("expansion").zip`
3. **MSA** — value: `{{MSA_NAME}}` verbatim (full string as returned by the CBSA layer), slightly smaller font (16pt) and 600-weight since MSA names are long strings, not big numbers.

If any slot's underlying data is null, remove that callout cell. The grid auto-widens remaining cells. Never say "data unavailable".

### 3.3 Population / Income / Housing / Rental / Workforce

Standard 4-col comparison pattern (§2). Section header with label + scale-header sub-label.

### 3.4 Workforce specifics

Above the stacked bars: 4-col collar-share strip (white-collar % and blue-collar %). Below: one horizontal stacked bar per scale showing Mgmt / Sales / Prod / Cons as normalized segments. If the user opted into "all 13 occupations", swap the 4-bar chart for a 13-segment bar; keep the collar-share strip unchanged.

### 3.5 Safety / Crime

Block Group raw counts from VestMap: 3×3 grid. Hidden cells if null. Per-capita line only if `TOTPOP_CY` at Block returned (R11). No ZIP/City/State crime-index comparison — VestMap's crime endpoint is Block-Group only.

### 3.5a Per-section thematic maps (two-up · VestMap `show_map`)

Sections with a matching VestMap layer show a thematic map **beside** the data. See `SKILL.md §O8b` for the data flow; this is the visual contract.

**Which sections carry a map:**

| Section | `show_map` label | Notes |
|---|---|---|
| Population Profile | `Expansion` | the "population growth" map |
| Income Profile | `Income` | median-HHI choropleth |
| Housing Values | `House Price Index` | note the `hpi` enum → this label |
| Safety | `Crime` | |
| Schools (opt-in) | `Schools` | only when the Schools module is on |
| Rental Market, Workforce | — | **no layer → no map**, full-width as before |

**Markup.** A mapped section adds the `section--mapped` class, wraps its existing header + table in `.section__body` (left), and adds a `.section__map` card (right) holding `<a href="{share_url}"><img src="file://…snapshot.png"></a>`. The link keeps the interactive map reachable from the printed PDF (PDF hyperlinks survive Chrome export); the image is the permanent artifact (share links expire in 90 days).

- Grid is table-dominant (`minmax(0,1.6fr)` / `minmax(0,1fr)`) so the wide 4-scale table keeps most of the width; a scoped 12pt value font + tighter cell padding keep Block · Tract · ZIP · County legible.
- The map card is `2.4in` tall with `object-fit: cover`, which crops the VestMap SPA chrome (top bar / chat bubble) down to the map canvas + legend. Best-effort — no image post-processing dependency.

**Silent shrink (O2).** If a section has no map — no matching layer, the snapshot came back blank/failed, or links-only mode — delete the `.section__map` div **and** remove the `section--mapped` class so the section renders full-width exactly like an unmapped one. Never an empty card, never a "map unavailable" note.

**Links-only mode.** Drop `.section--mapped`/`.section__map` and put a compact affordance under the section header instead: `<div class="section__maplink"><a href="{url}">Explore {Label} map ↗</a></div>`.

**Pagination.** Map cards make Population / Income / Housing / Safety taller, so page 2 usually needs to split. A `.page` container has `overflow: hidden` — content past ~11in is **clipped, not carried**. Distribute sections across as many `<section class="page">` blocks as needed (≈2–3 mapped sections per page); never let a page overflow. This is the same "if overflow, paginate" rule as §6.

### 3.6 Footer

Last strip of last page. Single line, 9pt, muted color, 0.7 opacity. **Minimal — no audit trail, no failure notes.**

Allowed contents: `Data: VestMap · Generated YYYY-MM-DD HH:MM`. Nothing else.

**Forbidden in the footer:** VestMap call names, layer IDs, "Optional modules included: …", any text describing which data was missing or which calls failed.

---

## 4. Typography

- Font stack: `"Inter", "SF Pro Text", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`. No web-font imports.
- Address H1: 22pt / 600.
- Section headers: 16pt → 13pt.
- Body: 11pt / 400.
- Big numbers (context band): 28pt / 700, tabular-nums.
- MSA value (context slot 3): 16pt / 600 (smaller than other callouts since MSA names are multi-word strings).
- Labels: 10pt / 500, uppercase, letter-spacing 0.04em.
- 4-col cell values: 14pt / 600, tabular-nums.
- Chips: 9pt / 500.
- Footer: 9pt / 400, opacity 0.85.

`font-variant-numeric: tabular-nums` on every numeric cell.

---

## 5. Color

Restrained, market-agnostic palette. Same for every OM.

- **Ink:** `#141414`
- **Muted:** `#5E5E5E`
- **Line:** `#E4E4E4`
- **Surface:** `#FFFFFF`
- **Surface-alt:** `#F6F6F3`
- **Accent:** `#2C5F4E`
- **Caution:** `#A84532` (reserved for crime / risk emphasis)
- **Chip-pos:** `#E6EFEA` bg / `#1E4D3E` text
- **Chip-neg:** `#F4E4E0` bg / `#7A2D1F` text
- **Chip-neu:** `#EDEDE8`

Never add market- or brand-specific colors unless the user supplies them.

---

## 6. Spacing

- Page outer padding: 0.4in (via `@page`).
- Between sections: 0.22in.
- Section header → first row: 0.12in.
- Between 4-col rows: 0.08in.
- Hero bottom padding: 0.28in.

Never squeeze sections. If overflow, paginate.

---

## 6a. Styling — the locked visual language

Every rule below is **mandatory**, not aesthetic guidance. Goal: same inputs → same pixels whether the page is rendered by Opus or Sonnet. New tokens: none. New CSS classes: only the two chip classes at the end.

### Page-header strip (replaces the old split-hero)

Top ~1.4" of page 1:

- Full-bleed dark band: `background: var(--accent)`, `color:#fff`.
- Left-aligned, uppercase label `LOCATION BRIEF`, 28pt / 700, letter-spacing 0.02em.
- Address line directly below in 13pt / 400, 85% opacity white.
- Nothing else in the band. No map, no badges, no pill.

The Leaflet map moves into a neutral card to the right of the summary table one row below.

### Section headers

Every section uses the same template:

```
┌──────────────────────────────────────────┐
│  SECTION TITLE                           │  ← 11pt / 600, uppercase, --ink
│ ─────────────                             │  ← 2px --accent rule, ~40% width
└──────────────────────────────────────────┘
```

No background fill. No bubble. Remove the current `surface-alt` pill-styled header. This is the single most reused visual on the page — locking it means every section reads the same.

### Tables (`.cmp-table`)

- Remove the per-row border-top. Replace with **zebra striping**: `.cmp-row:nth-child(even) { background: var(--surface-alt); }`.
- Row height stays at current spacing — zebra alone carries the separation.
- Label column left-aligned, muted, 10pt uppercase. Value columns right-aligned, 14pt / 600, tabular-nums. Keep the chip row below the value in the same cell.
- Scale header above each `<table>` uses the same styling as a section header but at 9pt.

### Callouts (big-number cards)

Any big-number callout (context-band slots, summary-table values) uses:

- `background: var(--surface-alt)`, 6px radius.
- **Left-edge accent bar**: 3px solid `var(--accent)` on the left side only.
- Padding 14pt / 12pt. Label 9pt uppercase muted. Value 22pt / 700, letter-spacing -0.015em.

Context band becomes 3 of these in a row.

### Chips — single style, no variants

One class: `.chip`. Background `--neutral-chip` (`#EDEDE8`), text `--muted` (`#5E5E5E`). No green, no red, no categorical color-coding. The chip content carries meaning via its signed value (`+61%`, `−8.3 pp`); color adds no information.

Consequence: the Population Profile section renders raw values only — no chips. Every other 4-col section (Income, Housing, Rental, Workforce) renders exactly one chip per non-first-column cell, muted, showing `%` for currency/counts or `pp` for rates.

### Forbidden (prevents drift toward decoration)

- No gradients. No shadows (the `--line` borders already in use are the only separators).
- No icons. No SVG decoration beyond the Leaflet marker.
- No colored dividers beyond the 2px accent rule under section titles.
- No stat-circle disks.
- No background tints on rows beyond the zebra rule.
- No hover / interactive states (this is a print artifact).

---

## 7. Module Layouts (opt-in)

All modules follow the same rules: no placeholder text, R9 omission, R11 gating.

- **Risk (FEMA NRI · Tract):** Page break before. Header: `Natural Hazard Risk · Tract`. 4 callouts (`RISK_SCORE`, `RISK_RATNG`, `SOVI_SCORE`, `RESL_SCORE`) + top 5 hazards by `_RISKS` score. Omit null-rated hazards.
- **Schools (point-radius):** Header: `Nearest Schools · [District name]`. 3 vertical cards: name, distance, rating, URL. No scale comparison.
- **Education (5 buckets):** 4-col stacked-bar panel, one bar per scale. 5 segments: No HS / HS / Some College / Bachelor's / Graduate. Monochrome ramp of `--accent`. R11 gated.
- **Income Distribution (9 HINC buckets):** 4-col stacked-bar, 9 segments per bar. R11 gated.
- **All 13 occupations:** replaces the default Workforce 4-bar chart.
- **Business / MSA:** single-row callout: `Metro: [MSA name] · [N01_BUS] businesses · [N01_EMP] employees`.
- **HPI:** small sparkline or single callout, depending on response shape.

---

## 8. What NOT to do

- **No "Offering Memorandum" eyebrow** or any document-type label above the address. Just the address.
- **No Tapestry anywhere** — no segment name, no grade pill, no lifestyle callout (R5/O4).
- **No market-specific hardcoded wording** — no city names in template flavor text (O5). Market / city names appear only where they're data-driven from the subject.
- **No failure notes anywhere in the rendered output** (O2). No "module-note" class. No paragraph saying "X row dropped" or "Y omitted because …". If something's not there, it's silently not there.
- **No "N/A", "—", "data unavailable"** in empty cells. CSS `display: none` only.
- **No adjectives / prose claims** ("desirable", "up-and-coming", "affluent", "stable"). R10.
- **No filler / welcome copy.** Section headers are labels, not marketing.
- **No client-side JS for data viz.** Stacked bars are CSS `flex-basis` only. The Leaflet map is the ONLY JS on the page.
- **No sections outside the default list** (unless opt-in module triggered).
- **No mixing Tract and City** in one OM's columns.
- **No default palette overrides** without the user asking.

---

## 9. PDF Export (default output)

PDF is the default output of this skill, not HTML. After filling the template:

### Step 1 — Write the HTML

Write the rendered HTML to a temp path (still in the current working directory but with a `.html` suffix):

```
vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.html
```

### Step 2 — Convert to PDF with headless Chrome

Use the locally-installed Chrome / Chromium binary. On macOS this is
`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`. On Linux it's
typically `google-chrome`, `google-chrome-stable`, or `chromium`. Pick whichever
exists (`command -v google-chrome || command -v chromium || command -v chromium-browser`).

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --hide-scrollbars \
  --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw \
  --virtual-time-budget=20000 \
  --print-to-pdf-no-header \
  --print-to-pdf="vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.pdf" \
  "file:///absolute/path/to/vestmap-om-{zip}-{YYYYMMDD-HHMMSS}.html"
```

Notes:
- `--virtual-time-budget=20000` is the upper bound; the template fires a `data-map-ready="true"` attribute on `<html>` once Leaflet's initial tile batch has rendered (or 12s have elapsed without it). The budget exists only as a safety net — it is intentionally larger than the in-page failsafe so the JS path always wins.
- `--run-all-compositor-stages-before-draw` forces Chrome to flush the compositor before snapshotting. Without it, freshly-loaded tile PNGs are sometimes captured mid-paint as a blank/grey tile grid even when `tilelayer.on('load')` has fired. **This is the single most important flag for getting the map into the PDF reliably.**
- `--headless=new` uses the modern headless renderer, which paints external image resources more deterministically than the legacy `--headless` mode.
- `--no-pdf-header-footer` kills Chrome's default "page 1 of N" and URL footer.
- `--disable-gpu` is required on headless-macOS; harmless elsewhere.
- `--no-sandbox` allows running as root in a CI / container environment; safe to drop on a normal workstation.
- Use `file://` scheme with the absolute path, not a relative path.

#### Verifying the map actually rendered

After the PDF is written, do a quick sanity check before responding:

```bash
# PDF should be ≥ ~80 KB once the map tiles are baked in. A blank-map PDF is
# typically 15–35 KB. If it comes in under 60 KB, re-run the export once.
[ "$(stat -f%z out.pdf 2>/dev/null || stat -c%s out.pdf)" -lt 60000 ] && echo "RETRY"
```

If the second attempt is still tiny, fall through to HTML-only and tell the user
the map didn't bake — do NOT silently ship a PDF with a blank tile area.

### Step 3 — Clean up

After the PDF is generated and verified (file exists, non-zero size), delete the intermediate HTML file **and the section-map PNG snapshots** (they are baked into the PDF) unless the user explicitly asked for both. Write the snapshots to temp paths in the working directory, e.g. `vestmap-om-{zip}-{ts}-map-{label}.png`.

### Step 4 — Output the PDF path

Respond with ONLY:
- The absolute PDF path
- One sentence naming the subject address

Do not list which sections rendered. Do not mention which modules were included vs not. Do not apologize for any missing data. See `SKILL.md §O10`.

### Fallback: user asks for HTML-only

If the user says "HTML only" or "no PDF" or similar, skip Step 2–3. Output the HTML path instead.

### Fallback: Chrome not found

If `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` doesn't exist, fall back to HTML-only and tell the user once: "Chrome not found — output is HTML. To produce PDF, open the HTML in a browser and use File → Print → Save as PDF." This is the only case where HTML+instructions replace PDF by default.

---

## 9a. Section-map snapshots (VestMap `show_map`)

Section maps (§3.5a) are static PNGs snapshotted from VestMap share URLs **before** the PDF export, so the export itself stays fast — it paints images, not live tiles.

### Get the URLs
One `show_map(address)` call, no `section` (SKILL.md §O8b). Parse bullets `- **{Label}**: {url}` with `^\s*-\s+\*\*(.+?)\*\*:\s+(https://\S+)\s*$`; **match by label** (`hpi` → `House Price Index`). Use URLs verbatim — the domain is environment-dependent.

### Render each to a PNG
`scripts/render-vestmap-map.sh <share-url> <out.png>` wraps the one command empirically verified to paint the WebGL map:

```bash
chrome --headless=new --use-angle=swiftshader --no-sandbox --hide-scrollbars \
  --window-size=1280,900 --virtual-time-budget=60000 --timeout=75000 \
  --screenshot=<out.png> <share-url>
```

- `--use-angle=swiftshader` (software GL) is load-bearing: without it the WebGL map never paints in headless mode and you get a blank canvas. A plain `--headless --screenshot` does NOT work here (unlike the hero, which is Leaflet raster tiles).
- **Success heuristic:** a painted map is ~1 MB; a blank canvas ~15 KB. The script treats < 100 KB as blank, retries once, then exits non-zero. On non-zero, the caller **drops** the section's map (silent shrink, §3.5a) — it never ships a blank card.

### Run them in parallel, overlapped with data work
Launch all snapshots in the background right after `show_map` returns (cap ~4 concurrent) so they render **while** the rest of acquisition + delta computation + the R9/R11 sweep run. `wait` for them only just before the PDF export. Net added wall-clock ≈ one snapshot (up to ~60s), not the sum — and the section maps add ~0 to the export itself. This is how the feature stays within the "don't add much time" budget. In links-only mode, skip this section entirely.

---

## 10. Market-agnostic rendering

Every OM renders identically regardless of market. Layout, colors, typography, spacing, and wording do not change based on the subject's location. The only places a market name appears on the page are the subject address (H1), the locality line (City, State · County · ZIP), and the MSA callout in the context band — all three data-driven from the geocoded subject.
