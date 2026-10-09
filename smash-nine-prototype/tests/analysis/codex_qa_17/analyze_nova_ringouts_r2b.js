// Independent Round 2b audit of Nova ring-outs from the two large QA-14 result files.
// It does not write or copy either input file; JSON is printed to stdout.
const fs = require("fs");

const currentPath = process.argv[2] || "../reports/codex-qa-14/round16-current-results.json";
const baselinePath = process.argv[3] || "../reports/codex-qa-14/round16-s0-results.json";

function counts(rows, key) {
  const out = {};
  for (const row of rows) {
    const value = String(row[key] || "(none)");
    out[value] = (out[value] || 0) + 1;
  }
  return out;
}

function ultimateStats(rows) {
  const out = {};
  for (const row of rows) {
    const item = out[row.character] || { casts: 0, hit_casts: 0, hit_events: 0, damage: 0 };
    item.casts += 1;
    item.hit_casts += row.hit ? 1 : 0;
    item.hit_events += row.hit_events || 0;
    item.damage += row.damage || 0;
    out[row.character] = item;
  }
  for (const item of Object.values(out)) item.damage = Number(item.damage.toFixed(2));
  return out;
}

function summarize(path) {
  const data = JSON.parse(fs.readFileSync(path, "utf8"));
  const starts = data.ringout_starts.filter((row) => row.victim === "nova");
  const ringouts = data.ringouts.filter((row) => row.victim === "nova");
  const joined = starts.map((start) => ({
    start,
    ringout: ringouts.find((row) => row.seed === start.seed && Math.abs(row.time - start.time) < 0.1),
  }));
  const ultimateWithin3 = joined.filter((row) => row.start.ultimate_hit_within_3s);
  return {
    path,
    nova_ringouts: joined.length,
    recent_ultimate_hits: ultimateWithin3.length,
    recent_ultimate_attacker: counts(ultimateWithin3.map((row) => row.start), "ultimate_attacker"),
    recent_pvp_attacker: counts(joined.filter((row) => row.start.pvp_hit_within_3s).map((row) => row.start), "pvp_attacker"),
    credited_attacker: counts(joined.map((row) => row.ringout || {}), "attacker"),
    during_recovery: joined.filter((row) => row.ringout && row.ringout.during_recovery).length,
    recent_ultimate_and_recovery: ultimateWithin3.filter((row) => row.ringout && row.ringout.during_recovery).length,
    recent_ultimate_and_zero_jumps: ultimateWithin3.filter((row) => row.ringout && row.ringout.air_jumps_left === 0).length,
    environment_credit: joined.filter((row) => row.ringout && row.ringout.attacker === "environment").length,
    per_seed: counts(joined.map((row) => ({ seed: row.start.seed })), "seed"),
    ultimates: ultimateStats(data.ultimate_events),
    nova_ultimate_driver: data.totals.nova,
  };
}

const current = summarize(currentPath);
const baseline = summarize(baselinePath);
const attackerDelta = {};
for (const key of new Set([...Object.keys(current.recent_ultimate_attacker), ...Object.keys(baseline.recent_ultimate_attacker)])) {
  attackerDelta[key] = (current.recent_ultimate_attacker[key] || 0) - (baseline.recent_ultimate_attacker[key] || 0);
}

console.log(JSON.stringify({
  schema: 1,
  definition: "recent ultimate = PvP damage while attacker ultimate_window_timer > 0, followed by Nova ring-out within 3 seconds",
  baseline,
  current,
  delta: {
    nova_ringouts: current.nova_ringouts - baseline.nova_ringouts,
    recent_ultimate_hits: current.recent_ultimate_hits - baseline.recent_ultimate_hits,
    recent_ultimate_attacker: attackerDelta,
    during_recovery: current.during_recovery - baseline.during_recovery,
    environment_credit: current.environment_credit - baseline.environment_credit,
  },
  limits: [
    "Character id is recorded but player instance id is not, so duplicate-character attacker identity cannot be reconstructed.",
    "The observer records ultimate damage received, not the victim's own ultimate movement; own-slingshot attribution is unavailable.",
    "Same seeds do not preserve the same fight after gameplay changes; this is association, not an armor-only causal A/B."
  ]
}, null, 2));
