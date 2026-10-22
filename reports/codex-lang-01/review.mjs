// Read-only delivery checks plus a JSON record of the English/Korean soak comparison.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
const report = 'reports/codex-lang-01';
function read(file) {
  const bytes = fs.readFileSync(file);
  return (bytes[0] === 0xff && bytes[1] === 0xfe ? bytes.subarray(2).toString('utf16le') : bytes.toString('utf8')).replace(/^\uFEFF/, '');
}
const tests = read(path.join(report, 'tests.log'));
assert.match(tests, /^ALL PASSED$/m);
assert.equal((tests.match(/^PASS /gm) || []).length, 38);
const english = JSON.parse([...tests.matchAll(/SOAK_RESULT (\{[^\r\n]*\})/g)].at(-1)[1]);
const korean = JSON.parse([...read(path.join(report, 'ko-soak.log')).matchAll(/SOAK_RESULT (\{[^\r\n]*\})/g)].at(-1)[1]);
assert.deepEqual(korean, english, 'Locale changed the seeded match telemetry');
assert.equal(korean.match_over, true);
assert.equal(korean.nan_positions, 0);
fs.writeFileSync(path.join(report, 'locale-parity.json'), JSON.stringify({seed: 1001, players: 8, identical: true, english, korean}, null, 2) + '\n');
let rawLogs = 0;
function checkLogs(directory) {
  for (const item of fs.readdirSync(directory, {withFileTypes: true})) {
    const file = path.join(directory, item.name);
    if (item.isDirectory()) checkLogs(file);
    else if (item.name.endsWith('.log')) {
      rawLogs++;
      for (const line of read(file).split(/\r?\n/)) {
        if (/^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(line))
          assert.equal(line.trim(), 'ERROR: Failed to read the root certificate store.', `${file}: unrecognized engine error`);
      }
    }
  }
}
checkLogs(path.join(report, 'raw-logs'));
const diff = spawnSync('git', ['diff', '--name-only'], {encoding: 'utf8'});
assert.equal(diff.status, 0);
const changed = diff.stdout.trim().split(/\r?\n/).filter(Boolean);
const writable = new Set([
  'smash-nine-prototype/assets/i18n/strings.csv',
  'smash-nine-prototype/characters/common/PlayerBase.gd',
  'smash-nine-prototype/scripts/Main.gd',
  'smash-nine-prototype/scripts/RealmMonster.gd',
  'smash-nine-prototype/scripts/RealmMonsterSpawner.gd',
  'smash-nine-prototype/scripts/SoulCrystal.gd',
  'smash-nine-prototype/scripts/match/MatchDirector.gd',
  'smash-nine-prototype/scripts/realms/RealmHazards.gd',
  'smash-nine-prototype/scripts/ui/FrontendMenu.gd',
  'smash-nine-prototype/scripts/ui/MatchHud.gd',
  'smash-nine-prototype/tests/run_all.ps1'
]);
for (const file of changed) assert(writable.has(file), 'Tracked file outside LANG-01 scope: ' + file);
function baseline(file) {
  const result = spawnSync('git', ['show', 'HEAD:' + file], {encoding: 'utf8', maxBuffer: 4 * 1024 * 1024});
  assert.equal(result.status, 0);
  return result.stdout.replaceAll('\r\n', '\n');
}
function codeNumbers(source) {
  // Ignore strings and line comments before comparing non-UI numerical constants.
  return source.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|#[^\n]*/g, '').match(/\b\d+(?:\.\d+)?(?:e[+-]?\d+)?\b/gi) || [];
}
let numericalAudits = 0;
for (const file of changed.filter(file => file.endsWith('.gd') && !file.includes('/scripts/ui/'))) {
  assert.deepEqual(codeNumbers(read(file)), codeNumbers(baseline(file)), 'Changed a non-UI number: ' + file);
  numericalAudits++;
}
const hudFile = 'smash-nine-prototype/scripts/ui/MatchHud.gd';
function functionBody(source, name) {
  const start = source.indexOf('func ' + name + '(');
  assert(start >= 0);
  const end = source.indexOf('\nfunc ', start + 1);
  return source.slice(start, end < 0 ? undefined : end).trim();
}
for (const name of ['_build_hp_bar', '_build_card_panel'])
  assert.equal(functionBody(read(hudFile).replaceAll('\r\n', '\n'), name), functionBody(baseline(hudFile), name), 'Rewrote the protected HUD builder: ' + name);
assert.match(read(path.join(report, 'capture.log')), /Language tests passed/);
assert.match(read(path.join(report, 'saved-choice.log')), /SAVED CHOICE ALL PASSED/);
console.log(`Delivery review passed: 37 scripts + 1 English soak; Korean soak identical; ${rawLogs} raw logs have only the documented certificate diagnostic; ${changed.length} tracked source changes are in scope; ${numericalAudits} non-UI files retain every numerical literal; HP/card panel builders are unchanged.`);
