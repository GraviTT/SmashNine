import fs from 'node:fs';
import path from 'node:path';
const dir=path.dirname(new URL(import.meta.url).pathname.replace(/^\/(?:([A-Za-z]:))/, '$1'));
const read=(d,n)=>JSON.parse(fs.readFileSync(path.join(d,n),'utf8').replace(/^\uFEFF/,''));
const olddir=path.join(dir,'../codex-qa-21');
const keys=['seconds_simulated','defeats','nan_positions','node_count','monster_hits','pvp_hits','ringouts'];
const previous=[2105,2106].map(s=>read(olddir,`gate-soak-${s}.json`));
const current=[2105,2106].map(s=>read(dir,`gate-soak-${s}.json`));
const comparison=keys.map(key=>{
 const oldValues=previous.map(r=>r[key]),spread=Math.max(...oldValues)-Math.min(...oldValues);
 return {key,old_spread:spread,runs:current.map((r,i)=>({seed:r.seed,before:oldValues[i],after:r[key],delta:r[key]-oldValues[i],exceeds_old_spread:Math.abs(r[key]-oldValues[i])>spread+1e-7}))};
});
const gateIntervals=current.map(run=>{
 const last={},revisits=[];
 for(const e of run.gate_events) {
  const key=e.window+':'+e.player;
  if(last[key]) revisits.push({seed:run.seed,player:e.player,hero:e.hero,window:e.window,from_time:last[key].t,to_time:e.t,seconds:e.t-last[key].t,frame_gap:e.frame-last[key].frame,previous_exit:last[key].to,next_entry:e.from,next_exit:e.to});
  last[key]=e;
 }
 return {seed:run.seed,events:run.gate_events.length,max_per_window:run.max_transports_per_actor_window,minimum_revisit_seconds:revisits.length?Math.min(...revisits.map(r=>r.seconds)):null,revisits};
});
fs.writeFileSync(path.join(dir,'regression-comparison.json'),JSON.stringify({comparison,gateIntervals},null,2)+'\n');
console.log(JSON.stringify({comparison,gateIntervals},null,2));
