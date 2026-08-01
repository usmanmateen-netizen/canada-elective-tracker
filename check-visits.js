// Who opened the tracker, and when.
// Run:  node site/check-visits.js
// Reads the visit log from Supabase using the public anon key + the site password.
import fs from "node:fs";

const cfg = fs.readFileSync(new URL("./config.js", import.meta.url), "utf8");
const URL_ = cfg.match(/url:\s*"([^"]+)"/)[1];
const KEY = cfg.match(/anonKey:\s*"([^"]+)"/)[1];
const PIN = process.argv[2] || "nehel84";

const r = await fetch(`${URL_}/rest/v1/rpc/visit_list`, {
  method: "POST",
  headers: { "Content-Type": "application/json", apikey: KEY, Authorization: `Bearer ${KEY}` },
  body: JSON.stringify({ pin: PIN }),
});
if (!r.ok) {
  console.error("Failed:", r.status, await r.text());
  process.exit(1);
}
const rows = await r.json();
if (!rows.length) {
  console.log("No visits recorded yet.");
  process.exit(0);
}
const fmt = (d) =>
  new Date(d).toLocaleString("en-GB", { timeZone: "Europe/London", dateStyle: "medium", timeStyle: "short" });
const device = (ua = "") =>
  /iPhone|iPad/.test(ua) ? "iPhone/iPad" : /Android/.test(ua) ? "Android" : /Macintosh/.test(ua) ? "Mac" : /Windows/.test(ua) ? "Windows" : "other";

console.log(`${rows.length} visit(s), newest first (UK time):\n`);
for (const v of rows) console.log(`  ${fmt(v.at)}  ${String(v.page).padEnd(8)}  ${device(v.agent)}`);

const days = new Set(rows.map((v) => v.at.slice(0, 10)));
console.log(`\nDistinct days: ${days.size}   ·   Last visit: ${fmt(rows[0].at)}`);
