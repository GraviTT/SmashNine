// CODEX-VFX-08 B. Star-shaped fragments and separated pink/gold wake filaments.
import { Rng, fit, scale, star, TAU } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
export const palette = ["#471853", "#913c9b", "#df69bd", "#ffb0dd", "#ffe2ac", "#ffffff"];
function glint(p,x,y,r,C,k,turn=0,gold=false) {
  p.poly(star(x,y,r*.38,r,5,-Math.PI/2+turn),scale(gold?C[4]:C[3],k));
  p.px(x,y,scale(C[5],k));
  if(r>3)p.line(x-1,y,x+1,y,scale(C[5],k*.9));
  p.glow(x,y,r+3,gold?C[4]:C[2],.3*k);
}
function dust(p,x,y,len,C,k,gold=false) {
  p.line(x-len,y,x,y,scale(gold?C[4]:C[2],k*.68));
  p.line(x-1,y,x,y,scale(gold?C[5]:C[3],k));
}

export function drawLaunch(p,t,o) {
  if(t>=o.duration)return;
  const C=fit(o.palette,6),big=o.big;
  for(let i=0;i<(big?16:11);i++) {
    const R=new Rng(o.seed+101+i*997),life=o.duration*R.range(.86,1.04),q=t/life;
    if(q>=1)continue;
    // A lower-side plume also stays away from the caster when the whole strip turns +/-60deg.
    const r=R.range(23,big?31:27);
    const x=-2+i%4*4+(1-Math.exp(-q*2.8))*R.range(16,big?53:38), y=r+Math.sin(q*Math.PI)*R.range(3,7);
    const k=Math.pow(1-q,.8), s=R.range(2.5,big?5.2:4);
    dust(p,x,y,8*(1-q)+2,C,k,i%3===0);
    if(i%2===0)glint(p,x,y,s*(1-q*.5),C,k,q*.7,i%3===0);
  }
  // Open slipstream below the star, never a filled bloom over its centre.
  if(t<.22) {
    const q=t/.22,k=1-q,xx=3+q*(big?29:20),yy=big?29:24;
    p.line(xx-7,yy+4,xx+5,yy,scale(C[3],k*.9));
    p.line(xx+5,yy,xx-7,yy+8,scale(C[4],k*.65));
  }
}

export function drawTrail(p,t,o) {
  const C=fit(o.palette,6),big=o.big;
  const period=o.duration, ph=((t%period)+period)%period/period;
  const length=big?153:113, near=big?25:16;
  // A periodic length envelope starts close to the star, grows with flight, then recedes.
  // The same short shape is approached on either side of the loop boundary. This avoids a
  // pre-existing full wake crossing the caster at spawn, without a game-side clipping shader.
  const age=ph*period,maxBehind=Math.max(0,(big?930:1050)*Math.min(age,period-age)-34);
  const tipK=.55+.4*Math.cos(ph*TAU);
  glint(p,-5,big?25:22,2.2,C,tipK,ph*.7,true);
  // Three unequal drifting lanes: gaps between them keep the wake airy at 1x.
  for(let lane=0;lane<3;lane++) {
    const side=lane===1?-1:1, laneY=(lane===2?2:big?12:7)*side;
    for(let i=0;i<length-near;i++) {
      const q=i/(length-near), x=-near-i;
      if(-x>maxBehind)continue;
      const y=laneY+Math.sin(q*7-ph*TAU+lane*1.7)*(big?3.2:2.2)*q;
      const k=Math.pow(1-q,1.3)*(.48+.18*Math.sin(ph*TAU-q*9+lane))*Math.min(1,(maxBehind+x)/12);
      if(k<.07||i%15>10)continue;
      p.light(x,y,lane===2?C[4]:C[2],k);
      if(i<22)p.light(x,y+1,C[3],k*.45);
    }
  }
  // Wrapped particles fade at both ends, so last->first is an ordinary time step.
  for(let i=0;i<(big?16:12);i++) {
    const R=new Rng(o.seed+401+i*997);
    const q=(ph+R.range(0,1))%1, side=i%2?1:-1;
    const x=-near-q*(length-near), y=side*R.range(big?8:5,big?21:15)+Math.sin(q*Math.PI*2+i)*2;
    const k=Math.pow(Math.sin(q*Math.PI),.7)*(.6+.4*(1-q))*Math.max(0,Math.min(1,(maxBehind+x-6)/14));
    if(k<.1)continue;
    if(i%3===0)glint(p,x,y,(big?4:3.2)*(1-q*.6),C,k,q*.8,i%2===0);
    else dust(p,x,y,3+5*(1-q),C,k,i%2===0);
  }
}

export function drawHit(p,t,o) {
  if(t>=o.duration)return;
  const C=fit(o.palette,6),big=o.big;
  // No replacement flash: existing hit spark / comet burst owns the contact.
  // Most debris exits right. A lower fan avoids the target's head and the bright burst centre.
  for(let i=0;i<(big?19:13);i++) {
    const R=new Rng(o.seed+701+i*997),side=i%5===0?-1:1, life=o.duration*R.range(.84,1.04);
    const q=t/life;if(q>=1)continue;
    const x=side*((big?38:31)+i%4*4)+side*(1-Math.exp(-q*2.9))*R.range(20,big?48:33);
    const y=R.range(-12,big?31:22)+q*R.range(7,18)+Math.sin(q*Math.PI+i)*3;
    const k=Math.pow(1-q,.68),s=R.range(3.5,big?7:5.5);
    if(i%2===0)glint(p,x,y,s*(1-q*.45),C,k,q*(i%2?1:-1),i%4===0);
    else dust(p,x,y,(big?11:8)*(1-q)+2,C,k,i%4===0);
  }
}
