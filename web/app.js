const TRENDS_URL    = "https://apoorvkulkarni.com/trending-screensaver/trends.json";
const POLL_INTERVAL = 15 * 60 * 1000;

const caustics   = document.querySelector(".caustics");
const focus      = document.getElementById("focus");
const hero       = document.getElementById("hero");
const card       = document.getElementById("card");
const thumb      = document.getElementById("thumb");
const headline   = document.getElementById("headline");
const newsSource = document.getElementById("newsSource");
const trafficEl  = document.getElementById("traffic");
const sourceEl   = document.getElementById("source");

const ghosts = [
  document.getElementById("ghost1"),
  document.getElementById("ghost2"),
  document.getElementById("ghost3"),
];

const DIRECTIONS = ["left", "right", "up", "down"];

const lower = (s) => s.toLowerCase();

const formatFetched = (iso) =>
  new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });

const randBetween = (min, max) => min + Math.random() * (max - min);

// --- pauseable wait ---
let paused = false;

const wait = (ms) => new Promise((resolve) => {
  let remaining = ms;
  let last = Date.now();
  const tick = () => {
    const now = Date.now();
    if (!paused) remaining -= now - last;
    last = now;
    if (remaining <= 0) { resolve(); return; }
    setTimeout(tick, Math.min(100, remaining));
  };
  setTimeout(tick, Math.min(100, ms));
});

const togglePause = () => {
  paused = !paused;
  sourceEl.classList.toggle("paused", paused);
};

focus.style.pointerEvents = "auto";
document.addEventListener("keydown", (e) => {
  if (e.key === " " || e.key === "Enter") { e.preventDefault(); togglePause(); }
});
document.addEventListener("click", (e) => {
  if (!e.target.closest("a")) togglePause();
});

// --- traffic parsing ---
const parseTraffic = (s) => {
  if (!s) return 0;
  const m = s.replace(/,/g, "").match(/([\d.]+)\s*([KMB]?)/i);
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

// --- adaptive font size by title length ---
const heroSizeClass = (title) => {
  if (title.length > 35) return "size-sm";
  if (title.length > 20) return "size-md";
  return "";
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

// --- mutable state shared between the display loop and the poller ---
let trends      = [];
let ghostTitles = [];
let ghostNext   = ghosts.length;
let trendIndex  = 0;
let fetchedAt   = null;

// Ghost listeners set up once; read ghostTitles by reference.
ghosts.forEach((el, i) => {
  el.addEventListener("animationiteration", () => {
    if (!ghostTitles.length) return;
    el.textContent = ghostTitles[ghostNext++ % ghostTitles.length];
  });
});

const applyPayload = (payload) => {
  trends      = payload.trends;
  ghostTitles = payload.trends.map((t) => lower(t.title));
  fetchedAt   = payload.fetched_at;
  trendIndex  = 0;
  ghostNext   = ghosts.length;
  sourceEl.textContent = `Google Trends · ${payload.region} · ${formatFetched(payload.fetched_at)}`;
  if (paused) sourceEl.classList.add("paused");
  ghosts.forEach((el, i) => { el.textContent = ghostTitles[i % ghostTitles.length]; });
};

const fetchPayload = async () => {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10_000);
  try {
    const res = await fetch(`${TRENDS_URL}?t=${Date.now()}`, { signal: controller.signal });
    return res.json();
  } finally {
    clearTimeout(timer);
  }
};

const startPoller = () => {
  setInterval(async () => {
    try {
      const payload = await fetchPayload();
      if (payload.fetched_at !== fetchedAt) applyPayload(payload);
    } catch (e) { /* silent */ }
  }, POLL_INTERVAL);
};

const showTrend = async (trend) => {
  // Populate content.
  hero.textContent       = lower(trend.title);
  hero.href              = trend.link || "#";
  hero.className         = "hero";
  const sc = heroSizeClass(trend.title);
  if (sc) hero.classList.add(sc);

  headline.textContent   = trend.headline || "";
  headline.href          = trend.url || trend.link || "#";
  newsSource.textContent = trend.source || "";
  trafficEl.textContent  = trend.traffic ? `${trend.traffic} searches` : "";
  setThumb(trend.picture);

  // Instant card reset — no flash.
  focus.className = "focus resetting";
  void focus.offsetWidth;
  focus.className = "focus";

  // Randomise anchor within a safe box around centre.
  focus.style.top  = `${randBetween(38, 62)}%`;
  focus.style.left = `${randBetween(38, 62)}%`;

  void focus.offsetWidth;
  pulseCaustics();

  // Enter: blur-in from depth.
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
