const fs = require('fs');
const path = require('path');

const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
const roundName = process.argv[2] || 'round4';
const data = JSON.parse(fs.readFileSync(path.join(reportDir, `${roundName}-results.json`), 'utf8').replace(/^\uFEFF/, ''));
const t = data.totals;
const chars = ['frey', 'luna', 'nova', 'rio', 'yuki'];
const phases = ['Exploration', 'Corner collapse warning', 'Convergence', 'Central brawl'];
const stateOrder = ['wander', 'pursue', 'engage', 'portal', 'recover'];
const targetOrder = ['player', 'monster', 'crystal', 'none'];
const buckets = ['0_120', '120_240', '240_360', '360_plus'];
const sum = values => values.reduce((a, b) => a + Number(b || 0), 0);
const pct = (n, d) => d ? 100 * n / d : 0;
const round = (n, digits = 2) => Number(n.toFixed(digits));

function keyedShares(source, prefixParts, labels) {
  const values = Object.fromEntries(labels.map(label => [label, Number(source[[...prefixParts, label].join('|')] || 0)]));
  const total = sum(Object.values(values));
  return Object.fromEntries(labels.map(label => [label, round(pct(values[label], total))]));
}

function attackByCharacter(character) {
  const rows = Object.entries(t.attacks).filter(([key]) => key.startsWith(character + '|'));
  const uses = sum(rows.map(([, value]) => value.uses));
  const hits = sum(rows.map(([, value]) => value.hits));
  return {uses, hits, hit_rate: round(pct(hits, uses)), pvp_dpm: round(Number(t.pvp_damage[character] || 0) / Number(t.character_seconds[character]) * 60), pve_dpm: round(Number(t.pve_damage[character] || 0) / Number(t.character_seconds[character]) * 60)};
}

function swingDistance(character, attackType = null) {
  const result = Object.fromEntries(buckets.map(bucket => [bucket, {uses: 0, hits: 0}]));
  for (const [key, value] of Object.entries(t.swing_context)) {
    const [keyCharacter, keyAttack, bucket] = key.split('|');
    if (keyCharacter !== character || (attackType && keyAttack !== attackType) || !result[bucket]) continue;
    result[bucket].uses += Number(value.uses || 0);
    result[bucket].hits += Number(value.hits || 0);
  }
  for (const value of Object.values(result)) value.miss_rate = round(pct(value.uses - value.hits, value.uses));
  return result;
}

function swingTargets(character, attackType) {
  const result = {};
  for (const [key, value] of Object.entries(t.swing_context)) {
    const [keyCharacter, keyAttack, , kind] = key.split('|');
    if (keyCharacter !== character || keyAttack !== attackType) continue;
    result[kind] ||= {uses: 0, hits: 0};
    result[kind].uses += Number(value.uses || 0);
    result[kind].hits += Number(value.hits || 0);
  }
  for (const value of Object.values(result)) value.miss_rate = round(pct(value.uses - value.hits, value.uses));
  return result;
}

function swingDistance60(character, basicOnly = true) {
  const result = {};
  for (const [key, value] of Object.entries(t.swing_context_60 || {})) {
    const [keyCharacter, keyAttack, bucket] = key.split('|');
    if (keyCharacter !== character || (basicOnly && !keyAttack.startsWith('basic_'))) continue;
    result[bucket] ||= {uses: 0, hits: 0};
    result[bucket].uses += Number(value.uses || 0);
    result[bucket].hits += Number(value.hits || 0);
  }
  for (const value of Object.values(result)) value.hit_rate = round(pct(value.hits, value.uses));
  return Object.fromEntries(Object.entries(result).sort(([a], [b]) => Number.parseInt(a) - Number.parseInt(b)));
}

const lengths = data.matches.map(row => Number(row.seconds)).sort((a, b) => a - b);
const allAttacks = Object.values(t.attacks);
const totalAttackUses = sum(allAttacks.map(row => row.uses));
const totalAttackHits = sum(allAttacks.map(row => row.hits));
const targetSamples = sum(Object.values(t.targets));
const stateSamples = sum(Object.values(t.states));
const noTarget = sum(Object.entries(t.targets).filter(([key]) => key.endsWith('|none')).map(([, value]) => value));
const wander = sum(Object.entries(t.states).filter(([key]) => key.endsWith('|wander')).map(([, value]) => value));
const noProgressEpisodes = sum(Object.values(t.no_progress).map(row => row.episodes));
const noProgressSeconds = sum(Object.values(t.no_progress).map(row => row.seconds));
const characterSeconds = sum(Object.values(t.character_seconds));

const dropsByKind = {};
for (const row of data.target_drop_events) {
  const kind = row.target_kind;
  dropsByKind[kind] ||= {all: 0, within_300: 0, traded_within_3s: 0, either: 0};
  dropsByKind[kind].all++;
  if (row.within_300) dropsByKind[kind].within_300++;
  if (row.traded_within_3s) dropsByKind[kind].traded_within_3s++;
  if (row.within_300 || row.traded_within_3s) dropsByKind[kind].either++;
}

const ringouts = {};
for (const character of chars) {
  const rows = data.ringouts.filter(row => row.victim === character);
  ringouts[character] = {all: rows.length, zero_jumps: rows.filter(row => Number(row.air_jumps_left) === 0).length};
}

const wins = Object.fromEntries(chars.map(character => [character, data.matches.filter(row => row.winner === character).length]));
const recoveryEpisodeUseCounts = {};
for (const row of data.recovery_skill_events || []) {
  const key = `${row.seed}|${row.character}|${row.recovery_episode}`;
  recoveryEpisodeUseCounts[key] = Number(recoveryEpisodeUseCounts[key] || 0) + 1;
}
const recoveryEpisodeUses = {};
for (const character of ['frey', 'nova', 'rio']) {
  const counts = Object.entries(recoveryEpisodeUseCounts)
    .filter(([key]) => key.split('|')[1] === character)
    .map(([, count]) => count);
  recoveryEpisodeUses[character] = {
    episodes_with_use: counts.length,
    one_use: counts.filter(count => count === 1).length,
    two_uses: counts.filter(count => count === 2).length,
    three_plus: counts.filter(count => count >= 3).length,
    max_uses: counts.length ? Math.max(...counts) : 0
  };
}
const freyFailedSecondDashes = (data.recovery_skill_events || []).filter(row => row.character === 'frey' && Number(row.use_index) === 2 && !row.reached_floor);
const deadBandsBySeed = {};
for (const row of data.dead_band_events || []) {
  deadBandsBySeed[row.seed] ||= {count: 0, seconds: 0, longest: 0};
  deadBandsBySeed[row.seed].count++;
  deadBandsBySeed[row.seed].seconds += Number(row.duration || 0);
  deadBandsBySeed[row.seed].longest = Math.max(deadBandsBySeed[row.seed].longest, Number(row.duration || 0));
}
for (const value of Object.values(deadBandsBySeed)) {
  value.seconds = round(value.seconds, 1);
  value.longest = round(value.longest, 1);
}
const byCharacter = {};
for (const character of chars) {
  const stateCounts = Object.fromEntries(stateOrder.map(label => [label, sum(phases.map(phase => Number(t.states[`${character}|${phase}|${label}`] || 0)))]));
  const stateTotal = sum(Object.values(stateCounts));
  const targetCounts = Object.fromEntries(targetOrder.map(label => [label, sum(phases.map(phase => Number(t.targets[`${character}|${phase}|${label}`] || 0)))]));
  const targetTotal = sum(Object.values(targetCounts));
  const recovery = t.recovery[character] || {success: 0, fail: 0, unfinished: 0};
  const recoveryTotal = Number(recovery.success || 0) + Number(recovery.fail || 0) + Number(recovery.unfinished || 0);
  byCharacter[character] = {
    states: Object.fromEntries(stateOrder.map(label => [label, round(pct(stateCounts[label], stateTotal))])),
    targets: Object.fromEntries(targetOrder.map(label => [label, round(pct(targetCounts[label], targetTotal))])),
    switches_per_target_minute: round(Number(t.target_switches[character] || 0) / (Number(t.target_active_seconds[character] || 0) / 60)),
    no_progress: t.no_progress[character] || {episodes: 0, seconds: 0},
    attack: attackByCharacter(character),
    ringouts: ringouts[character],
    recovery: {...recovery, rate: round(pct(Number(recovery.success || 0), recoveryTotal))},
    distance: swingDistance(character),
    distance_60_basic: swingDistance60(character)
  };
}

const byPhase = {};
for (const phase of phases) {
  const states = {};
  const targets = {};
  for (const label of stateOrder) states[label] = sum(chars.map(character => Number(t.states[`${character}|${phase}|${label}`] || 0)));
  for (const label of targetOrder) targets[label] = sum(chars.map(character => Number(t.targets[`${character}|${phase}|${label}`] || 0)));
  const stateTotal = sum(Object.values(states));
  const targetTotal = sum(Object.values(targets));
  byPhase[phase] = {
    states: Object.fromEntries(stateOrder.map(label => [label, round(pct(states[label], stateTotal))])),
    targets: Object.fromEntries(targetOrder.map(label => [label, round(pct(targets[label], targetTotal))]))
  };
}

const summary = {
  match: {median: round((lengths[5] + lengths[6]) / 2, 1), min: lengths[0], max: lengths.at(-1), per_seed: data.matches, wins},
  global: {
    ringouts: data.ringouts.length,
    ringouts_per_match: round(data.ringouts.length / data.matches.length),
    zero_jump_ringouts: data.ringouts.filter(row => Number(row.air_jumps_left) === 0).length,
    recovery_success: sum(Object.values(t.recovery).map(row => row.success)),
    recovery_total: sum(Object.values(t.recovery).map(row => Number(row.success || 0) + Number(row.fail || 0) + Number(row.unfinished || 0))),
    portals: Number(t.portals.all || 0),
    portal_reasons: t.portal_reasons,
    collapse_escape: Number(t.portals.collapse_escape || 0),
    collapse_relocation: Number(t.portals.collapse_relocation || 0),
    no_target_pct: round(pct(noTarget, targetSamples)),
    wander_pct: round(pct(wander, stateSamples)),
    switches_per_target_minute: round(sum(Object.values(t.target_switches)) / (sum(Object.values(t.target_active_seconds)) / 60)),
    target_drops: data.target_drop_events.length,
    no_progress_episodes: noProgressEpisodes,
    no_progress_seconds: round(noProgressSeconds, 1),
    no_progress_active_pct: round(pct(noProgressSeconds, characterSeconds)),
    stuck_seconds: round(sum(Object.values(t.stuck)), 1),
    stuck_pct: round(pct(sum(Object.values(t.stuck)), characterSeconds)),
    standoffs: t.standoffs,
    attack_uses: totalAttackUses,
    attack_hits: totalAttackHits,
    attack_hit_rate: round(pct(totalAttackHits, totalAttackUses))
  },
  by_character: byCharacter,
  by_phase: byPhase,
  drops_by_kind: dropsByKind,
  guards: t.guards_by_attacker,
  escapes: t.corner_escapes,
  recovery_skills: t.recovery_skills,
  recovery_skill_asks: t.recovery_skill_asks || {},
  recovery_skill_ask_events: data.recovery_skill_ask_events || [],
  recovery_skill_episode_uses: recoveryEpisodeUses,
	dead_bands: {count: (data.dead_band_events || []).length, by_seed: deadBandsBySeed, events: data.dead_band_events || []},
	target_drop_causes: t.target_drop_causes || {},
	zero_jump_ringout_causes: t.zero_jump_ringout_causes || {},
	frey_failed_second_dashes: {
		count: freyFailedSecondDashes.length,
		shortened: freyFailedSecondDashes.filter(row => Number(row.shortened_by || 0) > 0).length,
		rows: freyFailedSecondDashes
	},
  standoff_trace_events: data.standoff_trace_events || [],
  progress_extensions: t.progress_extensions || {},
  progress_extension_events: data.progress_extension_events || [],
  cornered_guards: t.cornered_guards || {},
  frey_recovery_entries: t.frey_recovery_entries,
  yuki: {side_distance: swingDistance('yuki', 'basic_side'), side_targets: swingTargets('yuki', 'basic_side'), ledge_ringouts: t.yuki_ledge_ringouts},
  rio: {side_distance: swingDistance('rio', 'basic_side'), side_targets: swingTargets('rio', 'basic_side'), pvp_dpm: byCharacter.rio.attack.pvp_dpm, wins: wins.rio},
  nova: t.nova,
  portal: {all: t.portals, reasons: t.portal_reasons},
  air_down_self_ringouts: t.air_down_self_ringouts,
  stuck_worst: Object.entries(t.stuck).sort((a, b) => b[1] - a[1]).slice(0, 10)
};

fs.writeFileSync(path.join(reportDir, `${roundName}-summary.json`), JSON.stringify(summary, null, 2) + '\n');
console.log(JSON.stringify(summary, null, 2));
