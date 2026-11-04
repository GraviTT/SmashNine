import {readFileSync,writeFileSync,statSync} from "node:fs";
import {spawnSync} from "node:child_process";
import {Script} from "node:vm";
import {bench} from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
import {specs,rootFor,repo,digest,moduleFor} from "./bake-lib.mjs";
const OUT=new URL("./",import.meta.url),files=JSON.parse(readFileSync(new URL("manifest.json",OUT),"utf8"));
const errors=[],decoder=new TextDecoder("utf-8",{fatal:true});let bytes=0,textFiles=0;
for(const path of files) {
  if(!/^art\/bakeoff\/effects\/pixelfx\/(frey|luna)\/b\//.test(path)&&!path.startsWith("reports/codex-vfx-08-b/"))errors.push(`outside allowed paths: ${path}`);
  if(path.endsWith("handoff-check.json"))continue;
  const url=new URL(path,repo),buf=readFileSync(url);bytes+=buf.length;
  if(/\.(mjs|js|json|md|ps1|html)$/.test(path)) {
    textFiles++;let s;try{s=decoder.decode(buf);}catch{errors.push(`UTF-8: ${path}`);continue;}
    if(/[ \t]+$/m.test(s))errors.push(`trailing spaces: ${path}`);
    if(/\n\s*\n$/.test(s))errors.push(`blank EOF: ${path}`);
    if(s.includes("\r"))errors.push(`CRLF: ${path}`);
    if(/\.(mjs|js)$/.test(path)) {const p=spawnSync(process.execPath,["--check",url.pathname.replace(/^\//,"")],{encoding:"utf8"});if(p.status!==0)errors.push(`syntax: ${path} ${p.stderr}`);}
    if(path.endsWith("preview.html")){try{new Script(s.match(/<script>([\s\S]*?)<\/script>/)[1]);}catch(e){errors.push(`preview JS syntax: ${e.message}`);}}
  }
}
const measurements=JSON.parse(readFileSync(new URL("measurements.json",OUT),"utf8")).measurements;
for(const s of specs) {
  const png=readFileSync(new URL(`${s.id}-b.png`,rootFor(s))),meta=JSON.parse(readFileSync(new URL(`${s.id}-b.json`,rootFor(s)),"utf8")),m=measurements.find(m=>m.id===s.id),mod=await import(moduleFor(s)),im=bench.readPNG(new URL(`${s.id}-b.png`,rootFor(s)));
  if(digest(png)!==m.sha256)errors.push(`stale measurements: ${s.id}`);
  if(im.w!==meta.frames*s.size[0]||im.h!==s.size[1]||JSON.stringify(meta.anchor)!==JSON.stringify(mod.meta.origin))errors.push(`metadata: ${s.id}`);
  if(s.blend==="add")for(let i=0;i<im.data.length;i+=4)if(im.data[i+3]&&Math.max(im.data[i],im.data[i+1],im.data[i+2])<40){errors.push(`dim additive pixel: ${s.id}`);break;}
  if(m.errors.length)errors.push(...m.errors.map(e=>s.id+": "+e));
}
const overlap=JSON.parse(readFileSync(new URL("spawn-overlap.json",OUT),"utf8")).overlap;
if(overlap.some(m=>m.max_head_pixels||m.max_core_pixels))errors.push("caster overlap");
const result={status:errors.length?"FAIL":"PASS",files:files.length,text_files:textFiles,bytes,MiB:+(bytes/1048576).toFixed(2),candidate_strips:specs.length,frames:measurements.reduce((n,m)=>n+m.frames,0),qa_pages:files.filter(f=>f.includes("/qa/")&&f.endsWith(".png")).length,all_text_utf8:!errors.some(e=>e.startsWith("UTF-8")),source_syntax_checked:true,preview_js_syntax_checked:true,git_commit:"not attempted: .git is read-only in this session",errors};
writeFileSync(new URL("handoff-check.json",OUT),JSON.stringify(result,null,2)+"\n","utf8");console.log(JSON.stringify(result));
if(errors.length)process.exitCode=1;
