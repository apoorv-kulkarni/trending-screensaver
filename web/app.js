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
    const res = await fetch(`https://apoorvkulkarni.com/trending-screensaver/trends.json?t=${Date.now()}`);
    payload = await res.json();
  } catch (e) {
    hero.textContent = "trends unavailable";
    return;
  }

  sourceEl.textContent = `Google Trends · ${payload.region} · ${formatFetched(payload.fetched_at)}`;

  const trends = payload.trends.map((t) => lower(t.title));
  const n = trends.length;

  // Shared pointer so every slot pulls from the same incrementing index —
  // guarantees all n trends appear before any repeats, regardless of slot count.
  let next = allWords.length;
  allWords.forEach((el, i) => {
    el.textContent = trends[i % n];
    el.addEventListener("animationiteration", () => {
      el.textContent = trends[next++ % n];
    });
  });
};

main();
