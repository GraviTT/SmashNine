import {readFileSync,writeFileSync} from "node:fs";
import {createHash} from "node:crypto";
import {specs,rootFor,moduleFor,metaFor,renderRaw} from "./bake-lib.mjs";
import {bench} from "./bench-link.mjs";
const hash=v=>createHash("sha256").update(v).digest("hex");
function measure(im,anchor) {
  let count=0,energy=0,border=0,alpha=0,dim=0,head=0,torso=0,darkOpaque=0,b=[Infinity,Infinity,-Infinity,-Infinity];
  for(let y=0;y<im.h;y++)for(let x=0;x<im.w;x++) {
    const i=(y*im.w+x)*4,a=im.data[i+3],lum=Math.max(...im.data.subarray(i,i+3));if(!a)continue;
    count++;energy+=lum*a/255;if(a!==255)alpha++;if(lum<40)dim++;
    if(a>=240&&lum<80)darkOpaque++;
    if(x===0||y===0||x===im.w-1||y===im.h-1)border++;
    const rx=x-anchor[0],ry=y-anchor[1];b=[Math.min(b[0],rx),Math.min(b[1],ry),Math.max(b[2],rx),Math.max(b[3],ry)];
    if(rx>=-36&&rx<=36&&ry>=-98&&ry<=-22)head++;
    if(rx>=-22&&rx<=22&&ry>-22&&ry<25)torso++;
  }
  return {pixels:count,energy:Math.round(energy),border,nonbinary_alpha:alpha,under40:dim,dark_opaque:darkOpaque,head,torso,bounds:count?b:null};
}
const measurements=[];
for(const s of specs) {
  const m=metaFor(s),mod=await import(moduleFor(s)),im=bench.readPNG(new URL(`${s.id}-b.png`,rootFor(s)));
  const per=Array.from({length:s.frames},(_,i)=>({frame:i+1,time:i/s.fps,...measure(bench.stripFrame(im,s.frames,i),m.anchor)}));
  const peak=per.reduce((a,b)=>b.energy>a.energy?b:a),nz=per.filter(f=>f.pixels),b=nz.reduce((a,f)=>[Math.min(a[0],f.bounds[0]),Math.min(a[1],f.bounds[1]),Math.max(a[2],f.bounds[2]),Math.max(a[3],f.bounds[3])],[Infinity,Infinity,-Infinity,-Infinity]);
  const pad=40,raw=renderRaw(s,mod,pad),end=measure(renderRaw(s,mod,0,s.duration,1),s.origin);let clipped=0;
  for(let i=0;i<s.frames;i++) {
    const f=bench.stripFrame(raw,s.frames,i);
    for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++)if((x<pad||x>=pad+s.size[0]||y<pad||y>=pad+s.size[1])&&f.data[(y*f.w+x)*4+3])clipped++;
  }
  const errors=[];
  if(nz[0]?.frame!==1)errors.push("empty first frame");
  if(clipped||per.some(f=>f.border))errors.push("clipping or border");
  if(s.blend==="add"&&per.some(f=>f.nonbinary_alpha||f.under40))errors.push("additive contract");
  if(s.blend==="mix"&&per.some(f=>f.dark_opaque))errors.push("opaque dark stardust regression");
  if(end.pixels)errors.push("nonempty end");
  const deterministic=hash(renderRaw(s,mod).data)===hash(renderRaw(s,mod).data);if(!deterministic)errors.push("nondeterministic");
  const untrimmed=renderRaw(s,mod);let mismatches=0;
  for(let n=0;n<s.frames;n++)for(let y=0;y<m.frame_size[1];y++)for(let x=0;x<m.frame_size[0];x++){
    const sx=n*s.size[0]+x+s.origin[0]-m.anchor[0],sy=y+s.origin[1]-m.anchor[1],di=(y*im.w+n*m.frame_size[0]+x)*4;
    for(let c=0;c<4;c++)if(im.data[di+c]!==untrimmed.data[(sy*untrimmed.w+sx)*4+c])mismatches++;
  }
  if(mismatches)errors.push("baked strip differs from module");
  if(['x','y','flip','angle'].some(key=>Object.hasOwn(mod.meta.options,key)))errors.push("reserved option");
  if(s.family==="luna_brave"&&per.some(f=>f.head||f.torso))errors.push("protected body region");
  const r={id:s.id,frames:s.frames,fps:s.fps,duration:s.duration,first_visible_frame:nz[0]?.frame,peak_frame:peak.frame,peak_time:peak.time,painted_size:[b[2]-b[0]+1,b[3]-b[1]+1],painted_bounds:b,frame_size:m.frame_size,anchor:m.anchor,peak_pixels:peak.pixels,peak_energy:peak.energy,last_energy_pct:+(100*per.at(-1).energy/peak.energy).toFixed(2),clipped_pixels:clipped,border_pixels:per.reduce((a,f)=>a+f.border,0),end_pixels:end.pixels,deterministic,sha256:hash(readFileSync(new URL(`${s.id}-b.png`,rootFor(s)))),errors,per_frame:per};
  r.last_visible_frame=nz.at(-1).frame;r.baked_module_mismatches=mismatches;
  r.game_fps=s.kind==="step"?s.frames*11.31/4:s.fps;r.game_duration=s.frames/r.game_fps;
  measurements.push(r);console.log(`${s.id}: first ${r.first_visible_frame}, peak ${r.peak_frame}, paint ${r.painted_size.join("x")}, tail ${r.last_energy_pct}%, ${errors.join(",")||"PASS"}`);
}
writeFileSync(new URL("measurements.json",import.meta.url),JSON.stringify({definitions:{peak:"알파를 곱한 max(R,G,B) 합계가 최대인 첫 프레임",painted:"모든 프레임의 비투명 픽셀 경계 합집합",head:"몸 중심 기준 x -36..36, y -98..-22",torso:"몸 중심 기준 x -22..22, y -21..24"},measurements},null,2)+"\n","utf8");
if(measurements.some(m=>m.errors.length))process.exitCode=1;
