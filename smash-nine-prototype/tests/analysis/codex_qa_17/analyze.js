const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../../../../');
const report = path.join(root, 'reports', 'codex-qa-17');

function aggregateBotUsage() {
  const attacks = {};
  const ultimates = {};
  for (let seed = 101; seed <= 112; seed++) {
    const file = path.join(root, 'reports', 'codex-qa-14', `round16-s0-seed-${seed}.json`);
    const data = JSON.parse(fs.readFileSync(file, 'utf8'));
    for (const [key, value] of Object.entries(data.totals.attacks || {})) {
      if (!key.startsWith('frey|') && !key.startsWith('luna|')) continue;
      attacks[key] ||= { uses: 0, hits: 0, damage: 0 };
      attacks[key].uses += value.uses || 0;
      attacks[key].hits += value.hits || 0;
      attacks[key].damage += value.damage || 0;
    }
    for (const row of data.ultimate_events || []) {
      if (!['frey', 'luna'].includes(row.character)) continue;
      ultimates[row.character] ||= { casts: 0, casts_with_hit: 0, hit_events: 0, damage: 0 };
      const out = ultimates[row.character];
      out.casts++;
      out.casts_with_hit += row.hit ? 1 : 0;
      out.hit_events += row.hit_events || 0;
      out.damage += row.damage || 0;
    }
  }
  for (const value of Object.values(attacks)) {
    value.hit_events_per_use = +(value.hits / value.uses).toFixed(3);
    value.damage_per_use = +(value.damage / value.uses).toFixed(3);
    value.damage = +value.damage.toFixed(2);
  }
  for (const value of Object.values(ultimates)) {
    value.cast_hit_rate = +(value.casts_with_hit / value.casts).toFixed(3);
    value.damage_per_cast = +(value.damage / value.casts).toFixed(3);
    value.damage = +value.damage.toFixed(2);
  }
  return { attacks, ultimates, note: 'hits are hit events, not unique successful activations; Luna trail+bloom can exceed one hit per use' };
}

function median(values) {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function aggregateCombos() {
  const data = JSON.parse(fs.readFileSync(path.join(report, 'combo-raw.json'), 'utf8'));
  const groups = {};
  for (const row of data.trials) {
    const key = `${row.character}|${row.route}|${row.start_distance}|${row.moving_bot ? 'bot' : 'dummy'}`;
    groups[key] ||= { character: row.character, route: row.route, distance: row.start_distance, target: row.moving_bot ? 'moving bot' : 'dummy', trials: 0, connects: 0, hits: [], knockback: [], gaps: [] };
    const group = groups[key];
    group.trials++;
    group.connects += row.connected ? 1 : 0;
    group.hits.push(row.hits);
    group.knockback.push(row.knockback_distance);
    group.gaps.push(...row.gap_frames);
  }
  return Object.values(groups).map(group => ({
    character: group.character,
    route: group.route,
    distance: group.distance,
    target: group.target,
    trials: group.trials,
    connect_rate: +(group.connects / group.trials).toFixed(3),
    avg_hits: +(group.hits.reduce((a, b) => a + b, 0) / group.trials).toFixed(2),
    median_gap_frames: median(group.gaps),
    gap_range: group.gaps.length ? [Math.min(...group.gaps), Math.max(...group.gaps)] : [],
    avg_knockback_distance: +(group.knockback.reduce((a, b) => a + b, 0) / group.trials).toFixed(1)
  }));
}

function aggregateMatchProbe() {
  const data = JSON.parse(fs.readFileSync(path.join(report, 'match-raw.json'), 'utf8'));
  const ultimates = {};
  for (const row of data.ultimate_events || []) {
    ultimates[row.character] ||= { casts: 0, hit_within_1s: 0, likely_cancelled: 0 };
    const out = ultimates[row.character];
    out.casts++;
    out.hit_within_1s += row.hit_within_1s ? 1 : 0;
    out.likely_cancelled += row.likely_cancelled ? 1 : 0;
  }
  const forms = data.luna_forms || [];
  return {
    seeds: data.seeds,
    seconds_cap: data.matches?.[0]?.seconds ?? null,
    ultimates,
    luna: {
      casts: ultimates.luna?.casts || 0,
      forms: forms.length,
      heart_lasers: forms.filter(row => row.heart_laser).length,
      average_form_seconds: forms.length ? +(forms.reduce((sum, row) => sum + row.duration, 0) / forms.length).toFixed(2) : null
    },
    frey_followups: data.frey_followups,
    limitation: '90-second early-match samples; likely_cancelled is an inference, not a product cancellation signal'
  };
}

const output = { bot_usage: aggregateBotUsage(), combos: aggregateCombos(), match_probe: aggregateMatchProbe() };
fs.writeFileSync(path.join(report, 'summary.json'), JSON.stringify(output, null, 2));
console.log(JSON.stringify(output, null, 2));
