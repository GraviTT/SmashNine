// Asset-contract audit, using raw padded pixelfx draws so the baker cannot hide clipping.
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { performance } from 'node:perf_hooks';
import { specs } from './setup.mjs';
import { core, readPNG, stripFrame } from './bench.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)),out=fileURLToPath(new URL('./',import.meta.url));
function render(mod,s,t,pad=0) {
  const f=core.createFrame(s.w+2*pad,s.h+2*pad),fx=core.createFx(mod,{x:s.anchor[0]+pad,y:s.anchor[1]+pad});
  fx.update(t);fx.draw(f,'back');fx.draw(f,'front');return f;
}
function rgba(f) {
  const out=new Uint8Array(f.w*f.h*4);
  for(let i=0;i<f.color.length;i++) {
    const c=f.color[i],l=f.light[i],a=(c>>>24)/255;
    const rgb=[Math.min(255,(c&255)*a+(l&255)),Math.min(255,((c>>>8)&255)*a+((l>>>8)&255)),Math.min(255,((c>>>16)&255)*a+((l>>>16)&255))];
    if(Math.max(...rgb)<40)continue;
    out.set([...rgb,255],i*4);
  }
  return out;
}
const digest=a=>createHash('sha256').update(a).digest('hex');
function delta(a,b){let v=0;for(let i=0;i<a.length;i++)v+=Math.abs(a[i]-b[i]);return v;}
const results=[];let errors=[];
for(const s of specs) {
  const root=`art/bakeoff/effects/pixelfx/${s.char}/a`,path=`${root}/${s.name}-a`;
  const meta=JSON.parse(readFileSync(resolve(repo,`${path}.json`),'utf8'));
  const mod=await import(pathToFileURL(resolve(repo,meta.source)).href),strip=readPNG(resolve(repo,`${path}.png`));
  let clipping=0,atEnd=0,deterministic=true;
  for(let n=0;n<=s.frames;n++) {
    const f=render(mod,s,n/s.fps,48),data=rgba(f);
    for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++)if(data[(y*f.w+x)*4+3]&&(x<49||x>=48+s.w-1||y<49||y>=48+s.h-1))clipping++;
    if(n===s.frames&&!s.loop)atEnd=data.filter((_,i)=>i%4===3).reduce((a,b)=>a+(b>0),0);
    if(n<s.frames)deterministic&&=digest(data)===digest(rgba(render(mod,s,n/s.fps,48)));
  }
  const seam=s.loop?delta(rgba(render(mod,s,0)),rgba(render(mod,s,s.frames/s.fps))):null;
  const samples=Array.from({length:s.frames},(_,i)=>stripFrame(strip,s.frames,i).data);
  const adj=samples.map((a,i)=>delta(a,samples[(i+1)%samples.length]));
  const durations=[];
  // CPU only, serial, short; does not measure Godot or web frame cost.
  for(let n=0;n<100;n++){const t=performance.now();render(mod,s,(n%s.frames)/s.fps);durations.push(performance.now()-t);}
  durations.sort((a,b)=>a-b);
  let corePixels=0;
  for(const f of samples)for(let y=0;y<s.h;y++)for(let x=0;x<s.w;x++) {
    if(!f[(y*s.w+x)*4+3])continue;
    const dx=x-s.anchor[0],dy=y-s.anchor[1];
    if(s.kind.startsWith('hit')&&Math.abs(dx)<20&&dy>=-22&&dy<=22)corePixels++;
    if(s.loop&&Math.hypot(dx,dy)<(s.kind.endsWith('big')?30:16.5))corePixels++;
  }
  const m={name:s.name,clippedPaintedPixels:clipping,nonemptyAtDuration:atEnd,deterministic,loopEndpointDelta:seam,seamAdjacentDelta:s.loop?adj.at(-1):null,maxInternalAdjacentDelta:s.loop?Math.max(...adj.slice(0,-1)):null,protectedCorePaintedPixels:corePixels,cpuDrawMedianMs:durations[50],cpuDrawP95Ms:durations[95],pngSha256:digest(readFileSync(resolve(repo,`${path}.png`)))};
  if(clipping||atEnd||!deterministic||seam>0||corePixels)errors.push(s.name);
  results.push(m);
}
const report={basis:'CPU draw timing is local Node/pixelfx only; not an in-game performance benchmark.',results,errors};
writeFileSync(resolve(out,'audit.json'),JSON.stringify(report,null,2)+'\n','utf8');
console.log(JSON.stringify(report,null,2));
if(errors.length)process.exitCode=1;
