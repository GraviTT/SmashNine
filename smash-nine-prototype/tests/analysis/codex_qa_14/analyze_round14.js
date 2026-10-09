const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
const read = name => JSON.parse(fs.readFileSync(path.join(reportDir, name), 'utf8').replace(/^\uFEFF/, ''));
const compact14 = read('round14-results.json');
const r14 = Array.isArray(compact14.fall_frames) ? compact14 : JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(reportDir, compact14.full_archive))).toString('utf8'));
const r11 = read('round11-summary.json');
const r13 = read('round13-summary.json');
const r11Raw = read('round11-results.json');
const characters = ['frey', 'luna', 'nova', 'rio', 'yuki'];
const attackTypes = ['basic_side','basic_up','basic_down','basic_air_side','basic_air_up','basic_air_down','skill_1','skill_2'];
const sum = values => values.reduce((a, b) => a + Number(b || 0), 0);
const pct = (a, b) => b ? Number((100 * a / b).toFixed(2)) : 0;
const rounded = value => Number(Number(value || 0).toFixed(2));
const median = values => {
  const sorted = [...values].sort((a, b) => a - b);
  if (!sorted.length) return 0;
  const i = Math.floor(sorted.length / 2);
  return rounded(sorted.length % 2 ? sorted[i] : (sorted[i - 1] + sorted[i]) / 2);
};
const countBy = (rows, key) => rows.reduce((out, row) => {
  const value = typeof key === 'function' ? key(row) : row[key];
  out[value] = (out[value] || 0) + 1;
  return out;
}, {});
const dictSum = dict => sum(Object.values(dict || {}));

function samplesFor(character, source, wanted) {
  return sum(Object.entries(source || {}).filter(([key]) => {
    const parts = key.split('|');
    return parts[0] === character && parts[parts.length - 1] === wanted;
  }).map(([, value]) => value));
}

function activationStats(raw) {
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
  return { byType, byCharacter };
}

const activations14 = activationStats(r14);
const samplesTotal = dictSum(r14.totals.samples);
const noneSamples = sum(Object.entries(r14.totals.targets || {}).filter(([key]) => key.endsWith('|none')).map(([, value]) => value));
const wanderSamples = sum(Object.entries(r14.totals.states || {}).filter(([key]) => key.endsWith('|wander')).map(([, value]) => value));
const recoveryTotals = Object.values(r14.totals.recovery || {}).reduce((out, row) => {
  out.success += Number(row.success || 0); out.fail += Number(row.fail || 0); out.unfinished += Number(row.unfinished || 0); return out;
}, { success: 0, fail: 0, unfinished: 0 });
const noProgressSeconds = sum(Object.values(r14.totals.no_progress || {}).map(row => row.seconds));
const noProgressEpisodes = sum(Object.values(r14.totals.no_progress || {}).map(row => row.episodes));
const activeSeconds = dictSum(r14.totals.character_seconds);
const standoffs14 = r14.totals.standoffs || [];
const inputless14 = (r14.fixture_candidates || []).filter(row => row.kind === 'inputless_engage' && Number(row.duration) >= 5);
const drops14 = countBy(r14.target_drop_events || [], 'cause');
const uncheckedDrops = (r14.target_drop_events || []).filter(row => row.chosen_without_route_check);
const selectionModes = countBy(r14.target_selection_events || [], 'mode');

const ultimate14 = {};
const ultimate11Legacy = {};
const ultimate14Legacy = {};
for (const character of characters) {
  const rows = (r14.ultimate_events || []).filter(row => row.character === character);
  ultimate14[character] = {
    activations: rows.length,
    hit_activations: rows.filter(row => row.hit).length,
    hit_rate: pct(rows.filter(row => row.hit).length, rows.length),
    hit_events: sum(rows.map(row => row.hit_events)),
    damage: rounded(sum(rows.map(row => row.damage))),
  };
  const legacy = (r11Raw.totals.attacks || {})[`${character}|ultimate`] || { uses: 0, hits: 0 };
  ultimate11Legacy[character] = { requests: legacy.uses, hits_within_0_4s: legacy.hits, rate: pct(legacy.hits, legacy.uses) };
  const currentLegacy = (r14.totals.attacks || {})[`${character}|ultimate`] || { uses: 0, hits: 0 };
  ultimate14Legacy[character] = { requests: currentLegacy.uses, hits_within_0_4s: currentLegacy.hits, rate: pct(currentLegacy.hits, currentLegacy.uses) };
}

const ringouts14 = {};
const noProgress14 = {};
const recoverySkills14 = {};
const pvpDpm14 = {};
const noTargetWander14 = {};
for (const character of characters) {
  const ringRows = (r14.ringouts || []).filter(row => row.victim === character);
  ringouts14[character] = { all: ringRows.length, zero_jumps: ringRows.filter(row => Number(row.air_jumps_left) <= 0).length };
  const causeRows = Object.entries(r14.no_progress_causes || {}).filter(([key]) => key.startsWith(`${character}|`));
  noProgress14[character] = { total: rounded(sum(causeRows.map(([, value]) => value))), causes: Object.fromEntries(causeRows.map(([key, value]) => [key.split('|')[1], rounded(value)])) };
  const skillRows = (r14.recovery_skill_events || []).filter(row => row.character === character);
  recoverySkills14[character] = { used: skillRows.length, reached_floor: skillRows.filter(row => row.reached_floor).length };
  const seconds = Number((r14.totals.character_seconds || {})[character] || 0);
  pvpDpm14[character] = rounded(60 * Number((r14.totals.pvp_damage || {})[character] || 0) / Math.max(seconds, 1));
  const charSamples = samplesFor(character, r14.totals.samples, 'Exploration') + samplesFor(character, r14.totals.samples, 'Corner collapse warning') + samplesFor(character, r14.totals.samples, 'Convergence') + samplesFor(character, r14.totals.samples, 'Central brawl');
  const none = samplesFor(character, r14.totals.targets, 'none');
  const wander = samplesFor(character, r14.totals.states, 'wander');
  noTargetWander14[character] = { no_target_seconds: rounded(none * Number(r14.sample_interval)), no_target_pct: pct(none, charSamples), wander_seconds: rounded(wander * Number(r14.sample_interval)), wander_pct: pct(wander, charSamples) };
}

const matchSeconds = r14.matches.map(row => Number(row.seconds));
const fallMetrics14 = {
  frame_count: r14.fall_frames.length,
  frame_landing: r14.fall_frames.filter(row => row.h).length,
  flips: r14.fall_flips.length,
  flips_by_class: countBy(r14.fall_flips, 'class'),
  flips_before_ringout: r14.fall_flips.filter(row => row.before_ringout).length,
  r10_only_falls: r14.r10_only_fall_events.length,
  r10_only_outcomes: countBy(r14.r10_only_fall_events, 'outcome'),
  r10_only_entered_recovery: r14.r10_only_fall_events.filter(row => row.entered_recovery).length,
};
const summary = {
  conditions: { seeds: r14.seeds, players: r14.players, seconds_cap: 480, fixed_fps: 60, wall_seconds: r14.wall_seconds },
  r11: {
    match: r11.match,
    global: r11.global,
    drops: r11.target_drop_causes,
    no_progress_causes: r13.no_progress_causes,
    recovery_skills: r11.recovery_skills,
    ringouts: Object.fromEntries(characters.map(c => [c, r11.by_character[c].ringouts])),
    pvp_dpm: Object.fromEntries(characters.map(c => [c, r11.by_character[c].attack.pvp_dpm])),
    activation_hit_rate: r13.attack_activations,
    ultimate_legacy_0_4s: ultimate11Legacy,
  },
  r14: {
    match: { median: median(matchSeconds), min: Math.min(...matchSeconds), max: Math.max(...matchSeconds), per_seed: r14.matches, wins: countBy(r14.matches, 'winner') },
    global: {
      ringouts: r14.ringouts.length,
      zero_jump_ringouts: r14.ringouts.filter(row => Number(row.air_jumps_left) <= 0).length,
      recovery_success: recoveryTotals.success,
      recovery_total: recoveryTotals.success + recoveryTotals.fail + recoveryTotals.unfinished,
      recovery_rate: pct(recoveryTotals.success, recoveryTotals.success + recoveryTotals.fail + recoveryTotals.unfinished),
      portals: sum(r14.matches.map(row => row.portals)),
      target_switches_per_minute: rounded(60 * dictSum(r14.totals.target_switches) / Math.max(dictSum(r14.totals.target_active_seconds), 1)),
      no_target_seconds: rounded(noneSamples * Number(r14.sample_interval)),
      no_target_pct: pct(noneSamples, samplesTotal),
      wander_seconds: rounded(wanderSamples * Number(r14.sample_interval)),
      wander_pct: pct(wanderSamples, samplesTotal),
      target_drops: r14.target_drop_events.length,
      no_progress_episodes: noProgressEpisodes,
      no_progress_seconds: rounded(noProgressSeconds),
      no_progress_active_pct: pct(noProgressSeconds, activeSeconds),
      inputless_engages_5s: inputless14.length,
      standoffs: standoffs14.length,
      standoff_longest: rounded(Math.max(0, ...standoffs14.map(row => row.duration))),
    },
    drops: drops14,
    unchecked: { selections: selectionModes.unchecked_after_3 || 0, drops: uncheckedDrops.length, drops_by_cause: countBy(uncheckedDrops, 'cause'), selection_modes: selectionModes },
    no_progress: noProgress14,
    no_target_wander: noTargetWander14,
    recovery_skills: recoverySkills14,
    recovery_entry_causes: countBy(r14.recovery_entry_events || [], 'cause'),
    ringouts: ringouts14,
    pvp_dpm: pvpDpm14,
    activation_hit_rate: activations14.byType,
    activation_hit_rate_by_character: activations14.byCharacter,
    ultimates_full_window: ultimate14,
    ultimate_legacy_0_4s: ultimate14Legacy,
    fall_metrics: fallMetrics14,
    inputless_engages: inputless14.map(row => ({ seed: row.seed, character: row.character, duration: row.duration, target_kind: row.target_kind })),
  },
};

fs.writeFileSync(path.join(reportDir, 'round14-summary.json'), `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(summary, null, 2));
