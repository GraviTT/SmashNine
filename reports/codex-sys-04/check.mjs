// Existing local Godot only. A self-contained copy keeps editor settings in writable TEMP.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
const report = path.resolve('reports/codex-sys-04');
const original = process.env.GODOT_BIN || 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe';
const mode = process.argv[2] || 'import';
let executable = original;
let args;
if (mode === 'import') {
  const temporary = path.join(process.env.TEMP, 'smashnine-sys04-godot');
  fs.mkdirSync(temporary, { recursive: true });
  for (const name of ['Godot_v4.7-stable_win64.exe', 'Godot_v4.7-stable_win64_console.exe']) {
    const target = path.join(temporary, name);
    if (!fs.existsSync(target)) fs.copyFileSync(path.join(path.dirname(original), name), target);
  }
  fs.writeFileSync(path.join(temporary, '_sc_'), '');
  executable = path.join(temporary, path.basename(original));
  args = ['--headless', '--path', 'smash-nine-prototype', '--import'];
} else if (mode === 'route') {
  args = ['--headless', '--fixed-fps', '60', '--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/escape-route-probe.gd', '--', '--hero=' + (process.argv[3] || 'frey')];
} else if (mode === 'matrix') {
  args = ['--headless', '--path', 'smash-nine-prototype', '-s', 'tests/test_story_late_flow.gd', '--', '--heroes=all'];
} else if (mode === 'combat') {
  args = ['--headless', '--fixed-fps', '60', '--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/combat-probe.gd'];
} else if (mode === 'combat_stalls') {
  args = ['--headless', '--fixed-fps', '60', '--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/combat-probe.gd', '--', '--stage8-stalls'];
} else if (mode === 'journey') {
  args = ['--headless', '--fixed-fps', '60', '--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/continuous-journey-probe.gd'];
} else if (mode === 'journey_reload') {
  args = ['--headless', '--fixed-fps', '60', '--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/continuous-journey-probe.gd', '--', '--reload'];
} else if (mode === 'capture') {
  args = ['--path', 'smash-nine-prototype', '-s', 'tests/test_story_late_flow.gd', '--', '--capture'];
} else if (mode === 'overview') {
  args = ['--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/capture-escape-overview.gd'];
} else if (mode === 'scene_warning') {
  args = ['--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/capture-scene-warning.gd'];
} else if (mode === 'completion') {
  args = ['--path', 'smash-nine-prototype', '-s', '../reports/codex-sys-04/capture-completion.gd'];
} else if (mode === 'all') {
  executable = 'powershell.exe';
  args = ['-ExecutionPolicy', 'Bypass', '-File', 'smash-nine-prototype/tests/run_all.ps1'];
} else {
  args = ['--headless', '--path', 'smash-nine-prototype', '-s', 'tests/' + mode + '.gd'];
}
const result = spawnSync(executable, args, { cwd: process.cwd(), encoding: 'utf8', windowsHide: mode !== 'capture', timeout: 900000, maxBuffer: 30 * 1024 * 1024,
  env: { ...process.env, GODOT_TEST_LOG_DIR: path.join(report, 'raw-logs') } });
const output = (result.stdout || '') + '\n' + (result.stderr || '');
fs.writeFileSync(path.join(report, mode + (mode === 'route' ? '-' + (process.argv[3] || 'frey') : '') + '.log'), output, 'utf8');
const errors = output.split(/\r?\n/).filter(line => /^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(line) && line.trim() !== 'ERROR: Failed to read the root certificate store.');
if (result.error || result.status !== 0 || errors.length) {
  console.error(result.error || errors.join('\n') || 'Godot exit ' + result.status);
  console.error(output.slice(-12000));
  process.exit(1);
}
console.log(output.split(/\r?\n/).filter(line => /tests passed|^PASS|ALL PASSED|SOAK_RESULT|ESCAPE_ROUTE_RESULT/.test(line)).join('\n'));
console.log('PASS ' + mode + ' (certificate-store noise: ' + (output.split('ERROR: Failed to read the root certificate store.').length - 1) + '; other errors fatal)');
