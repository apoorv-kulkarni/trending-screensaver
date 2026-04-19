const hero = document.getElementById("hero");
const ghosts = [
  document.getElementById("ghost1"),
  document.getElementById("ghost2"),
  document.getElementById("ghost3"),
];
const sourceEl = document.getElementById("source");
const allWords = [hero, ...ghosts];

const lower = (s) => s.toLowerCase();

const formatFetched = (iso) =>
  new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });

const main = async () => {
  let payload;
  try {
    const res = await fetch(`https://apoorv-kulkarni.github.io/trending-screensaver/trends.json?t=${Date.now()}`);
    payload = await res.json();
  } catch (e) {
    hero.textContent = "trends unavailable";
    return;
  }

  sourceEl.textContent = `Google Trends · ${payload.region} · ${formatFetched(payload.fetched_at)}`;

  const trends = payload.trends.map((t) => lower(t.title));
  const n = trends.length;

  // Each word picks a starting trend; on every animation loop, advance to the next.
  // Stagger starts so they don't all show the same trend at once.
  allWords.forEach((el, i) => {
    let idx = i % n;
    el.textContent = trends[idx];
    el.addEventListener("animationiteration", () => {
      idx = (idx + allWords.length) % n;
      el.textContent = trends[idx];
    });
  });
};

main();
