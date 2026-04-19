const TRENDS_URL = "https://apoorvkulkarni.com/trending-screensaver/trends.json";

const focus = document.getElementById("focus");
const hero = document.getElementById("hero");
const thumb = document.getElementById("thumb");
const headline = document.getElementById("headline");
const newsSource = document.getElementById("newsSource");
const sourceEl = document.getElementById("source");

const ghosts = [
  document.getElementById("ghost1"),
  document.getElementById("ghost2"),
  document.getElementById("ghost3"),
];

const DIRECTIONS = ["left", "right", "up", "down"];

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const lower = (s) => s.toLowerCase();

const formatFetched = (iso) =>
  new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });

const setThumb = (url) => {
  if (url) {
    thumb.src = url.startsWith("//") ? `https:${url}` : url;
    thumb.classList.remove("empty");
  } else {
    thumb.removeAttribute("src");
    thumb.classList.add("empty");
  }
};

const showTrend = async (trend) => {
  hero.textContent = lower(trend.title);
  setThumb(trend.picture);
  headline.textContent = trend.headline || "";
  newsSource.textContent = trend.source || "";

  // Reset to hidden, off-state.
  focus.className = "focus";
  // Force reflow so the next class change actually transitions.
  void focus.offsetWidth;

  // Enter (1s).
  focus.classList.add("visible");
  await wait(1000);

  // Hold hero alone (3s).
  await wait(3000);

  // Headline + thumbnail fade in (0.8s) and stay.
  focus.classList.add("with-card");
  await wait(4000);

  // Drift away in a random direction (4s).
  const dir = DIRECTIONS[Math.floor(Math.random() * DIRECTIONS.length)];
  focus.classList.add(`drift-${dir}`);
  await wait(4000);

  // Brief gap before next.
  await wait(300);
};

const setupGhosts = (titles) => {
  let next = ghosts.length;
  ghosts.forEach((el, i) => {
    el.textContent = lower(titles[i % titles.length]);
    el.addEventListener("animationiteration", () => {
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
