import {readFileSync,writeFileSync} from "node:fs";
import {createHash} from "node:crypto";
import {bench} from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
import {encodePNG} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs";
export const specs=JSON.parse(readFileSync(new URL("items.json",import.meta.url),"utf8"));
export const repo=new URL("../../",import.meta.url);
export const digest=v=>createHash("sha256").update(v).digest("hex");
export const rootFor=s=>new URL(`art/bakeoff/effects/pixelfx/${s.family}/b/`,repo);
export const moduleFor=s=>new URL(`src/sn-${s.id.replaceAll("_","-")}-b.js`,rootFor(s));
export function measure(im,anchor) {
  let pixels=0,energy=0,border=0,badAlpha=0,x0=Infinity,y0=Infinity,x1=-Infinity,y1=-Infinity,head=0,body=0;
  for(let y=0;y<im.h;y++)for(let x=0;x<im.w;x++) {
    const j=(y*im.w+x)*4,a=im.data[j+3],light=Math.max(im.data[j],im.data[j+1],im.data[j+2]);
    if(a!==0&&a!==255)badAlpha++;
    if(!a||!light)continue;
    pixels++;energy+=light*a/255;x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
    if(x===0||y===0||x===im.w-1||y===im.h-1)border++;
    const rx=x-anchor[0],ry=y-anchor[1];
    if(rx>=-24&&rx<24&&ry>=-70&&ry<-24)head++;
    if(rx>=-20&&rx<20&&ry>=-24&&ry<24)body++;
  }
  return {pixels,energy:Math.round(energy),border,badAlpha,head,body,bounds:pixels?[x0-anchor[0],y0-anchor[1],x1-anchor[0],y1-anchor[1]]:null};
}
export async function bakeCharacter(family) {
  for(const s of specs.filter(s=>s.family===family)) {
    const mod=await import(moduleFor(s)),n=Math.round(s.duration*20);
    const strip=bench.bakeStrip(mod,{}, {frames:n,fps:20,w:s.size[0],h:s.size[1],anchor:s.origin,additive:s.blend==="add",mixed:s.blend==="mix",minLight:40});
    // bakeStrip retains low RGB colour pixels by design; the task's strict cutoff also drops those.
    if(s.blend==="add")for(let i=0;i<strip.data.length;i+=4)if(Math.max(strip.data[i],strip.data[i+1],strip.data[i+2])<40)strip.data.fill(0,i,i+4);
    writeFileSync(new URL(`${s.id}-b.png`,rootFor(s)),encodePNG(strip.w,strip.h,strip.data));
    const meta={note:s.note,frames:n,fps:20,anchor:s.origin,blend:s.blend,loop:!!s.loop,attach:s.attach,source:`art/bakeoff/effects/pixelfx/${s.family}/b/src/sn-${s.id.replaceAll("_","-")}-b.js`,frame_size:s.size,duration:s.duration,candidate:"B",start_delay:0};
    if(s.kind==="trail") {
      meta.playback="반드시 1프레임부터 시작한다. 짧게 시작해 길어졌다 짧아지는 반복을 시트 자체에 구웠다. 무작위 시작 프레임을 쓰지 않는다. 생성 순간 기존의 긴 꼬리가 발사자와 겹치는 것을 방지한다.";
    }
    writeFileSync(new URL(`${s.id}-b.json`,rootFor(s)),JSON.stringify(meta,null,2)+"\n","utf8");
    console.log(`${s.id}-b: ${n} x ${s.size.join("x")} @20fps`);
  }
}
