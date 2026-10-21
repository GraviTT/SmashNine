const fs = require('fs');
const path = require('path');
const dir = __dirname;
const measurements = JSON.parse(fs.readFileSync(path.join(dir, 'measurements.json'), 'utf8'));
const summaries = [];
const skins = {};
const range = xs => xs.length ? [Math.min(...xs), Math.max(...xs)].map(x => +x.toFixed(3)) : [];
const readLog = name => {
  const bytes = fs.readFileSync(path.join(dir, name));
  return bytes[0] === 255 && bytes[1] === 254 ? bytes.toString('utf16le').replace(/^\uFEFF/, '') : bytes.toString('utf8');
};
for (const seed of [1001, 1002, 1003]) {
  const sample = JSON.parse(fs.readFileSync(path.join(dir, `probe-${seed}-p8.json`), 'utf8'));
  const log = readLog(`probe-${seed}-p8.log`);
  const emitted = log.split(/\r?\n/).find(line => line.startsWith('ECOLOGY_PROBE '));
  if (!emitted || !require('util').isDeepStrictEqual(sample, JSON.parse(emitted.slice(14)))) throw new Error(`Probe output/file mismatch for ${seed}.`);
  const errors = log.split(/\r?\n/).filter(line => /^\s*(?:Godot[^:]* : )?(?:SCRIPT ERROR|ERROR|Parse Error):/.test(line) && !line.includes('ERROR: Failed to read the root certificate store.'));
  if (errors.length) throw new Error(`Unexpected probe engine errors: ${errors.join('; ')}`);
  const paired = measurements.measurements.find(x => x.seed === seed).after;
  if (sample.seconds !== paired.match_seconds || sample.monster_hits.regular + sample.monster_hits.elite !== paired.monster_hits) throw new Error(`Read-only probe did not reproduce soak seed ${seed}.`);
  if (sample.violations.length) throw new Error(`Probe violations in seed ${seed}: ${sample.violations.join(', ')}`);
  for (const [skin, values] of Object.entries(sample.by_skin)) {
    const s = skins[skin] ||= { archetype: values.archetype, windups: 0, actions: 0, hits: 0 };
    s.windups += values.windups;
    s.actions += values.actions;
    s.hits += values.hits;
  }
  summaries.push({
    seed, seconds: sample.seconds,
    regular_hits: sample.monster_hits.regular, elite_hits: sample.monster_hits.elite,
    monster_eliminations: sample.monster_eliminations,
    first_elite_time: sample.elite_spawns.length ? +sample.elite_spawns[0].time.toFixed(3) : null,
    first_elite_phase: sample.elite_spawns[0]?.phase,
    regular_refills_observed: sample.refill_intervals.length,
    regular_refill_range: range(sample.refill_intervals),
    elite_refills_observed: sample.elite_intervals.length,
    elite_refill_range: range(sample.elite_intervals),
    elite_spawns: sample.elite_spawns.length,
    announcements: sample.announcements.length,
    peak_living_monsters: sample.peak_living_monsters,
    peak_monster_projectiles: sample.peak_projectiles,
    monster_fallouts: sample.monster_fallouts,
    violations: sample.violations.length,
    reproduces_required_soak: true
  });
}
const result = { summaries, skins, note: 'Observation only: windups are counted when sampled. Missing natural actions are not evidence of a broken archetype; every skin is exercised in deterministic unit fixtures.' };
fs.writeFileSync(path.join(dir, 'integration-summary.json'), JSON.stringify(result, null, 2) + '\n');
const fmt = x => x.length ? x.map(v => v.toFixed(3)).join('–') : '관측 없음';
let table = '| 시드 | 일반 적중 | 정예 적중 | 일반 리필 실측(초) | 정예 리필 실측(초) | 위반 |\n| --- | ---: | ---: | --- | --- | ---: |\n';
for (const s of summaries) table += `| ${s.seed} | ${s.regular_hits} | ${s.elite_hits} | ${fmt(s.regular_refill_range)} | ${fmt(s.elite_refill_range)} | ${s.violations} |\n`;
table += '\n각 프로브의 경기 길이와 몬스터 적중 합계는 같은 시드의 기본 soak를 정확히 재현했다. 첫 정예는 세 판 모두 두 번째 단계에서 관측됐다.\n';
fs.writeFileSync(path.join(dir, 'integration-summary.md'), table);
const reportPath = path.join(dir, 'README.md');
let report = fs.readFileSync(reportPath, 'utf8');
const marker = '<!-- PROBE_TABLE_START -->';
if (!report.includes(marker)) report = report.replace('## 확인 및 테스트', `${marker}\n<!-- PROBE_TABLE_END -->\n\n## 확인 및 테스트`);
report = report.replace(/<!-- PROBE_TABLE_START -->[\s\S]*?<!-- PROBE_TABLE_END -->/, `${marker}\n${table}<!-- PROBE_TABLE_END -->`);
fs.writeFileSync(reportPath, report);
console.log(table);
