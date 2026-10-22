import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url)), repo = path.resolve(dir,'../..');
const git = args => execFileSync('git',args,{cwd:repo,encoding:'utf8'}).trim();
const read = rel => fs.readFileSync(path.join(repo,rel),'utf8').replaceAll('\r\n','\n');
const before = rel => execFileSync('git',['show','HEAD:'+rel],{cwd:repo,encoding:'utf8'}).replaceAll('\r\n','\n');
const insist = (condition,message) => { if(!condition) throw Error(message); };
const files = fs.readFileSync(path.join(dir,'files.txt'),'utf8').trim().split('\n');
const single = new Set(['design/AUDIO.md','smash-nine-prototype/scripts/realms/RealmHazards.gd','smash-nine-prototype/scripts/story/StorySession.gd','smash-nine-prototype/scripts/ui/StoryDialogue.gd','smash-nine-prototype/scripts/ui/StoryScreens.gd','smash-nine-prototype/tests/test_audio.gd','smash-nine-prototype/tests/test_realm_gimmicks.gd']);
const allowed = p => single.has(p) || /^(smash-nine-prototype\/scripts\/audio\/|smash-nine-prototype\/tests\/analysis\/codex_sys_08\/|reports\/codex-sys-08\/)/.test(p);
const changed = git(['diff','--name-only']).split('\n').filter(Boolean);
insist(git(['branch','--show-current'])==='codex/sys-08','Wrong branch');
insist(changed.length===9 && changed.every(allowed),'Unexpected tracked edits');
for(const p of files) {
  insist(allowed(p) && !p.split('/').includes('..') && !path.isAbsolute(p) && !/__pycache__|\.pyc$/.test(p),'Forbidden manifest entry: '+p);
  if(p==='reports/codex-sys-08/verification.json' && !fs.existsSync(path.join(repo,p))) continue;
  const stat=fs.lstatSync(path.join(repo,p));
  insist(stat.isFile() && !stat.isSymbolicLink(),'Expected ordinary file: '+p);
  insist(!p.endsWith('.log') || stat.size<=1048576,'Log exceeds 1 MB: '+p);
}
insist(!files.some(p=>/\.(ogg|wav|mp3)$/i.test(p)),'Audio asset in manifest');
const storyChecks=[];
for(const [p,hooks] of [
  ['smash-nine-prototype/scripts/story/StorySession.gd',['\tpreload("res://scripts/audio/AudioManager.gd").sound(hero, "portal")']],
  ['smash-nine-prototype/scripts/ui/StoryDialogue.gd',['\tAUDIO.sound(self, "story_text")','\tAUDIO.story_advance(self, action)']],
  ['smash-nine-prototype/scripts/ui/StoryScreens.gd',['\tAUDIO.story_result(self, bool(result.clear))','\tAUDIO.story_ending(self)']]]) {
  const final=read(p), stripped=final.split('\n').filter(line=>!hooks.includes(line)).join('\n');
  insist(stripped===before(p),'Non-hook story changes: '+p);
  insist(hooks.every(h=>final.split('\n').filter(l=>l===h).length===1),'Duplicate/missing story hook');
  storyChecks.push({path:p,added_sound_hook_lines:hooks.length,other_changes:0});
}
const gatePath='smash-nine-prototype/scripts/realms/RealmHazards.gd';
insist(read(gatePath).replace('GATE_COOLDOWN := 2.5','GATE_COOLDOWN := 1.0').replace('(2.5 s per-fighter cooldown)','(1 s per-fighter cooldown)')===before(gatePath),'Gate changes beyond cooldown');
const catalogPath='smash-nine-prototype/scripts/audio/AudioCatalog.gd';
insist(read(catalogPath).replace(/^## SYS-08:.*\n/m,'').replace(/"gap_ms": \d+, /g,'')===before(catalogPath),'Catalog changed beyond gaps');
insist(!read('design/AUDIO.md').includes('needs a story-session hook'),'Stale story contract');
const logs=[];
const finalNames=new Set(['import.log','gate-after.log','gate-valid-2105.log','gate-valid-2106.log','audio-focused.log','audio-all-fixed.log','rate-replay.log','sound-br-1001.log','sound-br-2105.log','sound-br-2106.log','sound-story-1.log','sound-story-5.log','sound-story-9.log']);
for(const rel of files.filter(p=>p.startsWith('reports/codex-sys-08/suite/') || finalNames.has(p.split('/').at(-1)))) {
  const bytes=fs.readFileSync(path.join(repo,rel));
  const text=bytes[0]===255&&bytes[1]===254?bytes.toString('utf16le'):bytes.toString('utf8');
  const lines=text.replace(/^\uFEFF/,'').split(/\r?\n/), cert=lines.filter(l=>l.trim()==='ERROR: Failed to read the root certificate store.').length;
  const errors=lines.filter(l=>/^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(l)&&l.trim()!=='ERROR: Failed to read the root certificate store.');
  insist(errors.length===0,'Unexpected final engine errors: '+rel);
  logs.push({path:rel,certificate_noise:cert,other_engine_errors:errors.length});
}
const suite=JSON.parse(fs.readFileSync(path.join(dir,'suite-meta.json'),'utf8'));
const summary=fs.readFileSync(path.join(dir,'suite-summary.log'),'utf16le').replace(/^\uFEFF/,'');
insist(suite.exit===0 && suite.full_suite_invocations===1 && /ALL PASSED/.test(summary),'Full suite failed');
const regressions=JSON.parse(fs.readFileSync(path.join(dir,'regression-checks.json'),'utf8'));
insist(regressions.length===3 && regressions.every(r=>r.exit!==0&&r.expected_nonzero),'Missing negative controls');
const sourceHashes=Object.fromEntries(changed.map(p=>[p,crypto.createHash('sha256').update(fs.readFileSync(path.join(repo,p))).digest('hex')]));
const result={head:git(['rev-parse','HEAD']),branch:git(['branch','--show-current']),tracked_changed:changed,manifest_files:files.length,story_checks:storyChecks,gate_only_cooldown:true,catalog_only_gaps:true,no_audio_assets_added:true,source_hashes:sourceHashes,suite,final_logs:logs,certificate_noise:logs.reduce((n,r)=>n+r.certificate_noise,0),other_final_engine_errors:0,negative_controls:regressions,excluded_initial_logs:['logs/audio-all.log (initial timing fixture failure)','logs/gate-soak-2105.log and gate-soak-2106.log (seed=-1, excluded)'],note:'Verification reads git only. commit.ps1 is prepared and has not been run.'};
fs.writeFileSync(path.join(dir,'verification.json'),JSON.stringify(result,null,2)+'\n');
console.log(`SYS08 verified: ${files.length} files; 5 story hook lines only; ${logs.length} final Godot logs; ${result.certificate_noise} known certificate lines; 0 other final engine errors.`);
