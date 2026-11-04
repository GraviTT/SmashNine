// CODEX-VFX-09 B: pink/gold stars pulled behind a step, or down/out by takeoff.
import {Rng,fit,scale,star} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
export const palette=["#4b2058","#973b9c","#dc68bc","#ffb0df","#ffe4a8","#fff9ed"];
function starlet(p,x,y,r,C,k,gold=false,turn=0,mixed=false) {
  p.poly(star(x,y,r*.4,r,5,-Math.PI/2+turn),mixed?(gold?C[4]:C[3]):scale(gold?C[4]:C[3],k),mixed?k:1);
  if(mixed)p.blend(x,y,C[5],k);else p.px(x,y,scale(C[5],k));
  p.glow(x,y,r+2,gold?C[4]:C[2],k*.26);
}
export function draw(p,t,o) {
  if(t>=o.duration)return;
  const C=fit(o.palette,6),q=t/o.duration,fade=Math.pow(Math.max(0,1-q/.96),1.65),step=o.kind==="step",air=o.kind==="air";
  // Normal-blend stardust must fade in alpha; dim opaque RGB turned the last stars black.
  const ink=air?p:Object.create(p);
  if(!air)ink.put=(sx,sy,c,a=1)=>p.blendPx(sx,sy,c,a);
  // Translucent little puffs stay low and trail left; no white disk over the boots.
  if(!air)for(let i=0;i<(step?3:5);i++) {
    const side=step?-1:i%2?1:-1;
    const x=side*(4+i*4+(1-Math.exp(-3*q))*(step?25:40)),y=-3-Math.sin(q*Math.PI)*(step?6:8);
    const r=(step?5:7)*(1+q*.45);
    p.disc(x,y,r,C[2],.5*fade);
    p.disc(x-1,y-2,r*.62,C[3],.24*fade);
  }
  for(let i=0;i<(step?9:air?17:14);i++) {
    const R=new Rng(o.seed+i*997),side=step?-1:i%3===0?1:-1;
    const life=o.duration*R.range(.86,1),u=t/life;if(u>=1)continue;
    const k=Math.pow(1-u,.85),x=side*(R.range(3,step?16:23)+R.range(step?32:43,step?76:86)*t);
    const y=air?R.range(4,15)+R.range(12,35)*t+44*t*t:-R.range(2,8)-R.range(16,36)*t+60*t*t;
    const yy=air?y:Math.min(-1,y);
    const r=R.range(2.8,step?4.4:5.8)*(1-u*.65);
    if(i%3!==2)starlet(ink,x,yy,r,C,k,i%3===0,u*.6,!air);
    else {
      ink.line(x-side*(step?5:9)*(1-u),yy-(air?3:0),x,yy,air?scale(C[i%2?3:4],k):C[i%2?3:4],air?1:k);
      if(air)p.px(x,yy,scale(C[5],k));else p.blend(x,yy,C[5],k);
    }
  }
  // Air jump: two broken descending wings, open centre; no halo around the body.
  if(air&&t<.3)for(const side of [-1,1]) {
    const k=1-t/.3;
    const pts=[[side*6,5+t*20],[side*20,10+t*27],[side*37,6+t*35]];
    p.polyline(pts,scale(C[3],k));
    p.polyline(pts.map(([x,y])=>[x,y+2]),scale(C[4],k*.7));
  }
}
