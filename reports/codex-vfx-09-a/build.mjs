import {mkdirSync,writeFileSync,readFileSync} from 'node:fs';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
import {specs} from './specs.mjs';
import {bakeStrip,crop} from '../codex-vfx-08-a/bench.mjs';
import {encodePNG} from 'file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url));
export async function build(char){
 for(const s of specs.filter(s=>!char||s.char===char)){
  const dir=`art/bakeoff/effects/pixelfx/${s.char}/a`,source=`${dir}/src/sn-${s.name.replaceAll('_','-')}-a.js`;
  mkdirSync(resolve(repo,dir,'src'),{recursive:true});
  const helper=s.char==='luna'?'../../../luna_brave/a/src/sharp09-a.js':'./sharp09-a.js';
  const meta={name:`SN ${s.name} A - sharp moment`,size:[s.w,s.h],origin:s.anchor,duration:s.frames/s.fps,loop:false,fps:s.fps,tags:['smashnine','candidate-a',s.kind],options:{kind:s.kind,aim:s.aim,reach:s.reach,seed:9}};
  writeFileSync(resolve(repo,source),`import {drawSharp,palettes} from '${helper}';\nexport const meta=${JSON.stringify(meta,null,2)};\nmeta.options.palette=palettes.main;\nmeta.options.gold=palettes.gold;\nexport const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);\n`,'utf8');
  const mod=await import(pathToFileURL(resolve(repo,source)).href);
  const strip=bakeStrip(mod,{}, {...s,additive:true,minLight:40});
  let x0=s.w,y0=s.h,x1=0,y1=0;
  for(let y=0;y<s.h;y++)for(let x=0;x<strip.w;x++){
   const i=(y*strip.w+x)*4;if(Math.max(strip.data[i],strip.data[i+1],strip.data[i+2])<40)strip.data.fill(0,i,i+4);
   if(strip.data[i+3]){x0=Math.min(x0,x%s.w);x1=Math.max(x1,x%s.w);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  }
  x0=Math.max(0,x0-2);y0=Math.max(0,y0-2);x1=Math.min(s.w-1,x1+2);y1=Math.min(s.h-1,y1+2);
  const w=x1-x0+1,h=y1-y0+1,out=new Uint8ClampedArray(w*s.frames*h*4);
  for(let n=0;n<s.frames;n++){const f=crop(strip,n*s.w+x0,y0,w,h);for(let y=0;y<h;y++)out.set(f.data.subarray(y*w*4,(y+1)*w*4),(y*w*s.frames+n*w)*4);}
  const json={note:s.note,frames:s.frames,fps:s.fps,anchor:[s.anchor[0]-x0,s.anchor[1]-y0],blend:'add',loop:false,attach:s.attach,source,frame_size:[w,h],candidate:'A: 날카로운 순간',aim_degrees:s.aim,reach:s.reach};
  writeFileSync(resolve(repo,dir,`${s.name}-a.png`),encodePNG(w*s.frames,h,out));
  writeFileSync(resolve(repo,dir,`${s.name}-a.json`),JSON.stringify(json,null,2)+'\n','utf8');
  console.log(`${s.name}: ${s.frames} x ${w}x${h}, ${s.frames/s.fps}s`);
 }
}
if(process.argv[1]&&fileURLToPath(import.meta.url)===resolve(process.argv[1]))await build(process.argv[2]);
