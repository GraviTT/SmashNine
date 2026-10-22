import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
const dir=path.dirname(new URL(import.meta.url).pathname.replace(/^\/(?:([A-Za-z]:))/, '$1'));
const repo=path.resolve(dir,'../..');
const read=n=>JSON.parse(fs.readFileSync(path.join(dir,n),'utf8').replace(/^\uFEFF/,''));
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const walk=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(d,e.name)):[path.join(d,e.name)]);
const checks=[];
function check(ok,label) { checks.push({ok,label}); if(!ok) throw Error(label); }
const summary=read('sound-summary.json');
check(summary.length===6,'Six audio runs');
for(const s of summary) {
 const n=s.file.replace('.json','-events.json.gz');
 const d=JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(dir,n))));
 const counts={},world={watched:0,filtered:0,no_realm:0};
 for(const e of d.events) {
  counts[e.id]=(counts[e.id]??0)+1;
  if(e.outcome in world)world[e.outcome]++;
  if(e.outcome==='watched')check(e.source_realm===e.watched,`${n}: watched realm equality frame ${e.frame}`);
  if(e.outcome==='filtered')check(e.source_realm>=0 && e.source_realm!==e.watched,`${n}: filtered realm inequality frame ${e.frame}`);
  check(!e.played,`${n}: no actual audio play frame ${e.frame}`);
 }
 check(Object.entries(d.requests).every(([id,n])=>counts[id]===n),`${n}: request counts`);
 check(Object.entries(world).every(([id,n])=>n===d.world_probe[id]),`${n}: world probe`);
 check(world.no_realm===0,`${n}: no_realm 0`);
 check(s.seconds.reduce((n,r)=>n+r.watched,0)===world.watched,`${n}: second buckets sum`);
 check(d.actual_voice_peak_after_requests===0 && d.audio_manager_nodes===27,`${n}: actual voice peak and fixed nodes`);
 const b=s.busiest_five_seconds;
 check(d.events.filter(e=>e.outcome==='watched' && e.t>=b.start-1e-8 && e.t<b.end-1e-8).length===b.count,`${n}: busiest 5-second recount`);
}
for(const name of ['gate_geometry.gd','story_cutin.gd','gimmick_actors.gd','gate_soak.gd']) {
 const old=fs.readFileSync(path.join(repo,'smash-nine-prototype/tests/analysis/codex_qa_21',name),'utf8');
 const now=fs.readFileSync(path.join(repo,'smash-nine-prototype/tests/analysis/codex_qa_22',name),'utf8');
 check(old.replaceAll('reports/codex-qa-21/','reports/codex-qa-22/')===now,`${name}: only output path differs from QA21`);
}
check(read('gate-geometry.json').bad_slots===0,'Gate geometry fixed');
check(read('story-cutin.json').cast_seen && read('story-cutin.json').overlap_frames===0,'Cutin generated then cleared');
check(read('gimmick-actors.json').failed_expected_monster_use,'Monster participation mismatch persists');
const logs=walk(path.join(dir,'logs')).concat(fs.existsSync(path.join(dir,'suite'))?walk(path.join(dir,'suite')):[]).filter(p=>p.endsWith('.log'));
const logAudit=[];
for(const p of logs) {
 const lines=fs.readFileSync(p,'utf8').split(/\r?\n/),certificate=lines.filter(l=>l.trim()==='ERROR: Failed to read the root certificate store.').length;
 const errors=lines.filter(l=>/^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(l) && l.trim()!=='ERROR: Failed to read the root certificate store.');
 const warnings=lines.filter(l=>/^\s*WARNING:/.test(l));
 const audioWarnings=lines.filter(l=>/^\s*WARNING:.*(?:audio|sound|voice)|^\s*\[audio\].*warning/i.test(l));
 check(errors.length===0,`No non-certificate engine error: ${path.basename(p)}`);
 check(audioWarnings.length===0,`No audio warning: ${path.basename(p)}`);
 check(fs.statSync(p).size<=1000000,`Log <=1MB: ${path.basename(p)}`);
 logAudit.push({file:path.relative(dir,p).replaceAll('\\','/'),certificate,errors,warnings,audioWarnings,bytes:fs.statSync(p).size});
}
const git=(...args)=>execFileSync('git',args,{cwd:repo,encoding:'utf8'}).trim();
check(git('diff','--name-only')==='','No tracked worktree changes');
check(git('diff','--cached','--name-only')==='','No index changes');
check(git('branch','--show-current')==='codex/qa-22','Correct branch');
const suite=read('suite-meta.json');
check(suite.exit===0,'Full suite exit 0');
check(fs.readFileSync(path.join(dir,'suite-summary.log'),'utf8').includes('ALL PASSED'),'Full suite ALL PASSED');
const products=['smash-nine-prototype/project.godot','smash-nine-prototype/scripts/Main.gd','smash-nine-prototype/scripts/realms/RealmCatalog.gd','smash-nine-prototype/scripts/realms/RealmHazards.gd','smash-nine-prototype/scripts/ui/MatchHud.gd','smash-nine-prototype/scripts/audio/AudioManager.gd','smash-nine-prototype/characters/common/PlayerBase.gd'];
const artifacts=walk(dir).filter(p=>!['verification.json','run.log','analysis-output.txt'].includes(path.basename(p)));
const elapsedMinutes=(Date.now()-Date.parse('2026-10-22T19:15:36Z'))/60000;
check(elapsedMinutes<150,'Within 150-minute hard stop');
const verification={commit:git('rev-parse','HEAD'),branch:git('branch','--show-current'),started_utc:'2026-10-22T19:15:36Z',verified_utc:new Date().toISOString(),elapsed_minutes:elapsedMinutes,check_count:checks.length,failed:checks.filter(c=>!c.ok),summary:{audio_runs:6,no_realm:0,actual_audio_plays:0,actual_voice_peak:0,engine_errors:logAudit.reduce((n,l)=>n+l.errors.length,0),audio_warnings:logAudit.reduce((n,l)=>n+l.audioWarnings.length,0),certificate_noise:logAudit.reduce((n,l)=>n+l.certificate,0),logs:logAudit.length,suite_exit:suite.exit},logAudit,products:Object.fromEntries(products.map(p=>[p,hash(path.join(repo,p))])),artifacts:Object.fromEntries(artifacts.map(p=>[path.relative(dir,p).replaceAll('\\','/'),hash(p)]))};
fs.writeFileSync(path.join(dir,'verification.json'),JSON.stringify(verification,null,2)+'\n');
console.log(JSON.stringify({checks:checks.length,...verification.summary}));
