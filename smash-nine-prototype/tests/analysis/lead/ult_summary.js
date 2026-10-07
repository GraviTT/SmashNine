// Summarises ult_probe.gd JSONL: per character casts, hit rate, damage per cast, gain over the
// fighter's normal damage rate for the same window, KOs per cast.
// Usage: node tests/analysis/lead/ult_summary.js <file.jsonl>
const fs = require("fs");
const WINDOWS = { frey: 2.0, yuki: 3.5, luna: 7.0, nova: 3.2, rio: 1.8 };
const rows = fs.readFileSync(process.argv[2], "utf8").trim().split("\n").filter(Boolean).map(JSON.parse);
const total = {};
for (const row of rows) {
	for (const [id, c] of Object.entries(row.characters)) {
		const t = total[id] || (total[id] = { casts: 0, hit_casts: 0, damage: 0, kos: 0, normal_damage: 0, normal_time: 0, fighters: 0 });
		for (const k of Object.keys(t)) t[k] += c[k];
	}
}
console.log(`matches ${rows.length}`);
console.log("char   casts  hit%  dmg/cast  normal dps  gain/cast  KO/cast");
for (const [id, t] of Object.entries(total).sort()) {
	const dps = t.normal_time > 0 ? t.normal_damage / t.normal_time : 0;
	const perCast = t.casts ? t.damage / t.casts : 0;
	const gain = perCast - dps * WINDOWS[id];
	console.log(`${id.padEnd(6)} ${String(t.casts).padStart(5)}  ${(t.casts ? 100 * t.hit_casts / t.casts : 0).toFixed(0).padStart(3)}%  ${perCast.toFixed(1).padStart(8)}  ${dps.toFixed(2).padStart(10)}  ${gain.toFixed(1).padStart(9)}  ${(t.casts ? t.kos / t.casts : 0).toFixed(2).padStart(7)}`);
}
