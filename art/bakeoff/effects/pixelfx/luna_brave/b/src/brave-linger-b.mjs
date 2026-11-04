// CODEX-VFX-09 B. A brawler's broken star wake: direction is baked into XY;
// the acceleration is always screen-down. No simulated floor or rebound.
import {Rng,fit,scale,star} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
export const palette=["#542148","#a93685","#f064b7","#ffa8d5","#ffdb83","#fff9e9"];
const turn=(s,n,a)=>[s*Math.cos(a)-n*Math.sin(a),s*Math.sin(a)+n*Math.cos(a)];
// Avoid the central torso and a generous head/hair neighbourhood, including glow radius.
function safe(x,y,r=0){return !(x-r<42&&x+r>-42&&y-r<26&&y+r>-105);}
function glint(p,x,y,r,C,k,gold,twist=0) {
  if(!safe(x,y,r+3))return;
  p.poly(star(x,y,r*.4,r,5,-Math.PI/2+twist),scale(gold?C[4]:C[3],k));
  p.px(x,y,scale(C[5],k));
  p.glow(x,y,r+3,gold?C[4]:C[2],k*.3);
}
export function drawFollow(p,t,o) {
  if(t>=o.duration)return;
  const C=fit(o.palette,6),a=o.aimDeg*Math.PI/180,q=t/o.duration,low=o.kind==="low",upper=o.kind==="upper",spin=o.kind==="spin",dive=o.kind==="dive";
  const shift=low?32:0,n=o.kind==="jab"?11:spin||dive?19:15;
  // Unequal short ribbons point along the strike. They open, drift and break into stardust.
  if(t<.36)for(let lane=0;lane<(o.kind==="jab"?2:3);lane++) {
    const side=lane%2?1:-1,k=Math.pow(1-t/.36,.85);
    let previous=null;
    for(let j=0;j<32;j++) {
      const u=j/31,s=o.reach*(upper?.38:.40)+u*o.reach*(upper?.57:.53)+t*17;
      const lateral=upper?45+lane*6:side*((low?5:spin?20:12)+Math.sin(u*Math.PI)*(spin?15:6));
      let [x,y]=turn(s,lateral,a);y+=shift+40*t*t;
      if(j%11<2||!safe(x,y,5)){previous=null;continue;}
      if(previous) {
        p.line(previous[0],previous[1],x,y,scale(lane===1?C[4]:C[2],k*(.58+.3*u)));
        if(j>23)p.light(x,y,lane===1?C[4]:C[3],.3*k);
      }
      previous=[x,y];
    }
  }
  for(let i=0;i<n;i++) {
    const R=new Rng(o.seed+i*997),life=o.duration*R.range(.86,1),u=t/life;if(u>=1)continue;
    const s=R.range(upper?.4:.48,.98)*o.reach,lateral=upper?R.range(44,60):R.range(-(low?7:spin?30:18),low?7:spin?30:18);
    let [x,y]=turn(s,lateral,a);
    const [vx,vy]=turn(R.range(26,spin||dive?64:49),R.range(-17,17),a);
    x+=vx*t;y+=shift+vy*t+65*t*t;
    const k=Math.pow(1-u,.92),r=R.range(2.8,spin||dive?6:4.9)*(1-u*.6);
    if(i%3!==2)glint(p,x,y,r,C,k,i%3===0,u*.8);
    else if(safe(x,y,12)) {
      const speed=Math.hypot(vx,vy+130*t),len=Math.min(11,4+speed*.07)*(1-u*.5);
      const dx=vx/speed,dy=(vy+130*t)/speed;
      p.line(x-dx*len,y-dy*len,x,y,scale(i%2?C[3]:C[4],k));
      p.px(x,y,scale(C[5],k));
      p.glow(x,y,3,C[2],.25*k);
    }
  }
}
export function drawHit(p,t,o) {
  if(t>=o.duration)return;
  const C=fit(o.palette,6),big=o.big,n=big?21:13;
  // Existing hit spark owns the centre. Separated stars travel predominantly forward.
  for(let i=0;i<n;i++) {
    const R=new Rng(o.seed+i*997),side=i%5===0?-1:1,life=o.duration*R.range(.84,1),q=t/life;if(q>=1)continue;
    const x=side*(R.range(big?49:47,big?65:56)+R.range(24,big?72:48)*t);
    const y=R.range(-8,big?32:23)+R.range(-16,6)*t+55*t*t;
    const k=Math.pow(1-q,.85),r=R.range(3,big?7:5)*(1-q*.6);
    if(i%3!==2)glint(p,x,y,r,C,k,i%3===0,q*.8);
    else if(safe(x,y,7)) {
      p.line(x-side*(big?13:9)*(1-q),y-2,x,y,scale(C[3],k*.8));
      p.line(x-side*2,y,x,y,scale(C[4],k));
    }
  }
}
