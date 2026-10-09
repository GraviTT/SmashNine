const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
const read = name => {
  let text = fs.readFileSync(path.join(reportDir, name), 'utf8');
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  return JSON.parse(text);
};
const readRound13 = name => {
  const compact = read(name);
  if (Array.isArray(compact.fall_frames)) return compact;
  if (!compact.full_archive) throw new Error(`${name} has no fall_frames or full_archive`);
  return JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(reportDir, compact.full_archive))).toString('utf8'));
};
const a = readRound13('round13-a-results.json');
const b = readRound13('round13-b-results.json');
const r10 = read('round10-summary.json');
const r11 = read('round11-summary.json');
const r12 = read('round12-summary.json');

const characters = ['frey', 'luna', 'nova', 'rio', 'yuki'];
const countBy = (rows, key) => rows.reduce((out, row) => {
  const value = typeof key === 'function' ? key(row) : row[key];
  out[value] = (out[value] || 0) + 1;
  return out;
}, {});
const sum = values => values.reduce((x, y) => x + Number(y || 0), 0);
const pct = (x, y) => y ? Number((100 * x / y).toFixed(2)) : 0;
const avg = values => values.length ? Number((sum(values) / values.length).toFixed(2)) : 0;
const median = values => {
  if (!values.length) return 0;
  const sorted = [...values].sort((x, y) => x - y);
  const middle = Math.floor(sorted.length / 2);
  const value = sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  return Number(value.toFixed(2));
};

const baseline = a.matches.map(match => {
  const old = r11.match.per_seed.find(row => row.seed === match.seed);
  const oldEntries = Number(old.recovery_success) + Number(old.recovery_fail);
  const newEntries = Number(match.recovery_success) + Number(match.recovery_fail);
  return {
    seed: match.seed,
    expected: { seconds: old.seconds, winner: old.winner, ringouts: old.ringouts, portals: old.portals, recovery_entries: oldEntries },
    actual: { seconds: match.seconds, winner: match.winner, ringouts: match.ringouts, portals: match.portals, recovery_entries: newEntries },
    equal: old.seconds === match.seconds && old.winner === match.winner && old.ringouts === match.ringouts && old.portals === match.portals && oldEntries === newEntries,
  };
});

const flips = {
  total: a.fall_flips.length,
  by_class: countBy(a.fall_flips, 'class'),
  by_character: {},
  before_ringout: a.fall_flips.filter(row => row.before_ringout).length,
  directions: countBy(a.fall_flips, row => row.from_hit ? 'landing_to_no_landing' : 'no_landing_to_landing'),
  frame_count: a.fall_frames.length,
  frame_hit: a.fall_frames.filter(row => row.h).length,
};
for (const character of characters) {
  const rows = a.fall_flips.filter(row => row.character === character);
  flips.by_character[character] = { total: rows.length, before_ringout: rows.filter(row => row.before_ringout).length, by_class: countBy(rows, 'class') };
}

const aWithRecovery = {};
const bWithoutRecovery = {};
for (const character of characters) {
  const withRows = a.r10_only_fall_events.filter(row => row.character === character);
  const withoutRows = b.ab_suppressed_falls.filter(row => row.character === character);
  aWithRecovery[character] = { total: withRows.length, outcomes: countBy(withRows, 'outcome'), entered_recovery: withRows.filter(row => row.entered_recovery).length };
  bWithoutRecovery[character] = { total: withoutRows.length, outcomes: countBy(withoutRows, 'outcome') };
}
const ab = {
  with_recovery: { total: a.r10_only_fall_events.length, outcomes: countBy(a.r10_only_fall_events, 'outcome'), by_character: aWithRecovery },
  without_recovery: { total: b.ab_suppressed_falls.length, outcomes: countBy(b.ab_suppressed_falls, 'outcome'), by_character: bWithoutRecovery },
  matches: characters.reduce((out, character) => {
    out[character] = {
      a_ringouts: a.ringouts.filter(row => row.victim === character).length,
      b_ringouts: b.ringouts.filter(row => row.victim === character).length,
    };
    return out;
  }, {}),
  a_ringouts: a.ringouts.length,
  b_ringouts: b.ringouts.length,
  a_match_median: median(a.matches.map(row => row.seconds)),
  b_match_median: median(b.matches.map(row => row.seconds)),
};

const ringouts = {};
for (const character of ['luna', 'yuki']) {
  const rows = a.ringout_details.filter(row => row.character === character);
  ringouts[character] = {
    total: rows.length,
    zero_jump: rows.filter(row => row.air_jumps_left <= 0).length,
    last_jump_context: countBy(rows.filter(row => row.air_jumps_left <= 0), 'last_air_jump_context'),
    recovery_target_height_median: median(rows.map(row => row.recovery_target_height_above)),
    horizontal_to_ledge_median: median(rows.map(row => row.horizontal_to_ledge)),
    blast_distance_median: median(rows.map(row => row.distance_to_blast_line)),
    pvp_hit_within_3s: rows.filter(row => row.hit_started_it.age <= 3).length,
    movement_skill_ready: rows.filter(row => row.skills.some(skill => skill.moves_fighter && skill.ready)).length,
    slowing_skill_ready: rows.filter(row => row.skills.some(skill => !skill.moves_fighter && skill.ready && String(skill.air_effect).includes('velocity'))).length,
  };
}

const noRoute = {
  total: a.no_route_details.length,
  target_kind: countBy(a.no_route_details, 'target_kind'),
  reasons: countBy(a.no_route_details, 'no_route_reason'),
  reachable_within_attack: a.no_route_details.filter(row => row.reachable_point_within_attack_range).length,
  next_target: a.no_route_details.filter(row => row.follow.new_target_delay >= 0).length,
  next_target_delay_median: median(a.no_route_details.filter(row => row.follow.new_target_delay >= 0).map(row => row.follow.new_target_delay)),
  portal: a.no_route_details.filter(row => row.follow.portal).length,
  wander: a.no_route_details.filter(row => row.follow.wander).length,
  next_damage: a.no_route_details.filter(row => row.follow.next_damage_delay >= 0).length,
  next_damage_delay_median: median(a.no_route_details.filter(row => row.follow.next_damage_delay >= 0).map(row => row.follow.next_damage_delay)),
};

const fixtureDir = path.join(reportDir, 'fixtures-round13');
fs.mkdirSync(fixtureDir, { recursive: true });
const inputless = a.fixture_candidates.filter(row => row.kind === 'inputless_engage');
const requestedFixtures = [
  inputless.find(row => row.seed === 106 && row.character === 'rio'),
  inputless.find(row => row.seed === 112 && row.character === 'luna'),
].filter(Boolean);
requestedFixtures.forEach((row, index) => fs.writeFileSync(path.join(fixtureDir, `inputless-${index + 1}-seed-${row.seed}-${row.character}.json`), `${JSON.stringify(row, null, 2)}\n`));
const gapRows = a.fixture_candidates.filter(row => row.kind === 'gap_no_landing');
const grouped = new Map();
for (const row of gapRows) {
  const group = grouped.get(row.spot_key) || { count: 0, first: row };
  group.count += 1;
  grouped.set(row.spot_key, group);
}
const topGaps = [...grouped.entries()].map(([spot_key, value]) => ({ spot_key, ...value })).sort((x, y) => y.count - x.count).slice(0, 5);
topGaps.forEach((row, index) => fs.writeFileSync(path.join(fixtureDir, `gap-${index + 1}-count-${row.count}.json`), `${JSON.stringify({ frequency: row.count, spot_key: row.spot_key, ...row.first }, null, 2)}\n`));

const recoverySkills = {};
for (const character of ['frey', 'nova', 'rio']) {
  const rows = a.recovery_skill_events.filter(row => row.character === character);
  recoverySkills[character] = {
    uses: rows.length,
    floor: rows.filter(row => row.reached_floor).length,
    ringout_or_no_floor: rows.filter(row => !row.reached_floor).length,
    hit_within_0_5: rows.filter(row => row.hit_within_0_5).length,
    displacement_0_5: {
      dx_mean: avg(rows.filter(row => row.sampled_0_5).map(row => row.displacement_0_5.x)),
      dy_mean: avg(rows.filter(row => row.sampled_0_5).map(row => row.displacement_0_5.y)),
    },
    shortened_by_mean: avg(rows.map(row => row.shortened_by)),
    shortened_floor_mean: avg(rows.filter(row => row.reached_floor).map(row => row.shortened_by)),
    shortened_no_floor_mean: avg(rows.filter(row => !row.reached_floor).map(row => row.shortened_by)),
    displacement_magnitude_0_5_mean: avg(rows.filter(row => row.sampled_0_5).map(row => Math.hypot(row.displacement_0_5.x, row.displacement_0_5.y))),
    ledge_abs_dx_median: median(rows.map(row => Math.abs(row.ledge_dx))),
    ledge_dy_median: median(rows.map(row => row.ledge_dy)),
    air_jumps_zero: rows.filter(row => row.air_jumps_left <= 0).length,
  };
}

const activationByType = {};
for (const [key, stats] of Object.entries(a.totals.swing_context || {})) {
  const [, type] = key.split('|');
  const target = activationByType[type] || { uses: 0, hits: 0 };
  target.uses += Number(stats.uses || 0);
  target.hits += Number(stats.hits || 0);
  activationByType[type] = target;
}
for (const stats of Object.values(activationByType)) stats.hit_rate = pct(stats.hits, stats.uses);
const requestByType = {};
const requestByCharacter = {};
for (const [key, frames] of Object.entries(a.attack_request_frames || {})) {
  const [character, type] = key.split('|');
  requestByType[type] = (requestByType[type] || 0) + Number(frames);
  requestByCharacter[character] ||= {};
  requestByCharacter[character][type] = (requestByCharacter[character][type] || 0) + Number(frames);
}
const activationByCharacter = {};
for (const [key, stats] of Object.entries(a.totals.swing_context || {})) {
  const [character, type] = key.split('|');
  activationByCharacter[character] ||= {};
  activationByCharacter[character][type] ||= { uses: 0, hits: 0 };
  activationByCharacter[character][type].uses += Number(stats.uses || 0);
  activationByCharacter[character][type].hits += Number(stats.hits || 0);
}
for (const types of Object.values(activationByCharacter)) for (const stats of Object.values(types)) stats.hit_rate = pct(stats.hits, stats.uses);

const summary = {
  baseline: { all_equal: baseline.every(row => row.equal), rows: baseline },
  comparison_rounds: {
    r10: { match_median: r10.match.median, ringouts: r10.global.ringouts, recovery_entries: r10.global.recovery_total, no_progress: r10.global.no_progress_seconds, hit_rate: r10.global.attack_hit_rate },
    r11: { match_median: r11.match.median, ringouts: r11.global.ringouts, recovery_entries: r11.global.recovery_total, no_progress: r11.global.no_progress_seconds, hit_rate: r11.global.attack_hit_rate },
    r12: { match_median: r12.match.median, ringouts: r12.global.ringouts, recovery_entries: r12.global.recovery_total, no_progress: r12.global.no_progress_seconds, hit_rate: r12.global.attack_hit_rate },
  },
  flips,
  ab,
  luna_yuki_ringouts: ringouts,
  no_route: noRoute,
  fixtures: { inputless_found: requestedFixtures.map(row => ({ seed: row.seed, character: row.character, duration: row.duration, target_kind: row.target_kind,
    distance: Number(Math.hypot(row.fixture.bot.position.x - row.fixture.target.position.x, row.fixture.bot.position.y - row.fixture.target.position.y).toFixed(1)) })), top_gaps: topGaps.map(row => ({ spot_key: row.spot_key, count: row.count })) },
  recovery_skills: recoverySkills,
  no_progress_causes: a.no_progress_causes,
  attack_requests: requestByType,
  attack_requests_by_character: requestByCharacter,
  attack_activations: activationByType,
  attack_activations_by_character: activationByCharacter,
  errors: { note: 'logs are scanned separately; certificate-store line is expected sandbox noise' },
};

fs.writeFileSync(path.join(reportDir, 'round13-summary.json'), `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(summary, null, 2));
