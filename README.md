# trending-screensaver

A macOS screensaver that displays today's Google Trends as drifting words, plus a live web view at [apoorvkulkarni.com/trending-screensaver](https://apoorvkulkarni.com/trending-screensaver/).

## How it works

Three pieces, one data source:

1. **Fetcher** (`fetch_trends.py`) — pulls Google Trends daily RSS (`geo=US`) and writes `web/trends.json`.
2. **GitHub Actions** (`.github/workflows/pages.yml`) — runs the fetcher hourly and deploys `web/` to GitHub Pages.
3. **macOS screensaver** (`screensaver/`) — a `ScreenSaverView` hosting a `WKWebView` that loads `web/index.html` and fetches the live `trends.json` from the deployed site.

The screensaver has no local cron of its own — every time it activates, the web view pulls the latest JSON over HTTPS.

## Run the fetcher locally

```bash
python3 fetch_trends.py
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
  trends.json              # regenerated hourly by GHA
screensaver/
  Sources/TrendsView.swift # ScreenSaverView + WKWebView host
  Resources/Info.plist
  Makefile                 # build + install
.github/workflows/pages.yml
```

## Inspiration

Inspired by the macOS "Word of the Day" screensaver — same calm, ambient-information vibe, but with what the world is searching for instead of vocabulary.

## License

MIT — see [LICENSE](LICENSE).
