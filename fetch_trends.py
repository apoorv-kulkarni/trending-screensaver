#!/usr/bin/env python3
"""Fetch Google Trends daily trending searches and write web/trends.json."""

import json
import os
import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

GEO = os.environ.get("GEO", "US").upper()
FEED_URL = f"https://trends.google.com/trending/rss?geo={GEO}"
OUT_PATH = Path(__file__).parent / "web" / "trends.json"
NS = {"ht": "https://trends.google.com/trending/rss"}


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "trends-screensaver/1.0"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.read()


def parse(xml_bytes: bytes) -> list[dict]:
    root = ET.fromstring(xml_bytes)
    trends = []
    for item in root.iter("item"):
        title = (item.findtext("title") or "").strip()
        if not title:
            continue
        link = (item.findtext("link") or "").strip()
        traffic = (item.findtext("ht:approx_traffic", namespaces=NS) or "").strip()
        picture = (item.findtext("ht:picture", namespaces=NS) or "").strip()
        news_title = (item.findtext("ht:news_item/ht:news_item_title", namespaces=NS) or "").strip()
        news_source = (item.findtext("ht:news_item/ht:news_item_source", namespaces=NS) or "").strip()
        news_url = (item.findtext("ht:news_item/ht:news_item_url", namespaces=NS) or "").strip()
        trends.append({
            "title": title,
            "link": link,
            "traffic": traffic,
            "picture": picture,
            "headline": news_title,
            "source": news_source,
            "url": news_url,
        })
    return trends


def main() -> int:
    try:
        xml_bytes = fetch(FEED_URL)
    except Exception as e:
        print(f"fetch failed: {e}", file=sys.stderr)
        return 1

    trends = parse(xml_bytes)
    if not trends:
        print("no trends parsed", file=sys.stderr)
        return 1

    payload = {
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "region": GEO,
        "trends": trends,
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False))
    print(f"wrote {len(trends)} trends to {OUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
