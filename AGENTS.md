# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this project is

A macOS screensaver and a live web page that display today's Google Trends as animated, drifting words. Data flows one way: Google Trends RSS → `fetch_trends.py` → `web/trends.json` → GitHub Pages → the screensaver's WKWebView.

## Repo layout

```text
fetch_trends.py                   # fetcher — pure Python stdlib, no deps
web/                              # static site deployed to GitHub Pages
  index.html                      # single-page app
  app.js                          # lifecycle and rendering logic
  styles.css                      # all visual design
  trends.json                     # generated at deploy time, gitignored
screensaver/
  Sources/TrendsView.swift        # ScreenSaverView + WKWebView host
  Resources/Info.plist
  Makefile                        # build + install
.github/workflows/
  pages.yml                       # hourly fetch + Pages deploy
  build-screensaver.yml           # Swift compile check on screensaver/ changes
```

## How to run things

### Fetch trends locally
```bash
python3 fetch_trends.py
# Writes web/trends.json — no dependencies beyond stdlib.
```

### Open the web view locally
Open `web/index.html` directly in a browser. `app.js` fetches from the live
Pages URL so `web/trends.json` does not need to exist locally.

### Build and install the screensaver
```bash
cd screensaver
make          # builds screensaver/build/TrendsScreensaver.saver
make install  # copies to ~/Library/Screen Savers/
make uninstall
```

Requires macOS 11+ and the Swift toolchain (ships with Xcode or Command Line Tools).

## Key constraints

- **No runtime dependencies.** `fetch_trends.py` uses only Python stdlib. `web/` is vanilla HTML/CSS/JS with no bundler. The screensaver uses only ScreenSaver, WebKit, and AppKit frameworks.
- **`web/trends.json` is gitignored.** It is generated fresh on every GHA run and shipped via Pages artifact. Never commit it.
- **The screensaver loads `app.js` from its bundle**, which fetches `trends.json` from `https://apoorvkulkarni.com/trending-screensaver/trends.json` — the live Pages URL. This means the screensaver requires network access at activation time.
- **Screensaver links are intentionally disabled.** `app.js` detects `file://` protocol and disables pointer events, so trend links only work in the browser web view.
- **GHA uses GitHub Pages "GitHub Actions" source** (not "Deploy from branch"). Do not change `pages.yml` to commit `trends.json` back to the repo — that's intentional.

## What to check after changes

| Changed file | What to verify |
|---|---|
| `fetch_trends.py` | Run locally, inspect `web/trends.json` shape matches the schema (title, link, traffic, picture, headline, source, url) |
| `web/app.js` or `web/styles.css` | Open `web/index.html` in a browser; watch through 2–3 full trend cycles |
| `screensaver/Sources/TrendsView.swift` | Run `cd screensaver && make` to confirm it compiles |
| `.github/workflows/pages.yml` | Check GHA run succeeds and the live URL updates |

## Trend data schema

```json
{
  "fetched_at": "2026-04-23T00:00:00+00:00",
  "region": "US",
  "trends": [
    {
      "title": "Example Trend",
      "link": "https://trends.google.com/...",
      "traffic": "500K+",
      "picture": "https://...",
      "headline": "Example headline text",
      "source": "Example News Source",
      "url": "https://news.example.com/..."
    }
  ]
}
```
