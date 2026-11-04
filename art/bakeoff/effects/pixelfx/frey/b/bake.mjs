// node art/bakeoff/effects/pixelfx/frey/b/bake.mjs
// All writes stay in candidate B and reports/codex-vfx-07. The original bench is imported unchanged.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";
import { bench } from "./bench-link.mjs";
import { encodePNG } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs";
const { bakeStrip, stripFrame }=bench;
export const ROOT=new URL("./",import.meta.url), REPORT=new URL("../../../../../../reports/codex-vfx-07/",ROOT);
export const items=JSON.parse(readFileSync(new URL("items.json",ROOT),"utf8"));
const writeJSON=(url,obj)=>writeFileSync(url,JSON.stringify(obj,null,2)+"\n");
const digest=data=>createHash("sha256").update(data).digest("hex");
function measure(frame,anchor) {
 let pixels=0, energy=0, core=0, head=0, border=0, badAlpha=0, minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity;
 for(let y=0;y<frame.h;y++)for(let x=0;x<frame.w;x++){
  const i=(y*frame.w+x)*4,a=frame.data[i+3];
  if(a!==0&&a!==255)badAlpha++;
  if(!a)continue;
  const brightness=Math.max(frame.data[i],frame.data[i+1],frame.data[i+2]);
  if(!brightness)continue;
  pixels++;energy+=brightness;
  minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);
  if(x===0||y===0||x===frame.w-1||y===frame.h-1)border++;
  const rx=x-anchor[0],ry=y-anchor[1];
  if(rx>=-20&&rx<20&&ry>=-30&&ry<30)core++;
  if(rx>=-24&&rx<24&&ry>=-72&&ry<-24)head++;
 }
 return {pixels,energy,core,head,border,badAlpha,bounds:pixels?[minX-anchor[0],minY-anchor[1],maxX-anchor[0],maxY-anchor[1]]:null};
}
export async function bake() {
 mkdirSync(REPORT,{recursive:true});
 const metrics=[];
 for(const item of items){
  const name=`frey_${item.id}-b`,source=`src/sn-frey-${item.id.replaceAll("_","-")}-b.js`,mod=await import(new URL(source,ROOT));
  const spec={frames:item.frames,fps:20,w:item.size[0],h:item.size[1],anchor:item.origin,additive:true,minLight:40};
  const strip=bakeStrip(mod,{},spec), again=bakeStrip(mod,{},spec);
  const frameStats=Array.from({length:item.frames},(_,i)=>({frame:i+1,time:i/20,...measure(stripFrame(strip,item.frames,i),item.origin)}));
  const wider=bakeStrip(mod,{}, {...spec,w:spec.w+128,h:spec.h+128,anchor:spec.anchor.map(v=>v+64),border:0});
  let clippedPixels=0;
  for(let n=0;n<item.frames;n++) {
   const f=stripFrame(wider,item.frames,n);
   for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++)if(x<65||y<65||x>=64+spec.w-1||y>=64+spec.h-1){
    const j=(y*f.w+x)*4;if(f.data[j+3]&&Math.max(...f.data.subarray(j,j+3))>0)clippedPixels++;
   }
  }
  const end=bakeStrip(mod,{}, {...spec,frames:1,start:mod.meta.duration+0.000001});
  const bounds=frameStats.filter(f=>f.bounds).reduce((r,f)=>[Math.min(r[0],f.bounds[0]),Math.min(r[1],f.bounds[1]),Math.max(r[2],f.bounds[2]),Math.max(r[3],f.bounds[3])],[Infinity,Infinity,-Infinity,-Infinity]);
  const first=frameStats.find(f=>f.pixels>0),peak=frameStats.reduce((a,b)=>b.energy>a.energy?b:a),last=frameStats.findLast(f=>f.pixels>0);
  const png=encodePNG(strip.w,strip.h,strip.data);
  writeFileSync(new URL(`${name}.png`,ROOT),png);
  const attach=item.kind==="follow"?`Frey ${item.id}: 해당 J 판정 활성 순간, frey_slash와 같은 몸 중심. 오른쪽 기준 ${item.aimDeg}도 내장, 좌우 반전만 하고 회전·확대하지 않음. 생성 위치에 남음.`:`Frey의 ${item.big?"강한":"일반"} 실제 적중 1회당 1번, 기존 적중 불꽃 시작 0.075초 뒤 맞은 몸 중심에 생성. 방어·패리·빗나감 제외. 좌우 반전만, 1배.`;
  writeJSON(new URL(`${name}.json`,ROOT),{note:item.note,frames:item.frames,fps:20,anchor:item.origin,blend:"add",attach,source:`art/bakeoff/effects/pixelfx/frey/b/${source}`,frame_size:item.size,loop:false,duration:mod.meta.duration,start_delay:item.kind==="hit"?0.075:0,aim_degrees:item.aimDeg??null,reach:item.reach??null,floor_y:item.floorY??null,candidate:"B"});
  metrics.push({name,duration:item.frames/20,frames:item.frames,fps:20,first_frame:first?.frame,first_time:first?.time,peak_frame:peak.frame,peak_time:peak.time,peak_pixels:peak.pixels,peak_energy:peak.energy,last_frame:last?.frame,last_time:last?.time,last_energy_pct:Number((frameStats.at(-1).energy/peak.energy*100).toFixed(3)),frame_size:item.size,strip_size:[strip.w,strip.h],anchor:item.origin,painted_bounds:bounds,painted_size:[bounds[2]-bounds[0]+1,bounds[3]-bounds[1]+1],max_core_pixels:Math.max(...frameStats.map(f=>f.core)),max_head_pixels:Math.max(...frameStats.map(f=>f.head)),border_pixels:frameStats.reduce((a,f)=>a+f.border,0),nonbinary_alpha:frameStats.reduce((a,f)=>a+f.badAlpha,0),clipped_pixels:clippedPixels,end_pixels:measure(end,item.origin).pixels,deterministic:digest(strip.data)===digest(again.data),png_bytes:png.length,sha256:digest(png),per_frame:frameStats});
 }
 writeJSON(new URL("measurements.json",REPORT),{peak_definition:"프레임의 모든 비투명 픽셀 max(R,G,B) 합계가 최대인 첫 프레임",core_region:"몸 중심 기준 x=[-20,20), y=[-30,30): 40x60",measurements:metrics});
 for(const m of metrics)console.log(`${m.name}: ${m.duration}s F${m.first_frame}->peak F${m.peak_frame}, bbox ${m.painted_size.join("x")}, core ${m.max_core_pixels}, clipped ${m.clipped_pixels}, last ${m.last_energy_pct}%`);
 return metrics;
}
// Keep the pilot's exports and its explicit rebuild path; the default builds the current card.
if(process.argv[1]===fileURLToPath(import.meta.url)) {
 if(process.argv.includes("--pilot"))await bake();
 else { const {bakeCharacter}=await import("../../../../../../reports/codex-vfx-08-b/bake-lib.mjs"); await bakeCharacter("frey"); }
}
