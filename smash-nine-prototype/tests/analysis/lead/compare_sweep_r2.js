// Lead's round-2 sweep comparison (Codex QA-17 round 2 was cut by the Codex usage limit):
// summarizes a Round 16 style results file with Codex QA-14's own summarize() and prints it next to
// Round 16 S0. Usage: node compare_sweep_r2.js <results.json> [<sweep log with LEAD_PASSIVE lines>]
const fs = require("fs");
const path = require("path");
const analyzer = path.resolve(__dirname, "../codex_qa_14/analyze_round16.js");
const source = fs.readFileSync(analyzer, "utf8");
const body = source.slice(0, source.indexOf("const r11 = read("));
const summarize = new Function("require", "__dirname", body + "\nreturn summarize;")(require, path.dirname(analyzer));
const raw = JSON.parse(fs.readFileSync(process.argv[2], "utf8").replace(/^﻿/, ""));
const now = summarize(raw);
const s0 = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../../../../reports/codex-qa-14/round16-summary.json"), "utf8")).s0;
const chars = ["frey", "luna", "nova", "rio", "yuki"];
const wins = rows => Object.fromEntries(chars.map(c => [c, rows.filter(r => r.winner === c).length]));
const out = {
	matches: { s0: s0.conditions.matches, now: now.conditions.matches },
	median_seconds: { s0: s0.match.median, now: now.match.median },
	ringouts_total: { s0: s0.global.ringouts, now: now.global.ringouts },
	zero_jump_ringouts: { s0: s0.global.zero_jump_ringouts, now: now.global.zero_jump_ringouts },
	wins: { s0: wins(s0.match.per_seed), now: wins(now.match.per_seed) },
	ringouts: Object.fromEntries(chars.map(c => [c, { s0: s0.ringouts[c].all, now: now.ringouts[c].all }])),
	pvp_dpm: Object.fromEntries(chars.map(c => [c, { s0: s0.pvp_dpm[c], now: now.pvp_dpm[c] }])),
	ultimates: Object.fromEntries(chars.map(c => [c, {
		s0: `${s0.ultimates_full_window[c].activations} casts, ${s0.ultimates_full_window[c].hit_rate}% hit, ${s0.ultimates_full_window[c].damage} dmg`,
		now: `${now.ultimates_full_window[c].activations} casts, ${now.ultimates_full_window[c].hit_rate}% hit, ${now.ultimates_full_window[c].damage} dmg`,
	}])),
	per_seed_now: now.match.per_seed.map(r => `${r.seed}:${r.winner}:${r.seconds}s:${r.ringouts}ro`),
};
out.attacks_now = {};
for (const [k, v] of Object.entries(raw.totals.attacks || {})) {
	if (k.startsWith("frey|") || k.startsWith("luna|")) out.attacks_now[k] = `${v.uses} uses, ${v.hits} hits, ${(v.hits / Math.max(v.uses, 1)).toFixed(3)}/use, ${(v.damage / Math.max(v.uses, 1)).toFixed(2)} dmg/use`;
}
if (process.argv[3]) {
	const lines = fs.readFileSync(process.argv[3], "latin1").split(/\n/).filter(l => l.includes("LEAD_PASSIVE seed="));
	const last = lines[lines.length - 1];
	if (last) out.passives_cumulative = JSON.parse(last.slice(last.indexOf("{"), last.lastIndexOf("}") + 1));
}
console.log(JSON.stringify(out, null, 2));
