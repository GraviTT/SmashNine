const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
const read = name => JSON.parse(fs.readFileSync(path.join(reportDir, name), 'utf8').replace(/^\uFEFF/, ''));
const compact = read('round15-results.json');
const raw = Array.isArray(compact.fall_frames) ? compact : JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(reportDir, compact.full_archive))).toString('utf8'));
const characters = ['frey', 'luna', 'nova', 'rio', 'yuki'];
const sum = values => values.reduce((a, b) => a + Number(b || 0), 0);
const round = value => Number(Number(value || 0).toFixed(2));
const pct = (a, b) => b ? round(100 * a / b) : 0;
const countBy = (rows, key) => rows.reduce((out, row) => {
  const value = typeof key === 'function' ? key(row) : row[key];
  out[value] = (out[value] || 0) + 1;
  return out;
}, {});
const dictSum = value => sum(Object.values(value || {}));
const median = values => {
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return round(sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2);
};
const samplesFor = (character, source, wanted) => sum(Object.entries(source || {}).filter(([key]) => {
  const parts = key.split('|');
  return parts[0] === character && parts[parts.length - 1] === wanted;
}).map(([, value]) => value));

function activationStats() {
  const byType = {};
  const byCharacter = {};
  for (const [key, stats] of Object.entries(raw.totals.swing_context || {})) {
    const [character, type] = key.split('|');
    byType[type] ||= { uses: 0, hits: 0 };
    byType[type].uses += Number(stats.uses || 0);
    byType[type].hits += Number(stats.hits || 0);
    byCharacter[character] ||= {};
    byCharacter[character][type] ||= { uses: 0, hits: 0 };
    byCharacter[character][type].uses += Number(stats.uses || 0);
    byCharacter[character][type].hits += Number(stats.hits || 0);
  }
  for (const group of [byType, ...Object.values(byCharacter)]) {
    for (const stats of Object.values(group)) stats.hit_rate = pct(stats.hits, stats.uses);
  }
  return { by_type: byType, by_character: byCharacter };
}

const sampleTotal = dictSum(raw.totals.samples);
const noneSamples = sum(Object.entries(raw.totals.targets || {}).filter(([key]) => key.endsWith('|none')).map(([, value]) => value));
const wanderSamples = sum(Object.entries(raw.totals.states || {}).filter(([key]) => key.endsWith('|wander')).map(([, value]) => value));
const activeSeconds = dictSum(raw.totals.character_seconds);
const recovery = Object.values(raw.totals.recovery || {}).reduce((out, row) => {
  out.success += Number(row.success || 0);
  out.fail += Number(row.fail || 0);
  out.unfinished += Number(row.unfinished || 0);
  return out;
}, { success: 0, fail: 0, unfinished: 0 });
const noProgressSeconds = sum(Object.values(raw.totals.no_progress || {}).map(row => row.seconds));
const noProgressEpisodes = sum(Object.values(raw.totals.no_progress || {}).map(row => row.episodes));
const standoffs = raw.totals.standoffs || [];
const inputless = (raw.fixture_candidates || []).filter(row => row.kind === 'inputless_engage' && Number(row.duration) >= 5);

const noProgressByCharacter = {};
const noTargetWander = {};
const ringouts = {};
const recoverySkills = {};
const pvpDpm = {};
const ultimates = {};
for (const character of characters) {
  const causeRows = Object.entries(raw.no_progress_causes || {}).filter(([key]) => key.startsWith(`${character}|`));
  noProgressByCharacter[character] = {
    total: round(sum(causeRows.map(([, value]) => value))),
    causes: Object.fromEntries(causeRows.map(([key, value]) => [key.split('|')[1], round(value)])),
  };
  const charSamples = sum(['Exploration', 'Corner collapse warning', 'Convergence', 'Central brawl'].map(phase => samplesFor(character, raw.totals.samples, phase)));
  const none = samplesFor(character, raw.totals.targets, 'none');
  const wander = samplesFor(character, raw.totals.states, 'wander');
  noTargetWander[character] = {
    no_target_seconds: round(none * raw.sample_interval), no_target_pct: pct(none, charSamples),
    wander_seconds: round(wander * raw.sample_interval), wander_pct: pct(wander, charSamples),
  };
  const ringRows = (raw.ringouts || []).filter(row => row.victim === character);
  ringouts[character] = { all: ringRows.length, zero_jumps: ringRows.filter(row => Number(row.air_jumps_left) <= 0).length };
  const skillRows = (raw.recovery_skill_events || []).filter(row => row.character === character);
  recoverySkills[character] = { used: skillRows.length, reached_floor: skillRows.filter(row => row.reached_floor).length };
  const seconds = Number((raw.totals.character_seconds || {})[character] || 0);
  pvpDpm[character] = round(60 * Number((raw.totals.pvp_damage || {})[character] || 0) / Math.max(seconds, 1));
  const ultimateRows = (raw.ultimate_events || []).filter(row => row.character === character);
  ultimates[character] = {
    activations: ultimateRows.length,
    hit_activations: ultimateRows.filter(row => row.hit).length,
    hit_rate: pct(ultimateRows.filter(row => row.hit).length, ultimateRows.length),
    hit_events: sum(ultimateRows.map(row => row.hit_events)),
    damage: round(sum(ultimateRows.map(row => row.damage))),
  };
}

const matchSeconds = raw.matches.map(row => Number(row.seconds));
const totalRecovery = recovery.success + recovery.fail + recovery.unfinished;
const selections = countBy(raw.target_selection_events || [], 'mode');
const uncheckedDrops = (raw.target_drop_events || []).filter(row => row.chosen_without_route_check);
const fallMetrics = {
  frame_count: raw.fall_frames.length,
  frame_landing: raw.fall_frames.filter(row => row.h).length,
  flips: raw.fall_flips.length,
  flips_by_class: countBy(raw.fall_flips, 'class'),
  flips_before_ringout: raw.fall_flips.filter(row => row.before_ringout).length,
  r10_only_falls: raw.r10_only_fall_events.length,
  r10_only_outcomes: countBy(raw.r10_only_fall_events, 'outcome'),
  r10_only_entered_recovery: raw.r10_only_fall_events.filter(row => row.entered_recovery).length,
};
const summary = {
  conditions: { seeds: raw.seeds, players: raw.players, seconds_cap: 480, fixed_fps: 60, wall_seconds: raw.wall_seconds },
  match: { median: median(matchSeconds), min: Math.min(...matchSeconds), max: Math.max(...matchSeconds), per_seed: raw.matches, wins: countBy(raw.matches, 'winner') },
  global: {
    ringouts: raw.ringouts.length,
    zero_jump_ringouts: raw.ringouts.filter(row => Number(row.air_jumps_left) <= 0).length,
    recovery_success: recovery.success, recovery_total: totalRecovery, recovery_rate: pct(recovery.success, totalRecovery),
    portals: sum(raw.matches.map(row => row.portals)),
    target_switches_per_minute: round(60 * dictSum(raw.totals.target_switches) / Math.max(dictSum(raw.totals.target_active_seconds), 1)),
    no_target_seconds: round(noneSamples * raw.sample_interval), no_target_pct: pct(noneSamples, sampleTotal),
    wander_seconds: round(wanderSamples * raw.sample_interval), wander_pct: pct(wanderSamples, sampleTotal),
    target_drops: raw.target_drop_events.length,
    no_progress_episodes: noProgressEpisodes, no_progress_seconds: round(noProgressSeconds), no_progress_active_pct: pct(noProgressSeconds, activeSeconds),
    inputless_engages_5s: inputless.length,
    standoffs: standoffs.length, standoff_longest: round(Math.max(0, ...standoffs.map(row => row.duration))),
    pvp_dpm_total: round(sum(Object.values(pvpDpm))),
  },
  drops: countBy(raw.target_drop_events || [], 'cause'),
  unchecked: { selections: selections.unchecked_after_3 || 0, drops: uncheckedDrops.length, selection_modes: selections },
  no_progress: noProgressByCharacter,
  no_target_wander: noTargetWander,
  recovery_entry_causes: countBy(raw.recovery_entry_events || [], 'cause'),
  recovery_skills: recoverySkills,
  ringouts,
  pvp_dpm: pvpDpm,
  activation_hit_rate: activationStats(),
  ultimates_full_window: ultimates,
  fall_metrics: fallMetrics,
  standoffs,
  inputless_engages: inputless.map(row => ({ seed: row.seed, character: row.character, duration: row.duration, target_kind: row.target_kind })),
};

fs.writeFileSync(path.join(reportDir, 'round15-summary.json'), `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(summary, null, 2));
