// No dependencies. Use a temporary self-contained copy only for the editor import:
// the sandbox cannot write Godot's normal AppData editor settings.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
const root = process.cwd();
const report = path.join(root, 'reports/codex-sys-03');
const original = process.env.GODOT_BIN || 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe';
const mode = process.argv[2] || 'import';
let executable = original;
let args;
if (mode === 'import') {
  const temporary = path.join(process.env.TEMP, 'smashnine-sys03-godot');
  fs.mkdirSync(temporary, { recursive: true });
  for (const name of ['Godot_v4.7-stable_win64.exe', 'Godot_v4.7-stable_win64_console.exe']) {
    const target = path.join(temporary, name);
    if (!fs.existsSync(target)) fs.copyFileSync(path.join(path.dirname(original), name), target);
  }
  fs.writeFileSync(path.join(temporary, '_sc_'), '');
  executable = path.join(temporary, path.basename(original));
  args = ['--headless', '--path', 'smash-nine-prototype', '--import'];
} else if (mode === 'capture') {
  args = ['--path', 'smash-nine-prototype', '-s', 'tests/test_story_flow.gd', '--', '--capture'];
} else {
  args = ['--headless', '--path', 'smash-nine-prototype', '-s', 'tests/' + mode + '.gd'];
}
const result = spawnSync(executable, args, { cwd: root, encoding: 'utf8', windowsHide: true, timeout: 300000, maxBuffer: 20 * 1024 * 1024 });
const output = (result.stdout || '') + '\n' + (result.stderr || '');
fs.writeFileSync(path.join(report, mode + '-verified.log'), output, 'utf8');
const errors = output.split(/\r?\n/).filter(line => /^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(line) && line.trim() !== 'ERROR: Failed to read the root certificate store.');
if (result.error || result.status !== 0 || errors.length) {
  console.error(result.error || errors.join('\n') || 'Godot exit ' + result.status);
  console.error(output.slice(-10000));
  process.exit(1);
}
const certificateCount = output.split('ERROR: Failed to read the root certificate store.').length - 1;
console.log(output.split(/\r?\n/).filter(line => /tests passed/.test(line)).join('\n'));
console.log('PASS ' + mode + ' (known sandbox certificate-store noise: ' + certificateCount + '; all other errors are fatal)');
