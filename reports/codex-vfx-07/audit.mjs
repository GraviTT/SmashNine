import assert from "node:assert/strict";
import { readFileSync, writeFileSync } from "node:fs";
import { flight } from "../../art/bakeoff/effects/pixelfx/frey/b/src/frey-b-common.mjs";
const ROOT=new URL("../../art/bakeoff/effects/pixelfx/frey/b/",import.meta.url);
const itemList=JSON.parse(readFileSync(new URL("items.json",ROOT),"utf8"));
const measured=JSON.parse(readFileSync(new URL("measurements.json",import.meta.url),"utf8")).measurements;
const checks=[];
for(const item of itemList){
 const m=measured.find(m=>m.name===`frey_${item.id}-b`),source=new URL(`src/sn-frey-${item.id.replaceAll("_","-")}-b.js`,ROOT),mod=await import(source);
 assert.equal(m.first_frame,1,`${item.id}: blank first frame`);
 assert(m.peak_time<=0.100001,`${item.id}: late peak`);
 assert(m.duration<=(item.kind==="follow"?1:item.big?0.7:0.5));
 assert.equal(m.border_pixels,0);assert.equal(m.nonbinary_alpha,0);assert.equal(m.clipped_pixels,0);
 assert.equal(m.end_pixels,0);assert(m.deterministic);assert(m.last_energy_pct<1);
 assert.equal(m.max_core_pixels,0);
 assert(m.per_frame.every(f=>f.pixels>0),`${item.id}: empty baked frame`);
 const effect=mod.create(mod.meta.options),particles=effect.trajectories;
 let rebounds=0,belowFoot=0,maxY=-Infinity,maxGroundY=-Infinity;
 for(const s of particles){
  let wasFalling=false,bounced=false;
  for(let t=0;t<s.life;t+=1/120){
   const pos=flight(s,t,item.kind==="follow"?item.floorY:null);
   assert(Number.isFinite(pos.x)&&Number.isFinite(pos.y));
   if(item.floorY!==null&&item.floorY!==undefined){
    assert(pos.y<=item.floorY+1e-6);maxGroundY=Math.max(maxGroundY,pos.y);
    if(wasFalling&&pos.vy<-1&&!bounced){rebounds++;bounced=true;}
    if(pos.vy>0)wasFalling=true;
   }
   maxY=Math.max(maxY,pos.y);if(pos.y>32)belowFoot++;
  }
  // Positive world-Y acceleration for both left and right facing is independent of baked aim.
  const q0=flight(s,0.02),q1=flight(s,0.03),q2=flight(s,0.04);
  assert(q2.y-2*q1.y+q0.y>0);
 }
 if(item.kind==="follow"&&item.floorY!==null)assert(rebounds>0,`${item.id}: no visible-life bounce`);
 checks.push({id:item.id,frames:item.frames,contract:"PASS",rebounds_in_particle_lifetime:rebounds,samples_below_foot:belowFoot,max_particle_y:Number(maxY.toFixed(3)),max_ground_y:Number(maxGroundY.toFixed(3))});
}
const report={status:"PASS",effects:checks.length,frames:checks.reduce((s,c)=>s+c.frames,0),checks,notes:["Peak is summed max(R,G,B), not a human visibility rating.","Physics sampled at 120 Hz; particle centre floor and downward acceleration checked.","Empty-end, border, enlarged-canvas clipping and deterministic bake checks use measurements.json.","No gameplay, web p95/p99, hit-event count or 8-player performance claim."]};
writeFileSync(new URL("audit.json",import.meta.url),JSON.stringify(report,null,2)+"\n");
console.log(JSON.stringify(report,null,2));
