import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(dir, '../..');
const scripts = path.join(repo, 'smash-nine-prototype/tests/analysis/codex_qa_21');
const ignored = f => /(^|\/)web\//.test(f) || /(^|\/)(run\.log|story-save-test\.cfg|verification\.json)$/.test(f);
function walk(folder) {
  return fs.readdirSync(folder, {withFileTypes:true}).flatMap(e => {
    const full = path.join(folder,e.name);
    if (e.isDirectory()) return e.name === 'web' || e.name === '__pycache__' ? [] : walk(full);
    return e.isFile() ? [full] : [];
  });
}
const relative = f => path.relative(repo,f).replaceAll('\\','/');
const files = [...walk(dir), ...walk(scripts)].filter(f=>!ignored(relative(f))).sort();
for (const f of files) {
  const b = fs.readFileSync(f);
  let text = b[0] === 0xff && b[1] === 0xfe ? b.subarray(2).toString('utf16le') : b.toString('utf8').replace(/^\uFEFF/, '');
  text = text.replace(/\r\n/g,'\n');
  if (!b.equals(Buffer.from(text,'utf8'))) fs.writeFileSync(f,text,'utf8');
  if (f.endsWith('.json')) JSON.parse(text);
}
const engineErrors = [];
let certificates = 0;
for (const f of files.filter(f=>f.endsWith('.log'))) for (const line of fs.readFileSync(f,'utf8').split('\n')) {
  if (line.trim() === 'ERROR: Failed to read the root certificate store.') certificates++;
  else if (/^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(line)) engineErrors.push({file:relative(f),line});
}
const diff = execFileSync('git',['diff','--name-only'],{cwd:repo,encoding:'utf8'}).trim();
if (diff) throw Error('Unexpected tracked changes: '+diff);
if (engineErrors.length) throw Error('Unexpected engine errors: '+JSON.stringify(engineErrors));
const hash = f => createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const summary = fs.readFileSync(path.join(dir,'suite-summary.log'),'utf8');
const json = name=>JSON.parse(fs.readFileSync(path.join(dir,name),'utf8'));
const sourcePaths = ['smash-nine-prototype/export_presets.cfg','smash-nine-prototype/project.godot','smash-nine-prototype/scripts/realms/RealmCatalog.gd','smash-nine-prototype/scripts/realms/RealmHazards.gd','smash-nine-prototype/scripts/RealmMonsterSpawner.gd','smash-nine-prototype/scripts/ui/MatchHud.gd','smash-nine-prototype/scripts/story/StorySession.gd','smash-nine-prototype/scripts/Main.gd'];
const result = {
  finalized_at:new Date().toISOString(), base_commit:execFileSync('git',['rev-parse','HEAD'],{cwd:repo,encoding:'utf8'}).trim(),
  tracked_diff_empty:true, product_changes:[], log_encoding:'UTF-8; CRLF normalized to LF without changing message content',
  unexpected_engine_error_lines:engineErrors, known_certificate_lines_in_final_logs:certificates,
  original_suite:{passed_scripts:(summary.match(/^PASS test_|^PASS visual_preview/gm)||[]).length,all_passed:summary.includes('ALL PASSED'),elapsed_wall_seconds:950.59},
  controlled_journeys:json('continuous-journeys.json').journeys.length,
  menu_cycles:json('menu-cycles.json').cycles.length,
  monster_conditions:json('monster-matrix.json').rows.length,
  dialogue:json('dialogue-keys.json'),text_slots:json('text-slots.json'),
  findings_expected_exit_1:['gate_geometry.gd','gimmick_actors.gd','story_cutin.gd'],
  source_sha256:Object.fromEntries(sourcePaths.map(f=>[f,hash(path.join(repo,f))])),
  artifacts:files.map(f=>({path:relative(f),bytes:fs.statSync(f).size,sha256:hash(f)}))
};
fs.writeFileSync(path.join(dir,'verification.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({base_commit:result.base_commit,suite:result.original_suite,files:result.artifacts.length,engineErrors:engineErrors.length,knownCertificates:certificates,tracked_diff_empty:true},null,2));
