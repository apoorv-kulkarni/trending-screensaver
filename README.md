# trending-screensaver

A macOS screensaver and live web view that displays today's Google Trends as fish drifting through a deep-ocean scene. Each trend surfaces into focus — hero word, headline, thumbnail — then swims back into the dark.

Live at [apoorvkulkarni.com/trending-screensaver](https://apoorvkulkarni.com/trending-screensaver/).

## How it works

Three pieces, one data source:

1. **Fetcher** (`fetch_trends.py`) — pulls Google Trends daily RSS and writes `web/trends.json`.
2. **GitHub Actions** (`.github/workflows/pages.yml`) — runs the fetcher hourly and deploys `web/` to GitHub Pages.
3. **macOS screensaver** (`screensaver/`) — a `ScreenSaverView` hosting a `WKWebView` that loads `web/index.html` and fetches the live `trends.json` from the deployed site.

The screensaver has no local cron — every time it activates, the web view pulls the latest data over HTTPS.

## Change your region

By default the fetcher pulls US trends. To change it, set a GitHub Actions variable named `GEO` in your repo's **Settings → Secrets and variables → Actions → Variables** tab, using any [Google Trends geo code](https://developers.google.com/google-ads/api/data/geotargets) (e.g. `GB`, `AU`, `IN`, `JP`).

Or edit the `GEO` line directly in `.github/workflows/pages.yml`:

```yaml
GEO: ${{ vars.GEO || 'US' }}
```

## Run the fetcher locally

```bash
python3 fetch_trends.py          # defaults to US
GEO=GB python3 fetch_trends.py   # UK trends
```

No dependencies outside the Python stdlib. Writes `web/trends.json`.

## Build and install the screensaver

Requires macOS 11+ and the Swift toolchain (ships with Xcode / Command Line Tools).

```bash
cd screensaver
make install
```

This builds `TrendsScreensaver.saver` and copies it to `~/Library/Screen Savers/`. Open System Settings → Screen Saver to select it.

Uninstall with `make uninstall`.

## Project layout

```text
fetch_trends.py            # Google Trends RSS -> web/trends.json
web/                       # static site (deployed to Pages)
  index.html
  app.js
  styles.css
  trends.json              # regenerated hourly by GHA, gitignored
screensaver/
  Sources/TrendsView.swift # ScreenSaverView + WKWebView host
  Resources/Info.plist
  Makefile                 # build + install
.github/workflows/
  pages.yml                # hourly fetch + Pages deploy
  build-screensaver.yml    # Swift compile check
```

## Inspiration

Inspired by the macOS "Word of the Day" screensaver — same calm, ambient-information vibe, but with what the world is searching for instead of vocabulary.

## License

MIT — see [LICENSE](LICENSE).
