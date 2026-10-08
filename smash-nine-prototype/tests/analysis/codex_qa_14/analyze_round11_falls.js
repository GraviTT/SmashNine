const fs = require("fs");
const path = require("path");

const reportDir = path.resolve(__dirname, "../../../../reports/codex-qa-14");
const input = JSON.parse(fs.readFileSync(path.join(reportDir, "round11-results.json"), "utf8").replace(/^\uFEFF/, ""));

function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.min(sorted.length - 1, Math.floor((sorted.length - 1) * p))];
}

const entries = input.recovery_entry_events || [];
const r10Only = input.r10_only_fall_events || [];
const held = input.saved_fall_events || [];
const linkedCauses = {};
const linkedOutcomes = {};
let linked = 0;

for (const fall of r10Only) {
  if (!fall.entered_recovery) continue;
  const match = entries.find((entry) =>
    entry.seed === fall.seed &&
    entry.character === fall.character &&
    entry.time >= fall.time - 0.02 &&
    entry.time <= fall.time + 0.30
  );
  if (!match) continue;
  linked += 1;
  linkedCauses[match.cause] = (linkedCauses[match.cause] || 0) + 1;
  linkedOutcomes[match.outcome] = (linkedOutcomes[match.outcome] || 0) + 1;
}

const ringoutRows = r10Only.filter((event) => event.outcome === "ringout");
const result = {
  r10_only: {
    total: r10Only.length,
    entered_recovery: r10Only.filter((event) => event.entered_recovery).length,
    landed: r10Only.filter((event) => event.outcome === "landed").length,
    ringout: ringoutRows.length,
    unfinished: r10Only.filter((event) => event.outcome === "unfinished").length,
    duration_median: Number(percentile(r10Only.map((event) => Number(event.duration || 0)), 0.5).toFixed(2)),
    duration_p90: Number(percentile(r10Only.map((event) => Number(event.duration || 0)), 0.9).toFixed(2)),
    linked_recovery_entries: linked,
    linked_causes: linkedCauses,
    linked_outcomes: linkedOutcomes,
    ringouts: ringoutRows,
  },
  arc_held: {
    total: held.length,
    landed: held.filter((event) => event.outcome === "landed").length,
    late_recovery: held.filter((event) => event.outcome === "recover").length,
    ringout: held.filter((event) => event.outcome === "ringout").length,
    both_predictors: held.filter((event) => event.predictor === "both").length,
    arc_only: held.filter((event) => event.predictor === "arc_only").length,
    duration_median: Number(percentile(held.map((event) => Number(event.duration || 0)), 0.5).toFixed(2)),
    duration_p90: Number(percentile(held.map((event) => Number(event.duration || 0)), 0.9).toFixed(2)),
  },
};

const output = path.join(reportDir, "round11-fall-analysis.json");
fs.writeFileSync(output, `${JSON.stringify(result, null, 2)}\n`, "utf8");
console.log(JSON.stringify(result, null, 2));
