const fs = require('fs');
const path = require('path');
const util = require('util');
const dir = __dirname;
const rows = [];
for (const seed of [1001, 1002, 1003]) {
  const sample = JSON.parse(fs.readFileSync(path.join(dir, `probe-${seed}-p16.json`), 'utf8'));
  const bytes = fs.readFileSync(path.join(dir, `probe-${seed}-p16.log`));
  const log = bytes[0] === 255 && bytes[1] === 254 ? bytes.toString('utf16le').replace(/^\uFEFF/, '') : bytes.toString('utf8');
  const emitted = log.split(/\r?\n/).find(line => line.startsWith('ECOLOGY_PROBE '));
  if (!emitted || !util.isDeepStrictEqual(sample, JSON.parse(emitted.slice(14)))) throw new Error(`16-player probe log/file mismatch: ${seed}`);
  const errors = log.split(/\r?\n/).filter(line => /^\s*(?:Godot[^:]* : )?(?:SCRIPT ERROR|ERROR|Parse Error):/.test(line) && !line.includes('ERROR: Failed to read the root certificate store.'));
  if (!sample.match_over || sample.players !== 16 || sample.violations.length || errors.length) throw new Error(`16-player probe failed: ${seed}`);
  rows.push({ seed, seconds: sample.seconds, regular_hits: sample.monster_hits.regular, elite_hits: sample.monster_hits.elite, regular_eliminations: sample.monster_eliminations.regular, elite_eliminations: sample.monster_eliminations.elite, peak_living_monsters: sample.peak_living_monsters, peak_monster_projectiles: sample.peak_projectiles, violations: 0, unexpected_engine_errors: 0 });
}
fs.writeFileSync(path.join(dir, 'stress-summary.json'), JSON.stringify({ players: 16, rows, note: 'Additional integration checks, not a frame-time or gameplay-balance benchmark.' }, null, 2) + '\n');
let table = '| 시드 | 종료(초) | 일반/정예 적중 | 일반/정예 탈락 | 관측 위반 |\n| --- | ---: | ---: | ---: | ---: |\n';
for (const r of rows) table += `| ${r.seed} | ${r.seconds.toFixed(1)} | ${r.regular_hits} / ${r.elite_hits} | ${r.regular_eliminations} / ${r.elite_eliminations} | ${r.violations} |\n`;
table += '\n16명으로 외곽 전체에서 교전하는 추가 실행 검사다. 세 판 모두 종료했고 인증서 소음 외 엔진 오류는 없었다. 프레임 시간이나 사람 플레이 밸런스를 측정한 결과는 아니다.\n';
fs.writeFileSync(path.join(dir, 'stress-summary.md'), table);
const reportPath = path.join(dir, 'README.md');
let report = fs.readFileSync(reportPath, 'utf8');
if (!report.includes('<!-- STRESS_TABLE_START -->')) report = report.replace('## 확인 및 테스트', '### 추가 16명 실행 검사\n\n<!-- STRESS_TABLE_START -->\n<!-- STRESS_TABLE_END -->\n\n## 확인 및 테스트');
report = report.replace(/<!-- STRESS_TABLE_START -->[\s\S]*?<!-- STRESS_TABLE_END -->/, `<!-- STRESS_TABLE_START -->\n${table}<!-- STRESS_TABLE_END -->`);
fs.writeFileSync(reportPath, report);
console.log(table);
