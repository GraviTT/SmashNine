import { writeFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { bakeStrip } from './bench.mjs';
import { encodePNG } from 'file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs';
import { specs } from './setup.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url));
export async function bakeCharacter(char) {
  for(const s of specs.filter(s=>s.char===char)) {
    const source=`art/bakeoff/effects/pixelfx/${char}/a/src/sn-${s.name.replaceAll('_','-')}-a.js`;
    const mod=await import(pathToFileURL(resolve(repo,source)).href);
    const strip=bakeStrip(mod,{}, {...s,additive:true,minLight:40});
    // bakeStrip keeps dim solid colour; this candidate also discards those sub-40 remnants.
    for(let i=0;i<strip.data.length;i+=4)if(Math.max(...strip.data.subarray(i,i+3))<40)strip.data.fill(0,i,i+4);
    const target=resolve(repo,`art/bakeoff/effects/pixelfx/${char}/a/${s.name}-a`);
    writeFileSync(`${target}.png`,encodePNG(strip.w,strip.h,strip.data));
    const meta={note:s.note,frames:s.frames,fps:s.fps,anchor:s.anchor,blend:'add',loop:s.loop,attach:s.attach,source,frame_size:[s.w,s.h],candidate:'A: 날카로운 순간'};
    writeFileSync(`${target}.json`,JSON.stringify(meta,null,2)+'\n','utf8');
    console.log(`${s.name}-a: ${s.frames} x ${s.w}x${s.h} @ ${s.fps} fps`);
  }
}
