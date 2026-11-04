import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { resolve, relative, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { specs } from './setup.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)),report='reports/codex-vfx-08-a';
const files=[];
for(const s of specs) {
  const dir=`art/bakeoff/effects/pixelfx/${s.char}/a`;
  files.push(`${dir}/${s.name}-a.png`,`${dir}/${s.name}-a.json`,`${dir}/src/sn-${s.name.replaceAll('_','-')}-a.js`);
}
for(const char of ['frey','luna'])files.push(`art/bakeoff/effects/pixelfx/${char}/a/src/sharp-a.js`,`art/bakeoff/effects/pixelfx/${char}/a/bake.mjs`);
function list(dir){for(const e of readdirSync(resolve(repo,dir),{withFileTypes:true})){const p=`${dir}/${e.name}`;if(e.isDirectory())list(p);else files.push(p);}}
list(report);
files.push(`${report}/handoff-files.json`,`${report}/handoff-check.json`,'design/tasks/CODEX-VFX-08.md');
const unique=[...new Set(files)].sort();
writeFileSync(resolve(repo,`${report}/handoff-files.json`),JSON.stringify(unique,null,2)+'\n','utf8');
const errors=[],textFiles=[];let bytes=0,pngBytes=0;
for(const p of unique) {
  if(p.endsWith('handoff-check.json'))continue;
  if(p==='design/tasks/CODEX-VFX-08.md')continue; // Card is owned by the lead; never normalise it.
  const b=readFileSync(resolve(repo,p));bytes+=b.length;
  if(p.startsWith('art/')&&p.endsWith('.png'))pngBytes+=b.length;
  if(['.md','.mjs','.js','.json','.ps1','.html'].includes(extname(p))) {
    const t=new TextDecoder('utf-8',{fatal:true}).decode(b);textFiles.push(p);
    if(/[\t ]+$/m.test(t)||/\n\s*\n$/.test(t)||!t.endsWith('\n')||t.includes('\r'))errors.push(`text format: ${p}`);
    if(/\.(mjs|js)$/.test(p)) {
      const r=spawnSync(process.execPath,['--check',resolve(repo,p)],{encoding:'utf8'});
      if(r.status!==0)errors.push(`JS syntax: ${p}: ${r.stderr}`);
    }
  }
}
const decoded=specs.reduce((n,s)=>n+s.w*s.h*s.frames*4,0);
const result={files:unique.length,utf8TextFiles:textFiles.length,bytes,pngBytes,decodedRGBABytes:decoded,errors,scope:'Only VFX-08 A assets, its report, and the unchanged task card. No force-add.'};
writeFileSync(resolve(repo,`${report}/handoff-check.json`),JSON.stringify(result,null,2)+'\n','utf8');
console.log(JSON.stringify(result,null,2));
if(errors.length)process.exitCode=1;
