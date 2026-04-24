const TRENDS_URL = "https://apoorvkulkarni.com/trending-screensaver/trends.json";

const caustics = document.querySelector(".caustics");
const focus    = document.getElementById("focus");
const hero     = document.getElementById("hero");
const card     = document.getElementById("card");
const thumb    = document.getElementById("thumb");
const headline = document.getElementById("headline");
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

// Parse "500K+", "2M+", "45K+" → number. Returns 0 if unparseable.
const parseTraffic = (s) => {
  if (!s) return 0;
  const m = s.match(/([\d.]+)\s*([KMB]?)/i);
  if (!m) return 0;
  const mult = { k: 1e3, m: 1e6, b: 1e9 }[m[2].toLowerCase()] || 1;
  return parseFloat(m[1]) * mult;
};

// Scale hold times by traffic volume so high-trend moments breathe longer.
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

const showTrend = async (trend) => {
  hero.textContent       = lower(trend.title);
  hero.href              = trend.link || "#";
  headline.textContent   = trend.headline || "";
  headline.href          = trend.url || trend.link || "#";
  newsSource.textContent = trend.source || "";
  trafficEl.textContent  = trend.traffic ? `${trend.traffic} searches` : "";
  setThumb(trend.picture);

  // Instantly snap card to hidden — prevents flash on cycle reset.
  focus.className = "focus resetting";
  void focus.offsetWidth;
  focus.className = "focus";
  void focus.offsetWidth;

  pulseCaustics();

  // Enter: blur-in from depth (1.2s).
  focus.classList.add("visible");
  await wait(1200);

  // Hold hero alone.
  const { hero: heroHold, card: cardHold } = holdTimes(trend.traffic);
  await wait(heroHold);

  // Headline + thumbnail fade in, hold.
  focus.classList.add("with-card");
  await wait(cardHold);

  // Drift away in a random direction (4s).
  const dir = DIRECTIONS[Math.floor(Math.random() * DIRECTIONS.length)];
  focus.classList.add(`drift-${dir}`);
  await wait(4000);

  await wait(300);
};

const setupGhosts = (titles) => {
  let next = ghosts.length;
  ghosts.forEach((el, i) => {
    el.textContent = lower(titles[i % titles.length]);
    el.addEventListener("animationiteration", () => {
      // Text swap happens at opacity 0 (keyframe boundary), so it's invisible.
      el.textContent = lower(titles[next++ % titles.length]);
    });
  });
};

const main = async () => {
  let payload;
  try {
    const res = await fetch(`${TRENDS_URL}?t=${Date.now()}`);
    payload = await res.json();
  } catch (e) {
    hero.textContent = "trends unavailable";
    focus.classList.add("visible");
    return;
  }

  sourceEl.textContent = `Google Trends · ${payload.region} · ${formatFetched(payload.fetched_at)}`;

  const trends = payload.trends;
  if (!trends.length) return;

  setupGhosts(trends.map((t) => t.title));

  let i = 0;
  while (true) {
    await showTrend(trends[i % trends.length]);
    i++;
  }
};

main();
