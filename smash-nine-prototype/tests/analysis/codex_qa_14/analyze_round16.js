const fs = require('fs');
const path = require('path');
const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
const characters = ['frey', 'luna', 'nova', 'rio', 'yuki'];
const read = name => JSON.parse(fs.readFileSync(path.join(reportDir, name), 'utf8').replace(/^\uFEFF/, ''));
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

function summarize(raw) {
  const sampleTotal = dictSum(raw.totals.samples);
  const noneSamples = sum(Object.entries(raw.totals.targets || {}).filter(([key]) => key.endsWith('|none')).map(([, value]) => value));
  const wanderSamples = sum(Object.entries(raw.totals.states || {}).filter(([key]) => key.endsWith('|wander')).map(([, value]) => value));
  const activeSeconds = dictSum(raw.totals.character_seconds);
  const noProgressSeconds = sum(Object.values(raw.totals.no_progress || {}).map(row => row.seconds));
  const noProgressEpisodes = sum(Object.values(raw.totals.no_progress || {}).map(row => row.episodes));
  const out = {
    conditions: { variant: raw.variant, matches: raw.matches.length, wall_seconds: raw.wall_seconds },
    match: {
      median: median(raw.matches.map(row => Number(row.seconds))),
      min: Math.min(...raw.matches.map(row => Number(row.seconds))),
      max: Math.max(...raw.matches.map(row => Number(row.seconds))),
      per_seed: raw.matches,
    },
    global: {
      ringouts: raw.ringouts.length,
      zero_jump_ringouts: raw.ringouts.filter(row => Number(row.air_jumps_left) <= 0).length,
      no_progress_seconds: round(noProgressSeconds),
      no_progress_episodes: noProgressEpisodes,
      no_progress_active_pct: pct(noProgressSeconds, activeSeconds),
      wrong_level_seconds: round(sum(Object.entries(raw.no_progress_causes || {}).filter(([key]) => key.endsWith('|wrong_level')).map(([, value]) => value))),
      no_target_seconds: round(noneSamples * raw.sample_interval),
      no_target_pct: pct(noneSamples, sampleTotal),
      wander_seconds: round(wanderSamples * raw.sample_interval),
      wander_pct: pct(wanderSamples, sampleTotal),
      target_drops: raw.target_drop_events.length,
      recovery_entries: raw.recovery_entry_events.length,
    },
    ringouts: {}, ringout_starts: {}, drops: countBy(raw.target_drop_events, 'cause'),
    recovery_entry_causes: countBy(raw.recovery_entry_events, 'cause'),
    no_progress: {}, no_target_wander: {}, pvp_dpm: {}, ultimates_full_window: {},
  };
  for (const character of characters) {
    const ringRows = raw.ringouts.filter(row => row.victim === character);
    const startRows = (raw.ringout_starts || []).filter(row => row.victim === character);
    const causeRows = Object.entries(raw.no_progress_causes || {}).filter(([key]) => key.startsWith(`${character}|`));
    const charSamples = sum(['Exploration', 'Corner collapse warning', 'Convergence', 'Central brawl'].map(phase => samplesFor(character, raw.totals.samples, phase)));
    const none = samplesFor(character, raw.totals.targets, 'none');
    const wander = samplesFor(character, raw.totals.states, 'wander');
    const seconds = Number((raw.totals.character_seconds || {})[character] || 0);
    const ultimateRows = (raw.ultimate_events || []).filter(row => row.character === character);
    out.ringouts[character] = { all: ringRows.length, zero_jumps: ringRows.filter(row => Number(row.air_jumps_left) <= 0).length };
    out.ringout_starts[character] = {
      all: startRows.length,
      pvp_hit_within_3s: startRows.filter(row => row.pvp_hit_within_3s).length,
      ultimate_hit_within_3s: startRows.filter(row => row.ultimate_hit_within_3s).length,
    };
    out.no_progress[character] = {
      total: round(sum(causeRows.map(([, value]) => value))),
      causes: Object.fromEntries(causeRows.map(([key, value]) => [key.split('|')[1], round(value)])),
    };
    out.no_target_wander[character] = {
      no_target_seconds: round(none * raw.sample_interval), no_target_pct: pct(none, charSamples),
      wander_seconds: round(wander * raw.sample_interval), wander_pct: pct(wander, charSamples),
    };
    out.pvp_dpm[character] = round(60 * Number((raw.totals.pvp_damage || {})[character] || 0) / Math.max(seconds, 1));
    out.ultimates_full_window[character] = {
      activations: ultimateRows.length,
      hit_activations: ultimateRows.filter(row => row.hit).length,
      hit_rate: pct(ultimateRows.filter(row => row.hit).length, ultimateRows.length),
      hit_events: sum(ultimateRows.map(row => row.hit_events)),
      damage: round(sum(ultimateRows.map(row => row.damage))),
    };
  }
  return out;
}

const r11 = read('round11-summary.json');
const r15 = read('round15-summary.json');
const s0 = summarize(read('round16-s0-results.json'));
const u0 = summarize(read('round16-u0-results.json'));
const baseline = {
  r11: {
    match: r11.match,
    global: { ...r11.global, wrong_level_seconds: 431.75, recovery_entries: r11.recovery_entries.total },
    ringouts: Object.fromEntries(characters.map(c => [c, r11.by_character[c].ringouts])),
    drops: r11.target_drop_causes,
    recovery_entry_causes: Object.fromEntries(Object.entries(r11.recovery_entries.causes).map(([key, value]) => [key, value.entries])),
    pvp_dpm: Object.fromEntries(characters.map(c => [c, r11.by_character[c].attack.pvp_dpm])),
    yuki_pvp_hit_within_3s: 15,
    ultimate_full_window: null,
  },
  r15,
  s0,
  u0,
  notes: {
    r11_wrong_level_source: 'round15.md comparison table; R11 observer did not split no-progress causes',
    r11_yuki_pvp_source: 'deterministic R11-equivalent round13-a ringout_details (15/16)',
    r15_yuki_pvp_source: 'round15.md ringout_details (33/37)',
    r11_r15_ultimate_ringout_attribution: 'not observed; Round 16 variants record exact full-window attribution',
  },
};
fs.writeFileSync(path.join(reportDir, 'round16-summary.json'), `${JSON.stringify(baseline, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({s0, u0}, null, 2));
