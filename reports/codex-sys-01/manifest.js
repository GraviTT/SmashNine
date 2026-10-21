const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const dir = __dirname;
const root = path.resolve(dir, '../..');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
if (process.argv.includes('--verify')) {
  const saved = JSON.parse(fs.readFileSync(path.join(dir, 'validation-manifest.json'), 'utf8'));
  let checked = 0;
  for (const record of saved.code) {
    if (hash(path.join(root, record.path)) !== record.sha256) throw new Error(`Changed code: ${record.path}`);
    checked++;
  }
  for (const record of [...saved.evidence, ...saved.screenshots]) {
    if (hash(path.join(dir, record.path)) !== record.sha256) throw new Error(`Changed evidence: ${record.path}`);
    checked++;
  }
  console.log(`Final saved evidence matches manifest: ${checked} files.`);
  process.exit(0);
}
const read = file => {
  const b = fs.readFileSync(file);
  return b[0] === 255 && b[1] === 254 ? b.toString('utf16le').replace(/^\uFEFF/, '') : b.toString('utf8');
};
const suite = read(path.join(dir, 'run-all-final.log'));
if (!/^ALL PASSED\s*$/m.test(suite) || /^FAIL /m.test(suite)) throw new Error('Final suite is incomplete or failed.');
const ecology = read(path.join(dir, 'ecology.log'));
const newChecks = /Monster ecology tests passed \((\d+) checks/.exec(ecology);
if (!newChecks) throw new Error('Missing final ecology test result.');
const code = [
  'smash-nine-prototype/scripts/Main.gd',
  'smash-nine-prototype/scripts/RealmMonster.gd',
  'smash-nine-prototype/scripts/RealmMonsterSpawner.gd',
  'smash-nine-prototype/scripts/monsters/MonsterArchetypes.gd',
  'smash-nine-prototype/scripts/monsters/MonsterAttack.gd',
  'smash-nine-prototype/scripts/monsters/MonsterProjectile.gd',
  'smash-nine-prototype/tests/test_monster_ecology.gd',
  'smash-nine-prototype/tests/run_all.ps1'
].map(file => ({ path: file, sha256: hash(path.join(root, file)) }));
const evidence = ['before-1001.log', 'before-1002.log', 'before-1003.log', 'after-1001.log', 'after-1002.log', 'after-1003.log', 'run-all-final.log', 'ecology.log', 'measurements.json', 'integration-summary.json', 'stress-summary.json', 'probe-1001-p8.json', 'probe-1002-p8.json', 'probe-1003-p8.json', 'probe-1001-p16.json', 'probe-1002-p16.json', 'probe-1003-p16.json'];
const records = evidence.map(file => ({ path: file, sha256: hash(path.join(dir, file)), modified_utc: fs.statSync(path.join(dir, file)).mtime.toISOString() }));
const engineName = 'Godot_v4.7-stable_win64.exe';
const originalEngine = `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/${engineName}`;
const portableEngine = path.join(process.env.TEMP, 'SmashNine-sys01-godot', engineName);
const originalHash = hash(originalEngine);
const portableHash = hash(portableEngine);
if (originalHash !== portableHash) throw new Error('Portable engine differs from the supplied original binary.');
const screenshots = ['ecology-runtime.png', 'readability-runtime.png', 'jotunheim-runtime.png'].map(file => {
  const bytes = fs.readFileSync(path.join(dir, file));
  return { path: file, width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20), sha256: hash(path.join(dir, file)) };
});
const result = {
  captured_utc: new Date().toISOString(), baseline_commit: '5dc0917',
  supplied_engine_sha256: originalHash, portable_copy_matches: true,
  final_suite: 'ALL PASSED', passed_test_scripts: (suite.match(/^PASS (?!soak)/gm) || []).length,
  final_ecology_checks: Number(newChecks[1]),
  code, evidence: records, screenshots,
  verification_note: 'Only the exact user-authorized certificate-store sandbox error is filtered by verify.ps1; product runner error detection is unchanged.'
};
fs.writeFileSync(path.join(dir, 'validation-manifest.json'), JSON.stringify(result, null, 2) + '\n');
console.log(`Validation manifest written: ${result.passed_test_scripts} test scripts, ${result.final_ecology_checks} ecology checks, identical Godot binary copy.`);
