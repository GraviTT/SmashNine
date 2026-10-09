const fs = require("fs");
const path = require("path");

const variant = (process.argv[2] || "a").toLowerCase();
if (!['a', 'b'].includes(variant)) throw new Error(`bad variant ${variant}`);
const reportDir = path.resolve(__dirname, "../../../../reports/codex-qa-14");

function merge(left, right) {
  if (left === undefined || left === null) return right;
  if (right === undefined || right === null) return left;
  if (Array.isArray(left) && Array.isArray(right)) return left.concat(right);
  if (typeof left === 'number' && typeof right === 'number') return left + right;
  if (typeof left === 'object' && typeof right === 'object') {
    const out = { ...left };
    for (const [key, value] of Object.entries(right)) out[key] = key in out ? merge(out[key], value) : value;
    return out;
  }
  return left;
}

const rows = [];
for (let seed = 101; seed <= 112; seed += 1) {
  const file = path.join(reportDir, `round13-${variant}-seed-${seed}.json`);
  rows.push(JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '')));
}
const first = rows[0];
let totals = null;
const arrayKeys = [
  'matches','ringouts','low_hp_portals','relocations','target_drop_events','corner_escape_events',
  'recovery_skill_events','recovery_skill_ask_events','progress_extension_events','standoff_trace_events',
  'dead_band_events','recovery_entry_events','saved_fall_events','r10_only_fall_events','fall_frames',
  'fall_flips','ringout_details','no_route_details','fixture_candidates','ab_suppressed_falls'
];
const output = {
  schema: 13, variant, seeds: Array.from({length: 12}, (_, i) => i + 101), players: first.players,
  sample_interval: first.sample_interval, hit_window: first.hit_window,
  wall_seconds: Number(rows.reduce((sum, row) => sum + Number(row.wall_seconds || 0), 0).toFixed(3)),
};
for (const key of arrayKeys) output[key] = rows.flatMap(row => row[key] || []);
for (const row of rows) totals = merge(totals, row.totals);
output.totals = totals;
output.no_progress_causes = rows.reduce((acc, row) => merge(acc, row.no_progress_causes || {}), {});
output.attack_request_frames = rows.reduce((acc, row) => merge(acc, row.attack_request_frames || {}), {});
output.round13_definitions = first.round13_definitions;
const destination = path.join(reportDir, `round13-${variant}-results.json`);
fs.writeFileSync(destination, `${JSON.stringify(output, null, 2)}\n`, 'utf8');
console.log(`Merged variant ${variant}: matches=${output.matches.length} frames=${output.fall_frames.length} flips=${output.fall_flips.length} -> ${destination}`);
