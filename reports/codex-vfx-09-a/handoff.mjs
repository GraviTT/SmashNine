import {readFileSync,writeFileSync,readdirSync,statSync} from 'node:fs';
import {resolve,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {specs} from './specs.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)),report='reports/codex-vfx-09-a';
const walk=p=>readdirSync(resolve(repo,p),{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(p+'/'+e.name):[p+'/'+e.name]);
const owned=[];
for(const s of specs){const dir=`art/bakeoff/effects/pixelfx/${s.char}/a`;owned.push(`${dir}/${s.name}-a.png`,`${dir}/${s.name}-a.json`,`${dir}/src/sn-${s.name.replaceAll('_','-')}-a.js`);}
owned.push('art/bakeoff/effects/pixelfx/luna/a/bake-vfx09.mjs','art/bakeoff/effects/pixelfx/luna_brave/a/bake.mjs','art/bakeoff/effects/pixelfx/luna_brave/a/src/sharp09-a.js');
const license=readFileSync('C:/Users/TH/Documents/AI/GameProject/pixelfx/LICENSE','utf8');
writeFileSync(resolve(repo,report,'PIXELFX-LICENSE.txt'),license.trimEnd()+'\n','utf8');
const manifest=[...new Set([...owned,...walk(report),`${report}/manifest.json`,`${report}/delivery-check.json`,'design/tasks/CODEX-VFX-09.md'])].sort();
writeFileSync(resolve(repo,report,'manifest.json'),JSON.stringify(manifest,null,2)+'\n','utf8');
const textFiles=manifest.filter(p=>p.startsWith('art/')||p.startsWith(report)).filter(p=>/\.(mjs|js|json|md|ps1|txt|html)$/.test(p)&&!p.endsWith('/delivery-check.json'));
for(const path of textFiles){const buf=readFileSync(resolve(repo,path)),text=new TextDecoder('utf-8',{fatal:true}).decode(buf),clean=text.replace(/\r\n/g,'\n').split('\n').map(l=>l.trimEnd()).join('\n').trimEnd()+'\n';writeFileSync(resolve(repo,path),clean,'utf8');}
const ignored=spawnSync('git',['check-ignore','--',...manifest],{cwd:repo,encoding:'utf8'});
if(ignored.status!==0&&ignored.status!==1)throw new Error(ignored.stderr||'git check-ignore failed');
if(ignored.stdout.trim())throw new Error('Ignored delivery files: '+ignored.stdout);
const bytes=manifest.filter(p=>p!=='design/tasks/CODEX-VFX-09.md'&&!p.endsWith('/delivery-check.json')).reduce((sum,p)=>sum+statSync(resolve(repo,p)).size,0);
const reportJson={strips:specs.length,frames:specs.reduce((sum,s)=>sum+s.frames,0),manifestFiles:manifest.length,packageBytes:bytes,packageMiB:bytes/1024/1024,ignoredFiles:[],textEncoding:'UTF-8',lineEndings:'LF',textTrailingWhitespace:false,commitPerformed:false,gitRestriction:'Session .git is read-only. commit.ps1 is supplied for the lead.',qa:'All 108 saved frames personally inspected on real sprites at 4x.'};
writeFileSync(resolve(repo,report,'delivery-check.json'),JSON.stringify(reportJson,null,2)+'\n','utf8');
console.log(JSON.stringify(reportJson,null,2));
