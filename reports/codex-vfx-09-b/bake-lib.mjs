import {readFileSync,writeFileSync} from "node:fs";
import {bench} from "./bench-link.mjs";
import {encodePNG} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs";
export const specs=JSON.parse(readFileSync(new URL("items.json",import.meta.url),"utf8"));
export const repo=new URL("../../",import.meta.url);
export const rootFor=s=>new URL(`art/bakeoff/effects/pixelfx/${s.family}/b/`,repo);
export const moduleFor=s=>new URL(`src/sn-${s.id.replaceAll("_","-")}-b.js`,rootFor(s));
export const metaFor=s=>JSON.parse(readFileSync(new URL(`${s.id}-b.json`,rootFor(s)),"utf8"));
export function renderRaw(s,mod,pad=0,start=0,frames=s.frames) {
  const im=bench.bakeStrip(mod,{}, {frames,fps:s.fps,w:s.size[0]+pad*2,h:s.size[1]+pad*2,anchor:s.origin.map(v=>v+pad),additive:s.blend==="add",mixed:s.blend==="mix",minLight:40,border:0,start});
  if(s.blend==="add")for(let i=0;i<im.data.length;i+=4)if(Math.max(im.data[i],im.data[i+1],im.data[i+2])<40)im.data.fill(0,i,i+4);
  return im;
}
export async function bake(family,only=[]) {
  for(const s of specs.filter(s=>s.family===family&&(!only.length||only.includes(s.id)))) {
    const mod=await import(moduleFor(s)),raw=renderRaw(s,mod);
    let x0=Infinity,y0=Infinity,x1=0,y1=0;
    for(let y=0;y<raw.h;y++)for(let x=0;x<raw.w;x++)if(raw.data[(y*raw.w+x)*4+3]){const xx=x%s.size[0];x0=Math.min(x0,xx);y0=Math.min(y0,y);x1=Math.max(x1,xx);y1=Math.max(y1,y);}
    // Retain a two-pixel guard on every frame. Sprite coordinates stay at native art scale.
    x0-=2;y0-=2;x1+=2;y1+=2;
    const w=x1-x0+1,h=y1-y0+1,out={w:w*s.frames,h,data:new Uint8ClampedArray(w*s.frames*h*4)};
    for(let n=0;n<s.frames;n++)for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
      const sx=n*s.size[0]+x+x0,sy=y+y0;if(sx<n*s.size[0]||sx>=(n+1)*s.size[0]||sy<0||sy>=raw.h)continue;
      out.data.set(raw.data.subarray((sy*raw.w+sx)*4,(sy*raw.w+sx)*4+4),(y*out.w+n*w+x)*4);
    }
    writeFileSync(new URL(`${s.id}-b.png`,rootFor(s)),encodePNG(out.w,out.h,out.data));
    const meta={note:s.note,frames:s.frames,fps:s.fps,anchor:[s.origin[0]-x0,s.origin[1]-y0],blend:s.blend,loop:false,attach:s.attach,source:`art/bakeoff/effects/pixelfx/${s.family}/b/src/sn-${s.id.replaceAll("_","-")}-b.js`,frame_size:[w,h],duration:s.duration,candidate:"B",gravity:"screen-down, no floor bounce",start_delay:0};
    if(s.id==="luna_step")meta.playback="4 walk drawings per step; card nominal 0.35s. At adopted 11.31fps: 4/11.31=0.353669s, effective effect fps=7*11.31/4=19.7925.";
    writeFileSync(new URL(`${s.id}-b.json`,rootFor(s)),JSON.stringify(meta,null,2)+"\n","utf8");
    console.log(`${s.id}: ${s.frames} x ${w}x${h}, ${s.duration}s`);
  }
}
