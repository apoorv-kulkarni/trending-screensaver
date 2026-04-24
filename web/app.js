const TRENDS_URL = "https://apoorvkulkarni.com/trending-screensaver/trends.json";
const POLL_INTERVAL = 15 * 60 * 1000; // 15 min — GHA updates hourly, this catches it promptly

const caustics  = document.querySelector(".caustics");
const focus     = document.getElementById("focus");
const hero      = document.getElementById("hero");
const card      = document.getElementById("card");
const thumb     = document.getElementById("thumb");
const headline  = document.getElementById("headline");
const newsSource = document.getElementById("newsSource");
const trafficEl  = document.getElementById("traffic");
const sourceEl   = document.getElementById("source");

const ghosts = [
  document.getElementById("ghost1"),
  document.getElementById("ghost2"),
  document.getElementById("ghost3"),
];

const DIRECTIONS = ["left", "right", "up", "down"];

const wait  = (ms) => new Promise((r) => setTimeout(r, ms));
const lower = (s)  => s.toLowerCase();

const formatFetched = (iso) =>
  new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });

const parseTraffic = (s) => {
  if (!s) return 0;
  const m = s.match(/([\d.]+)\s*([KMB]?)/i);
  if (!m) return 0;
  const mult = { k: 1e3, m: 1e6, b: 1e9 }[m[2].toLowerCase()] || 1;
  return parseFloat(m[1]) * mult;
};

const holdTimes = (traffic) => {
  const n = parseTraffic(traffic);
  if (n >= 2_000_000) return { hero: 5000, card: 5500 };
  if (n >= 500_000)   return { hero: 4000, card: 4500 };
  if (n >= 100_000)   return { hero: 3000, card: 4000 };
  return                     { hero: 2500, card: 3000 };
};

const setThumb = (url) => {
  if (url) {
    thumb.src = url.startsWith("//") ? `https:${url}` : url;
    thumb.classList.remove("empty");
  } else {
    thumb.removeAttribute("src");
    thumb.classList.add("empty");
  }
};

const pulseCaustics = () => {
  caustics.classList.remove("pulse");
  void caustics.offsetWidth;
  caustics.classList.add("pulse");
  caustics.addEventListener("animationend", () => caustics.classList.remove("pulse"), { once: true });
};

// Enable pointer events on the web view only (screensavers block interaction).
const isScreensaver = window.location.protocol === "file:";
if (!isScreensaver) focus.style.pointerEvents = "auto";

// --- mutable state shared between the display loop and the poller ---
let trends      = [];
let ghostTitles = [];
let ghostNext   = ghosts.length;
let trendIndex  = 0;
let fetchedAt   = null;

// Ghost listeners are set up once; they read from ghostTitles by reference.
ghosts.forEach((el, i) => {
  el.addEventListener("animationiteration", () => {
    if (!ghostTitles.length) return;
    el.textContent = ghostTitles[ghostNext++ % ghostTitles.length];
  });
});

const applyPayload = (payload, updateSource = true) => {
  trends      = payload.trends;
  ghostTitles = payload.trends.map((t) => lower(t.title));
  fetchedAt   = payload.fetched_at;
  if (updateSource) {
    sourceEl.textContent = `Google Trends · ${payload.region} · ${formatFetched(payload.fetched_at)}`;
  }
  ghosts.forEach((el, i) => {
    el.textContent = ghostTitles[i % ghostTitles.length];
  });
  ghostNext   = ghosts.length;
  trendIndex  = 0;
};

const fetchPayload = async () => {
  const res = await fetch(`${TRENDS_URL}?t=${Date.now()}`);
  return res.json();
};

// Background poller — silently refreshes trends when GHA has new data.
const startPoller = () => {
  setInterval(async () => {
    try {
      const payload = await fetchPayload();
      if (payload.fetched_at !== fetchedAt) applyPayload(payload);
    } catch (e) { /* silent — never disrupt the display */ }
  }, POLL_INTERVAL);
};

const showTrend = async (trend) => {
  hero.textContent       = lower(trend.title);
  hero.href              = trend.link || "#";
  headline.textContent   = trend.headline || "";
  headline.href          = trend.url || trend.link || "#";
  newsSource.textContent = trend.source || "";
  trafficEl.textContent  = trend.traffic ? `${trend.traffic} searches` : "";
  setThumb(trend.picture);

  focus.className = "focus resetting";
  void focus.offsetWidth;
  focus.className = "focus";
  void focus.offsetWidth;

  pulseCaustics();

  focus.classList.add("visible");
  await wait(1200);

  const { hero: heroHold, card: cardHold } = holdTimes(trend.traffic);
  await wait(heroHold);

  focus.classList.add("with-card");
  await wait(cardHold);

  const dir = DIRECTIONS[Math.floor(Math.random() * DIRECTIONS.length)];
  focus.classList.add(`drift-${dir}`);
  await wait(4000);

  await wait(300);
};

const main = async () => {
  let payload;
  try {
    payload = await fetchPayload();
  } catch (e) {
    hero.textContent = "trends unavailable";
    focus.classList.add("visible");
    return;
  }

  applyPayload(payload);
  startPoller();

  while (true) {
    await showTrend(trends[trendIndex % trends.length]);
    trendIndex++;
  }
};

main();
