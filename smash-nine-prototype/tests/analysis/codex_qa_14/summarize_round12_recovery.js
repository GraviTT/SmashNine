const fs = require("fs");
const path = require("path");

const reportDir = path.resolve(__dirname, "../../../../reports/codex-qa-14");
const resultsPath = path.join(reportDir, "round12-results.json");
const summaryPath = path.join(reportDir, "round12-summary.json");
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
fs.writeFileSync(summaryPath, `${JSON.stringify(summary, null, 2)}\n`, "utf8");
console.log(JSON.stringify(summary.recovery_entries, null, 2));
