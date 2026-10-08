const fs = require("fs");
const path = require("path");

const reportDir = path.resolve(__dirname, "../../../../reports/codex-qa-14");
const resultsPath = path.join(reportDir, "round11-results.json");
const summaryPath = path.join(reportDir, "round11-summary.json");
const results = JSON.parse(fs.readFileSync(resultsPath, "utf8").replace(/^\uFEFF/, ""));
const summary = JSON.parse(fs.readFileSync(summaryPath, "utf8").replace(/^\uFEFF/, ""));

const causes = {};
const characters = {};
for (const event of results.recovery_entry_events || []) {
  const cause = causes[event.cause] ||= { entries: 0, success: 0, ringout: 0, unfinished: 0 };
  cause.entries += 1;
  cause[event.outcome] = (cause[event.outcome] || 0) + 1;

  const character = characters[event.character] ||= {};
  character[event.cause] = (character[event.cause] || 0) + 1;
}

const total = (results.recovery_entry_events || []).length;
for (const cause of Object.values(causes)) {
  cause.share_pct = total ? Number((100 * cause.entries / total).toFixed(2)) : 0;
  cause.ringout_pct = cause.entries ? Number((100 * cause.ringout / cause.entries).toFixed(2)) : 0;
}

summary.recovery_entries = { total, causes, characters };
const savedFallOutcomes = {};
const savedFallCharacters = {};
for (const event of results.saved_fall_events || []) {
  savedFallOutcomes[event.outcome] = (savedFallOutcomes[event.outcome] || 0) + 1;
  const character = savedFallCharacters[event.character] ||= {};
  character[event.outcome] = (character[event.outcome] || 0) + 1;
}
summary.saved_falls = { total: (results.saved_fall_events || []).length, outcomes: savedFallOutcomes, characters: savedFallCharacters };
const savedFallPredictors = {};
for (const event of results.saved_fall_events || []) {
  const predictor = event.predictor || "unknown";
  const row = savedFallPredictors[predictor] ||= { total: 0 };
  row.total += 1;
  row[event.outcome] = (row[event.outcome] || 0) + 1;
}
summary.saved_falls.predictors = savedFallPredictors;

const r10OnlyOutcomes = {};
const r10OnlyCharacters = {};
let r10OnlyEnteredRecovery = 0;
for (const event of results.r10_only_fall_events || []) {
  r10OnlyOutcomes[event.outcome] = (r10OnlyOutcomes[event.outcome] || 0) + 1;
  if (event.entered_recovery) r10OnlyEnteredRecovery += 1;
  const character = r10OnlyCharacters[event.character] ||= {};
  character[event.outcome] = (character[event.outcome] || 0) + 1;
}
summary.r10_only_falls = {
  total: (results.r10_only_fall_events || []).length,
  entered_recovery: r10OnlyEnteredRecovery,
  outcomes: r10OnlyOutcomes,
  characters: r10OnlyCharacters,
};
fs.writeFileSync(summaryPath, `${JSON.stringify(summary, null, 2)}\n`, "utf8");
console.log(JSON.stringify({ recovery_entries: summary.recovery_entries, saved_falls: summary.saved_falls, r10_only_falls: summary.r10_only_falls }, null, 2));
