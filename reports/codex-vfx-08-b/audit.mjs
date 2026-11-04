import {readFileSync,writeFileSync} from "node:fs";
import {bench} from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
import {specs,rootFor,moduleFor,digest,measure} from "./bake-lib.mjs";
const {bakeStrip,stripFrame,readPNG}=bench;
function raw(s,mod,start=0,extra=0,frames=1) {
  const im=bakeStrip(mod,{}, {frames,fps:20,w:s.size[0]+extra*2,h:s.size[1]+extra*2,anchor:s.origin.map(v=>v+extra),additive:s.blend==="add",mixed:s.blend==="mix",minLight:40,border:0,start});
  if(s.blend==="add")for(let i=0;i<im.data.length;i+=4)if(Math.max(im.data[i],im.data[i+1],im.data[i+2])<40)im.data.fill(0,i,i+4);
  return im;
}
function diff(a,b) {let sum=0;for(let i=0;i<a.data.length;i+=4)for(let k=0;k<3;k++)sum+=Math.abs(a.data[i+k]*a.data[i+3]/255-b.data[i+k]*b.data[i+3]/255);return Math.round(sum);}
const measurements=[];let failed=false;
for(const s of specs) {
  const mod=await import(moduleFor(s)),n=Math.round(s.duration*20),im=readPNG(new URL(`${s.id}-b.png`,rootFor(s)));
  const frames=Array.from({length:n},(_,i)=>stripFrame(im,n,i));
  const per=frames.map((f,i)=>({frame:i+1,time:i/20,...measure(f,s.origin)}));
  const peak=per.reduce((a,b)=>b.energy>a.energy?b:a),all=per.filter(f=>f.bounds);
  const bounds=all.reduce((a,f)=>[Math.min(a[0],f.bounds[0]),Math.min(a[1],f.bounds[1]),Math.max(a[2],f.bounds[2]),Math.max(a[3],f.bounds[3])],[Infinity,Infinity,-Infinity,-Infinity]);
  let clipping=0;const pad=48,wide=raw(s,mod,0,pad,n);
  for(let i=0;i<n;i++) {
    const f=stripFrame(wide,n,i);
    for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++)if(x<pad+1||y<pad+1||x>=pad+s.size[0]-1||y>=pad+s.size[1]-1) {
      const j=(y*f.w+x)*4;if(f.data[j+3]&&Math.max(f.data[j],f.data[j+1],f.data[j+2]))clipping++;
    }
  }
  const zero=raw(s,mod),end=raw(s,mod,s.duration+1e-8),same=raw(s,mod),steps=frames.slice(1).map((f,i)=>diff(frames[i],f));
  const seam=s.loop?diff(frames.at(-1),frames[0]):null;
  const loopExact=s.loop?diff(zero,raw(s,mod,s.duration)):null;
  const m={id:s.id,frames:n,fps:20,duration:s.duration,first_visible_frame:all[0]?.frame,peak_frame:peak.frame,peak_time:peak.time,painted_bounds:bounds,painted_size:[bounds[2]-bounds[0]+1,bounds[3]-bounds[1]+1],frame_size:s.size,peak_energy:peak.energy,peak_pixels:peak.pixels,last_energy_pct:+(100*per.at(-1).energy/peak.energy).toFixed(2),border_pixels:per.reduce((a,f)=>a+f.border,0),clipped_pixels:clipping,nonbinary_alpha:s.blend==="add"?per.reduce((a,f)=>a+f.badAlpha,0):null,end_pixels:measure(end,s.origin).pixels,deterministic:digest(zero.data)===digest(same.data),loop_exact_difference:loopExact,loop_seam_difference:seam,loop_internal_differences:s.loop?steps:null,head_peak_pixels:s.kind==="hit"?Math.max(...per.map(f=>f.head)):null,body_peak_pixels:s.kind==="hit"?Math.max(...per.map(f=>f.body)):null,sha256:digest(readFileSync(new URL(`${s.id}-b.png`,rootFor(s)))),per_frame:per};
  const errors=[];
  if(m.first_visible_frame!==1)errors.push("empty first frame");
  if(m.border_pixels||m.clipped_pixels)errors.push("clipping/border");
  if(m.nonbinary_alpha)errors.push("non-binary alpha");
  if(!s.loop&&m.end_pixels)errors.push("nonempty end");
  if(!m.deterministic)errors.push("nondeterministic");
  if(s.loop&&(loopExact!==0||seam>Math.max(...steps)*1.4))errors.push("loop seam");
  if(s.kind==="hit"&&(m.head_peak_pixels||m.body_peak_pixels))errors.push("head/body obstruction");
  m.errors=errors;failed ||= errors.length>0;measurements.push(m);
  console.log(`${m.id}: ${m.duration}s, first F${m.first_visible_frame}, peak F${m.peak_frame}, paint ${m.painted_size.join("x")}, clip ${clipping}, tail ${m.last_energy_pct}%, ${errors.join("; ")||"PASS"}`);
}
writeFileSync(new URL("measurements.json",import.meta.url),JSON.stringify({peak_definition:"알파를 곱한 max(R,G,B) 합계가 최대인 첫 프레임. 크기는 전체 프레임의 그려진 픽셀 합집합 경계.",head_region:"적중 중심 기준 x=[-24,24), y=[-70,-24)",body_region:"적중 중심 기준 x=[-20,20), y=[-24,24)",measurements},null,2)+"\n","utf8");
if(failed)process.exitCode=1;
