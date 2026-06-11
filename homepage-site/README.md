# VestMap — New Homepage

Static marketing site for VestMap, implemented from the Claude Design
"Homepage" handoff bundle. Plain HTML/CSS — **no build step, no framework,
no dependencies** — so Netlify (or any static host) can serve the repo
root as-is.

## Pages

| Page | Status |
| --- | --- |
| `for-brokers.html` | ✅ Implemented |
| `index.html` (homepage) | Not yet built |
| `solutions.html` | Not yet built |
| `for-investors.html` | Not yet built |
| `developers.html` | Not yet built |
| `pricing.html` | Not yet built |

Nav and footer links to the unbuilt pages will 404 until those pages are
implemented. Until `index.html` exists, `netlify.toml` temporarily
redirects the site root (`/`) to `/for-brokers.html`.

## Deploying on Netlify

1. **Add new site → Import an existing project** and pick this repo.
2. Build command: *(leave empty)* · Publish directory: `.` (repo root).
3. Deploy. `netlify.toml` in the repo root handles the redirects.

## Structure

```
for-brokers.html        The For Brokers / Marketplace page
kit.css                 Component styles (nav, hero, sections, footer …)
colors_and_type.css     Design tokens: colors, type, spacing, radii, motion
fonts/fonts.css         Font stack — Newsreader, Inter, JetBrains Mono (Google Fonts)
assets/                 Logos, favicon
assets/imagery/         Client logos + aerial photography
netlify.toml            Publish config + temporary root redirect
```

Notes:

- The design prototype was desktop-first; there are no responsive
  breakpoints yet.
- The aerial photos were re-encoded from PNG (~4 MB each) to JPEG
  (~0.4 MB each) at their native 1536×1024 resolution for page weight.
- Fonts load from Google Fonts via `fonts/fonts.css`; swap in local
  `@font-face` declarations there if self-hosting is preferred.

## Local preview

```
python3 -m http.server
# → http://localhost:8000/for-brokers.html
```
