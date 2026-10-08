const fs = require("fs");
const path = require("path");

const reportDir = path.resolve(__dirname, "../../../../reports/codex-qa-14");
const input = JSON.parse(fs.readFileSync(path.join(reportDir, "round12-results.json"), "utf8").replace(/^\uFEFF/, ""));
const entries = input.recovery_entry_events || [];

function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.min(sorted.length - 1, Math.floor((sorted.length - 1) * p))];
}

function summarize(events, rejected = false) {
  const outcomes = {};
  const characters = {};
  const linkedCauses = {};
  const linkedOutcomes = {};
  let enteredRecovery = 0;
  let linkedRecoveryEntries = 0;
  for (const event of events) {
    outcomes[event.outcome] = (outcomes[event.outcome] || 0) + 1;
    const character = characters[event.character] ||= {};
    character[event.outcome] = (character[event.outcome] || 0) + 1;
    if (event.entered_recovery) enteredRecovery += 1;
    if (rejected && event.entered_recovery) {
      const match = entries.find(entry => entry.seed === event.seed && entry.character === event.character && entry.time >= event.time - 0.02 && entry.time <= event.time + 0.30);
      if (match) {
        linkedRecoveryEntries += 1;
        linkedCauses[match.cause] = (linkedCauses[match.cause] || 0) + 1;
        linkedOutcomes[match.outcome] = (linkedOutcomes[match.outcome] || 0) + 1;
      }
    }
  }
  return {
    total: events.length,
    outcomes,
    landed: outcomes.landed || 0,
    did_not_land: (outcomes.recover || 0) + (outcomes.ringout || 0) + (outcomes.unfinished || 0),
    entered_recovery: enteredRecovery,
    duration_median: Number(percentile(events.map(event => Number(event.duration || 0)), 0.5).toFixed(2)),
    duration_p90: Number(percentile(events.map(event => Number(event.duration || 0)), 0.9).toFixed(2)),
    characters,
    linked_recovery_entries: linkedRecoveryEntries,
    linked_causes: linkedCauses,
    linked_outcomes: linkedOutcomes,
  };
}

const accepted = input.saved_fall_events || [];
const r10Rejected = input.r10_only_fall_events || [];
const r11Rejected = input.r11_only_fall_events || [];
const acceptedPredictorMatrix = {};
for (const event of accepted) {
  const key = `r10_${Boolean(event.r10_landing)}|r11_${Boolean(event.r11_landing)}`;
  const row = acceptedPredictorMatrix[key] ||= { total: 0 };
  row.total += 1;
  row[event.outcome] = (row[event.outcome] || 0) + 1;
}
const acceptedLateRecovery = { linked: 0, outcomes: {}, causes: {} };
for (const fall of accepted.filter(event => event.outcome === "recover")) {
  const end = Number(fall.time) + Number(fall.duration || 0);
  const entry = entries.find(event => event.seed === fall.seed && event.character === fall.character && Math.abs(Number(event.time) - end) <= 0.03);
  if (!entry) continue;
  acceptedLateRecovery.linked += 1;
  acceptedLateRecovery.outcomes[entry.outcome] = (acceptedLateRecovery.outcomes[entry.outcome] || 0) + 1;
  acceptedLateRecovery.causes[entry.cause] = (acceptedLateRecovery.causes[entry.cause] || 0) + 1;
}
const acceptedTrace = {
  total: accepted.length,
  move_input_changed: accepted.filter(event => Number(event.move_input_changes || 0) > 0).length,
  move_input_reversed: accepted.filter(event => Number(event.move_input_reversals || 0) > 0).length,
  intent_move_changed: accepted.filter(event => Number(event.intent_move_changes || 0) > 0).length,
  intent_move_reversed: accepted.filter(event => Number(event.intent_move_reversals || 0) > 0).length,
};
const acceptedRecover = accepted.filter(event => event.outcome === "recover");
acceptedTrace.late_recovery = {
  total: acceptedRecover.length,
  move_input_changed: acceptedRecover.filter(event => Number(event.move_input_changes || 0) > 0).length,
  move_input_reversed: acceptedRecover.filter(event => Number(event.move_input_reversals || 0) > 0).length,
  intent_move_changed: acceptedRecover.filter(event => Number(event.intent_move_changes || 0) > 0).length,
  intent_move_reversed: acceptedRecover.filter(event => Number(event.intent_move_reversals || 0) > 0).length,
  r10_still_accepted_last: acceptedRecover.filter(event => event.r10_landing_last).length,
  r11_still_accepted_last: acceptedRecover.filter(event => event.r11_landing_last).length,
};
const result = {
  r12_accepted: summarize(accepted),
  r12_rejected_r10_accepted: summarize(r10Rejected, true),
  r12_rejected_r11_accepted: summarize(r11Rejected, true),
  accepted_predictor_overlap: {
    r10: accepted.filter(event => event.r10_landing).length,
    r11: accepted.filter(event => event.r11_landing).length,
    r12_only_vs_r10_r11: accepted.filter(event => !event.r10_landing && !event.r11_landing).length,
  },
  accepted_predictor_matrix: acceptedPredictorMatrix,
  accepted_late_recovery_followup: acceptedLateRecovery,
  accepted_input_trace: acceptedTrace,
  r10_rejected_r11_accepts: r10Rejected.filter(event => event.r11_landing).length,
};

const output = path.join(reportDir, "round12-fall-analysis.json");
fs.writeFileSync(output, `${JSON.stringify(result, null, 2)}\n`, "utf8");
console.log(JSON.stringify(result, null, 2));
