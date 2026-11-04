import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {performance} from 'node:perf_hooks';
import {specs} from './specs.mjs';
import {core,readPNG,stripFrame} from '../codex-vfx-08-a/bench.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)),out=fileURLToPath(new URL('./',import.meta.url));
const hash=b=>createHash('sha256').update(b).digest('hex');
function render(mod,s,t,pad=0){const f=core.createFrame(s.w+2*pad,s.h+2*pad),fx=core.createFx(mod,{x:s.anchor[0]+pad,y:s.anchor[1]+pad});fx.update(t);fx.draw(f,'back');fx.draw(f,'front');return f;}
function rgba(f){const data=new Uint8ClampedArray(f.w*f.h*4);for(let i=0;i<f.color.length;i++){const c=f.color[i],l=f.light[i],a=(c>>>24)/255,r=(c&255)*a+(l&255),g=((c>>>8)&255)*a+((l>>>8)&255),b=((c>>>16)&255)*a+((l>>>16)&255);if(Math.max(r,g,b)<40)continue;data.set([r,g,b,255],i*4);}return data;}
let results=[],errors=[];
for(const s of specs){
 const root=resolve(repo,`art/bakeoff/effects/pixelfx/${s.char}/a/${s.name}-a`),meta=JSON.parse(readFileSync(root+'.json','utf8')),strip=readPNG(root+'.png'),mod=await import(pathToFileURL(resolve(repo,meta.source)).href);
 let clippedPaintedPixels=0,endPixels=0,protectedHeadPixels=0,protectedCorePixels=0,alphaBad=0,borderPixels=0,dimPixels=0,emptyFrames=0,deterministic=true,atlasMismatchPixels=0;const energies=[];
 for(let n=0;n<=s.frames;n++){
  const f=render(mod,s,n/s.fps,48),raw=rgba(f),d2=rgba(render(mod,s,n/s.fps,48));deterministic&&=hash(raw)===hash(d2);
  for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++)if(raw[(y*f.w+x)*4+3]){if(x<49||x>=48+s.w-1||y<49||y>=48+s.h-1)clippedPaintedPixels++;if(n===s.frames)endPixels++;}
  if(n===s.frames)continue;
  const cell=stripFrame(strip,s.frames,n);let count=0,energy=0;
  for(let y=0;y<cell.h;y++)for(let x=0;x<cell.w;x++){
   const j=(y*cell.w+x)*4,a=cell.data[j+3],mx=Math.max(cell.data[j],cell.data[j+1],cell.data[j+2]);if(a!==0&&a!==255)alphaBad++;
   const rx=x-meta.anchor[0]+s.anchor[0]+48,ry=y-meta.anchor[1]+s.anchor[1]+48,ri=(ry*f.w+rx)*4;
   if(cell.data.slice(j,j+4).some((v,k)=>v!==raw[ri+k]))atlasMismatchPixels++;
   if(!a)continue;count++;energy+=mx;if(mx<40)dimPixels++;if(x===0||y===0||x===cell.w-1||y===cell.h-1)borderPixels++;
   const px=x-meta.anchor[0],py=y-meta.anchor[1];
   if(s.char==='luna'){if(Math.abs(px)<48&&py<-40)protectedHeadPixels++;}
   else{if(Math.abs(px)<48&&py>=-100&&py<-24)protectedHeadPixels++;if(Math.abs(px)<20&&py>=-24&&py<=24)protectedCorePixels++;}
  }
  if(!count)emptyFrames++;energies.push(energy);
 }
 const times=[];for(let i=0;i<30;i++){const start=performance.now();render(mod,s,(i%s.frames)/s.fps);times.push(performance.now()-start);}times.sort((a,b)=>a-b);
 const r={name:s.name,clippedPaintedPixels,endPixels,protectedHeadPixels,protectedCorePixels,alphaBad,borderPixels,dimPixels,emptyFrames,deterministic,atlasMismatchPixels,peakFrame:energies.indexOf(Math.max(...energies))+1,drawMedianMs:times[15],drawP95Ms:times[28],pngSha256:hash(readFileSync(root+'.png'))};results.push(r);
 if(clippedPaintedPixels||endPixels||protectedHeadPixels||protectedCorePixels||alphaBad||borderPixels||dimPixels||emptyFrames||atlasMismatchPixels||!deterministic)errors.push(s.name);
}
const report={basis:'Node/pixelfx CPU samples on a shared PC, not Godot/web performance. Head/core tests are explicit geometric regions, not every pose silhouette.',results,errors};
writeFileSync(resolve(out,'audit.json'),JSON.stringify(report,null,2)+'\n','utf8');console.log(JSON.stringify(report,null,2));if(errors.length)process.exitCode=1;
