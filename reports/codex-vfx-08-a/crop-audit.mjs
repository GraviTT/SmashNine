import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { specs } from './setup.mjs';
import { readPNG, stripFrame } from './bench.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)),out=fileURLToPath(new URL('./',import.meta.url));
const current=[];
for(const s of specs) {
  const stem=resolve(repo,`art/bakeoff/effects/pixelfx/${s.char}/a/${s.name}-a`),meta=JSON.parse(readFileSync(stem+'.json','utf8')),im=readPNG(stem+'.png');
  const hash=createHash('sha256');
  for(let n=0;n<meta.frames;n++) {
    const f=stripFrame(im,meta.frames,n),canonical=new Uint8Array(384*256*4);
    for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++) {
      const from=(y*f.w+x)*4,to=((y-meta.anchor[1]+128)*384+x-meta.anchor[0]+192)*4;
      if(f.data[from+3])canonical.set(f.data.subarray(from,from+4),to);
    }
    hash.update(canonical);
  }
  current.push({name:s.name,relativePixelHash:hash.digest('hex'),frameSize:meta.frame_size,anchor:meta.anchor});
}
if(process.argv.includes('--before'))writeFileSync(resolve(out,'crop-before.json'),JSON.stringify(current,null,2)+'\n','utf8');
else {
  const before=JSON.parse(readFileSync(resolve(out,'crop-before.json'),'utf8'));
  const results=current.map((s,i)=>({...s,previousSize:before[i].frameSize,identicalRelativePixels:s.relativePixelHash===before[i].relativePixelHash}));
  writeFileSync(resolve(out,'crop-equivalence.json'),JSON.stringify(results,null,2)+'\n','utf8');
  console.log(results.map(s=>({name:s.name,size:s.frameSize,identical:s.identicalRelativePixels})));
  if(results.some(s=>!s.identicalRelativePixels))process.exitCode=1;
}
