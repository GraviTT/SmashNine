// Candidate B: a broken gold blade-edge, tangential steel filings, gravity in world Y.
// Uses the read-only pixelfx painter and seeded RNG; never rotates a simulated floor.
import { Rng, fit, scale } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";

export const PALETTE = ["#3a2206", "#7a4a10", "#c08020", "#f0c040", "#fff0a0", "#ffffff"];
const rot = (x,y,a) => [x*Math.cos(a)-y*Math.sin(a),x*Math.sin(a)+y*Math.cos(a)];

// Analytic ballistic flight, one damped rebound. All Y acceleration is down.
export function flight(s, t, floor=null) {
  const g=s.g ?? 680;
  let x=s.x+s.vx*t, y=s.y+s.vy*t+0.5*g*t*t, vx=s.vx, vy=s.vy+g*t;
  if (floor !== null) {
    const root=(-s.vy+Math.sqrt(s.vy*s.vy+2*g*Math.max(0,floor-s.y)))/g;
    if (t>=root) {
      const age=t-root, rebound=(s.vy+g*root)*0.38;
      x=s.x+s.vx*root+s.vx*0.65*age;
      y=floor-rebound*age+0.5*g*age*age;
      vx=s.vx*0.65; vy=-rebound+g*age;
      if (y>floor) { y=floor; vy=0; }
    }
  }
  return {x,y,vx,vy};
}

function glint(p,x,y,arm,C,k=1) {
  const a=Math.max(1,Math.round(arm)), c=scale(C[4],k), white=scale(C[5],k);
  p.line(x-a,y,x+a,y,c); p.line(x,y-a,x,y+a,c);
  p.line(x-1,y,x+1,y,white); p.line(x,y-1,x,y+1,white);
  p.glow(x,y,a+3,C[3],0.36*k);
}
function streak(p,pos,C,age,life) {
  const q=age/life, k=Math.pow(1-q,0.65), speed=Math.hypot(pos.vx,pos.vy)||1;
  const len=Math.max(1,Math.min(11,speed*0.032))*(1-q*0.6);
  const tx=pos.x-pos.vx/speed*len, ty=pos.y-pos.vy/speed*len;
  p.line(tx,ty,pos.x,pos.y,scale(C[3],k));
  p.line(pos.x-pos.vx/speed*len*0.3,pos.y-pos.vy/speed*len*0.3,pos.x,pos.y,scale(q<0.24?C[5]:C[4],k));
  p.glow(pos.x,pos.y,3.8,C[3],0.36*k);
}

export function createFollow(o) {
  const C=fit(o.palette,6), rng=new Rng(o.seed), a=o.aimDeg*Math.PI/180, reach=o.reach;
  const point=(phi,extra=0) => rot(reach*(0.31+0.59*Math.cos(phi))+extra,reach*0.168*Math.sin(phi),a);
  const sparks=Array.from({length:15},(_,i)=>{
    const phi=rng.range(-1.15,1.15), [x,y]=point(phi), side=i%2?-1:1;
    const [vx,vy]=rot(rng.range(30,90),side*rng.range(18,68),a);
    return {x,y:o.floorY===null?y:Math.min(y,30),vx:vx+(x<0?-18:18),vy:vy-16,g:680,at:i<6?0:rng.range(0.015,0.05),life:rng.range(0.42,Math.min(0.78,o.duration-0.075))};
  });
  // Three longer falling filings make the ground and aerial uppercut visibly different.
  if(o.aimDeg < -60) for(const i of [2,7,12]) Object.assign(sparks[i], {vx:38+i,vy:-8,g:720,at:0,life:o.duration-0.025});
  if(o.aimDeg >= -60) for(const i of [0,4]) Object.assign(sparks[i], {at:0,life:o.duration-0.025});
  const glints=Array.from({length:10},(_,i)=>{
    const phi=-1.13+i*2.26/9, [x,y]=point(phi, i%3===0?3:-1);
    return {x,y,at:i%2===0?0:rng.range(0.015,0.045),life:rng.range(0.25,0.48),arm:rng.range(2.5,5.3),vx:x<0?-7:7};
  });
  let t=0;
  return {
    update(dt){t+=dt;},
    draw(p){
      if(t>=o.duration) return;
      // Already visible at release; its initial arc is thin enough to leave the existing slash in charge.
      if(t<0.34) {
        const k=1-t/0.34;
        for(let i=0;i<38;i++) {
          if(t>0.11 && (i%7===0 || (t>0.22 && i%3===0))) continue;
          const phi=-1.18+i*2.36/38, phi2=phi+2.36/38;
          const [x,y]=point(phi), [xx,yy]=point(phi2);
          if(o.floorY!==null && Math.max(y,yy)>30) continue;
          p.line(x,y,xx,yy,scale(t<0.10?C[4]:C[3],0.95*k));
          const [ox,oy]=rot(-1,0,a);
          p.line(x+ox,y+oy,xx+ox,yy+oy,scale(C[3],0.8*k));
          if(i%3===0)p.glow(x,y,5,C[3],0.24*k);
        }
      }
      for(const s of sparks) {
        const age=t-s.at;
        if(age<0 || age>=s.life)continue;
        const pos=flight(s,age,o.floorY);
        if(Math.abs(pos.x)<25 && pos.y>-76 && pos.y<29)continue;
        streak(p,pos,C,age,s.life);
      }
      for(const s of glints) {
        const age=t-s.at;
        if(age<0 || age>=s.life)continue;
        const q=age/s.life, x=s.x+s.vx*age, y=s.y+30*age*age;
        if(o.floorY!==null && y>28)continue;
        const envelope=s.at===0?Math.pow(1-q,0.65):Math.sin(Math.PI*Math.min(1,q*1.2));
        if(envelope>0.08)glint(p,x,y,Math.max(1,s.arm*envelope),C,Math.pow(1-q,0.65));
      }
    },
    // Used by the contract audit, independent of rasterization.
    trajectories:sparks.map(s=>({...s})),
  };
}

export function createHit(o) {
  const C=fit(o.palette,6), rng=new Rng(o.seed), big=o.big, duration=o.duration;
  const sparks=Array.from({length:big?12:8},(_,i)=>{
    const side=i%3===0?-1:1;
    return {x:side*rng.range(29,big?41:36),y:rng.range(-19,21),vx:side*rng.range(25,big?112:78),vy:rng.range(-65,12),g:280,at:0,life:rng.range(duration*0.6,duration-0.025)};
  });
  let t=0;
  return {
    update(dt){t+=dt;},
    draw(p){
      if(t>=duration)return;
      const q=t/duration, k=Math.pow(1-q,0.8);
      // Two short, offset blade fragments on opposite sides of the target; no disc over its body.
      if(t<(big?0.27:0.19))for(const side of [-1,1]) {
        const R=(big?43:35)+t*24;
        const lo=side===1?-1.08:-0.68, hi=side===1?0.53:0.94;
        for(let j=0;j<21;j++) {
          if(t>0.09 && j%6<2)continue;
          const ph=lo+(hi-lo)*j/21, ph2=lo+(hi-lo)*(j+1)/21;
          const x=side*(23+R*0.38*Math.cos(ph)), y=R*Math.sin(ph)-side*4+t*8;
          const xx=side*(23+R*0.38*Math.cos(ph2)), yy=R*Math.sin(ph2)-side*4+t*8;
          p.line(x,y,xx,yy,scale(t<0.06?C[4]:C[3],k));
          p.line(x+side,y,xx+side,yy,scale(C[3],0.9*k));
          if(j%5===0)p.glow(x,y,4,C[3],0.27*k);
        }
      }
      for(const s of sparks){if(t<s.life)streak(p,flight(s,t),C,t,s.life);}
      const count=big?5:3;
      for(let i=0;i<count;i++){
        const side=i%2?-1:1, x=side*((big?38:33)+t*(12+i*4));
        const y=(-21+i*12)+20*t*t, life=duration*(0.63+i*0.045);
        if(t<life)glint(p,x,y,(big?6.8:5.0)*Math.pow(1-t/life,0.6),C,1-t/life);
      }
    },
    trajectories:sparks.map(s=>({...s})),
  };
}
