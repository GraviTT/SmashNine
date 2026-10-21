// No packages: parse the unchanged soak's SOAK_RESULT JSON, never infer missing results.
const fs = require('fs');
const path = require('path');
const dir = __dirname;
function read(file) {
  const b = fs.readFileSync(file);
  return b[0] === 255 && b[1] === 254 ? b.toString('utf16le').replace(/^\uFEFF/, '') : b.toString('utf8');
}
const measurements = [];
for (const seed of [1001, 1002, 1003]) {
  const row = { seed };
  for (const stage of ['before', 'after']) {
    const content = read(path.join(dir, `${stage}-${seed}.log`));
    const line = content.split(/\r?\n/).find(x => x.startsWith('SOAK_RESULT '));
    if (!line) throw new Error(`Missing ${stage} seed ${seed} result`);
    const result = JSON.parse(line.slice('SOAK_RESULT '.length));
    const errors = content.split(/\r?\n/).filter(x => /^\s*(?:Godot[^:]* : )?(?:SCRIPT ERROR|ERROR|Parse Error):/.test(x) && !x.includes('ERROR: Failed to read the root certificate store.'));
    if (errors.length) throw new Error(`Unexpected ${stage} seed ${seed} errors: ${errors.join('\n')}`);
    if (!result.match_over || !result.winner || result.nan_positions) throw new Error(`Invalid match result for ${stage} seed ${seed}`);
    row[stage] = {
      monster_hits: result.monster_hits,
      defeats_by_monster: result.defeats_by_cause.monster || 0,
      match_seconds: result.seconds_simulated,
      pvp_hits: result.pvp_hits,
      ringouts: result.ringouts,
      winner: result.winner,
      match_over: result.match_over,
      nan_positions: result.nan_positions,
      unexpected_engine_errors: errors.length
    };
  }
  measurements.push(row);
}
const totals = {};
for (const stage of ['before', 'after']) {
  totals[stage] = {};
  for (const key of ['monster_hits', 'defeats_by_monster', 'pvp_hits', 'ringouts']) totals[stage][key] = measurements.reduce((n, x) => n + x[stage][key], 0);
  totals[stage].mean_match_seconds = +(measurements.reduce((n, x) => n + x[stage].match_seconds, 0) / 3).toFixed(1);
  totals[stage].median_match_seconds = measurements.map(x => x[stage].match_seconds).sort((a, b) => a - b)[1];
}
const data = {
  baseline_commit: '5dc0917',
  command: 'Godot_v4.7-stable_win64_console.exe --headless --path smash-nine-prototype --fixed-fps 60 -s tests/soak_match.gd -- --seconds=480 --seed=<1001|1002|1003> --players=8',
  measurements, totals,
  limitation: '3 seeds only. Full ecology change includes altered spawn positions and RNG consumption; outcomes cannot isolate one archetype or elite causal effect. Original soak does not split elite and regular hits or indirect monster-caused ringouts.'
};
fs.writeFileSync(path.join(dir, 'measurements.json'), JSON.stringify(data, null, 2) + '\n');
let md = '| 시드 | 몬스터 적중 전 → 후 | 몬스터 탈락 전 → 후 | 경기 길이(초) 전 → 후 |\n| --- | ---: | ---: | ---: |\n';
for (const x of measurements) md += `| ${x.seed} | ${x.before.monster_hits} → ${x.after.monster_hits} | ${x.before.defeats_by_monster} → ${x.after.defeats_by_monster} | ${x.before.match_seconds.toFixed(1)} → ${x.after.match_seconds.toFixed(1)} |\n`;
md += `| 합계 / 경기 길이 평균 | ${totals.before.monster_hits} → ${totals.after.monster_hits} | ${totals.before.defeats_by_monster} → ${totals.after.defeats_by_monster} | ${totals.before.mean_match_seconds} → ${totals.after.mean_match_seconds} |\n`;
md += '\n측정치이며 인과관계 추정이 아니다. 일반/정예 적중과 간접 링아웃은 기존 soak가 따로 분류하지 않는다.\n';
fs.writeFileSync(path.join(dir, 'soak-comparison.md'), md);
const reportPath = path.join(dir, 'README.md');
if (fs.existsSync(reportPath)) {
  const report = fs.readFileSync(reportPath, 'utf8');
  fs.writeFileSync(reportPath, report.replace(/<!-- SOAK_TABLE_START -->[\s\S]*?<!-- SOAK_TABLE_END -->/, `<!-- SOAK_TABLE_START -->\n${md}<!-- SOAK_TABLE_END -->`));
}
console.log(md);
