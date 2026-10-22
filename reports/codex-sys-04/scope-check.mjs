import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
const report = 'reports/codex-sys-04';
function git(...args) {
  const result = spawnSync('git', args, { encoding: 'utf8', windowsHide: true });
  if (result.status !== 0) throw new Error(result.stderr || result.stdout);
  return result.stdout.trim();
}
const changed = git('diff', '--name-only').split(/\r?\n/).filter(Boolean);
const allowed = /^(?:reports\/codex-sys-04\/|smash-nine-prototype\/(?:scripts\/(?:story\/|ui\/|Main\.gd$|RealmMonster\.gd$|monsters\/|Vfx\.gd$)|assets\/i18n\/strings\.csv$|tests\/(?:test_story_.*\.gd$|test_monster_options\.gd$|test_language\.gd$|run_all\.ps1$)))/;
const denied = changed.filter(name => !allowed.test(name));
if (denied.length) throw new Error('Out-of-card tracked changes: ' + denied.join(', '));
const newTests = ['test_monster_options', 'test_story_late_flow', 'test_story_rewards', 'test_story_exit_reload', 'test_story_text_fit', 'test_story_atomic_reload'].map(name => 'smash-nine-prototype/tests/' + name + '.gd');
for (const name of [...changed, ...newTests]) {
  if (fs.readFileSync(name).includes(13)) throw new Error('CR byte in source: ' + name);
}
git('diff', '--check');
if (git('diff', '--cached', '--name-only')) throw new Error('Unexpected staged changes.');
const manifest = JSON.parse(fs.readFileSync(report + '/validation-summary.json', 'utf8'));
const expected = [...changed, ...newTests].sort();
if (JSON.stringify(Object.keys(manifest.source_sha256).sort()) !== JSON.stringify(expected)) throw new Error('Validated source list differs from the task handoff.');
for (const [name, hash] of Object.entries(manifest.source_sha256)) {
  if (createHash('sha256').update(fs.readFileSync(name)).digest('hex') !== hash) throw new Error('Source changed since final validation: ' + name);
}
if (createHash('sha256').update(fs.readFileSync(report + '/all.log')).digest('hex') !== manifest.final_gate_log_sha256) throw new Error('Final gate log changed.');
const links = [...fs.readFileSync(report + '/README.md', 'utf8').matchAll(/\]\(([^)]+)\)/g)].map(match => match[1]);
for (const link of links) if (!link.includes('://') && !fs.existsSync(path.join(report, link))) throw new Error('Missing report link: ' + link);
const captures = fs.readdirSync(report).filter(name => /^\d{2}-.*\.png$/.test(name));
if (captures.length !== manifest.korean_captures) throw new Error('Capture count differs from validation summary.');
for (const name of captures) {
  const png = fs.readFileSync(report + '/' + name);
  if (png.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a' || png.readUInt32BE(16) !== 1280 || png.readUInt32BE(20) !== 720) throw new Error('Unexpected capture format or size: ' + name);
}
const output = [
  'Branch: ' + git('branch', '--show-current'),
  'Base: ' + git('rev-parse', 'HEAD'),
  'core.autocrlf: ' + git('config', '--get', 'core.autocrlf'),
  'PASS: tracked changes only in the task card writable paths.',
  'PASS: LF sources and git diff --check.',
  'PASS: index remains unstaged (the denied git add changed no index entries).',
  'PASS: no tracked change to characters, EnemyAI, realms, MatchDirector, spawners, art, story.csv, project.godot or design.',
  'PASS: final validation source hashes (' + expected.length + ') and full-gate log hash match the current files.',
  'PASS: README links (' + links.length + ') exist; all ' + captures.length + ' original captures are valid 1280x720 PNGs.',
  'Changed tracked files (' + changed.length + '):', ...changed,
  'New tests:', ...newTests,
  'Existing unrelated untracked files are neither deleted nor staged.'
].join('\n') + '\n';
fs.writeFileSync(report + '/scope-check.log', output, 'utf8');
console.log(output);
