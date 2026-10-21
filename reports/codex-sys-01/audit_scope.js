const fs = require('fs');
const path = require('path');
const cp = require('child_process');
const root = path.resolve(__dirname, '../..');
const git = 'C:/Program Files/Git/mingw64/bin/git.exe';
function run(args) {
  const result = cp.spawnSync(git, args, { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) throw new Error(result.stderr || `git ${args.join(' ')} failed`);
  return result.stdout;
}
const exact = [
  'smash-nine-prototype/scripts/RealmMonster.gd',
  'smash-nine-prototype/scripts/RealmMonsterSpawner.gd',
  'smash-nine-prototype/scripts/Main.gd',
  'smash-nine-prototype/tests/test_monster_ecology.gd',
  'smash-nine-prototype/tests/run_all.ps1'
];
const allowed = p => exact.includes(p) || p.startsWith('smash-nine-prototype/scripts/monsters/') || p.startsWith('reports/codex-sys-01/');
const trackedChanges = run(['diff', '--name-only']).trim().split(/\r?\n/).filter(Boolean);
for (const file of trackedChanges) if (!allowed(file)) throw new Error(`Tracked change outside card: ${file}`);
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const mainPath = 'smash-nine-prototype/scripts/Main.gd';
const oldMain = run(['show', `HEAD:${mainPath}`]);
const oldWire = '\trealm_monster_spawner.configure(Callable(layout, "get_spawn_points"), Callable(director, "get_playable_indices"))';
const newWire = '\trealm_monster_spawner.configure(Callable(layout, "get_spawn_points"), Callable(director, "get_playable_indices"), Callable(director, "get_phase_name"), match_seed)\n\trealm_monster_spawner.announcement.connect(_show_message)';
if (read(mainPath) !== oldMain.replace(oldWire, newWire)) throw new Error('Main changed beyond the two permitted wiring lines.');
const runnerPath = 'smash-nine-prototype/tests/run_all.ps1';
const oldRunner = run(['show', `HEAD:${runnerPath}`]);
const expectedRunner = oldRunner.replace('"test_realm_monsters", "test_moves_sheet"', '"test_realm_monsters", "test_monster_ecology", "test_moves_sheet"');
if (read(runnerPath) !== expectedRunner) throw new Error('run_all changed beyond its one added test entry.');
const protectedPaths = [
  'smash-nine-prototype/scripts/EnemyAI.gd',
  'smash-nine-prototype/characters',
  'smash-nine-prototype/scripts/realms/RealmHazards.gd',
  'smash-nine-prototype/scripts/ui',
  'smash-nine-prototype/scripts/realms/RealmCatalog.gd'
];
if (run(['diff', '--name-only', '--', ...protectedPaths]).trim()) throw new Error('A protected path changed.');
run(['diff', '--check']);
const files = [...exact, ...fs.readdirSync(path.join(root, 'smash-nine-prototype/scripts/monsters')).filter(x => x.endsWith('.gd')).map(x => `smash-nine-prototype/scripts/monsters/${x}`)];
for (const file of files) if (read(file).includes('\r')) throw new Error(`Expected LF line endings in ${file}`);
const result = {
  tracked_changes: trackedChanges,
  main_only_permitted_function_wiring: true,
  run_all_only_one_entry: true,
  protected_paths_unchanged: protectedPaths,
  whitespace_check: 'passed',
  line_endings: 'LF',
  note: 'Pre-existing untracked files outside this card were left untouched and are not staged by commit.ps1.'
};
fs.writeFileSync(path.join(__dirname, 'scope-audit.json'), JSON.stringify(result, null, 2) + '\n');
console.log('Scope audit passed: Main wiring only, runner one entry, protected paths unchanged, LF and diff --check clean.');
