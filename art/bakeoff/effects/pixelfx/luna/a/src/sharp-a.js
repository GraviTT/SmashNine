// CODEX-VFX-08 A: separate launch, moving-star trail and impact ornaments.
// No central haze; the projectile and struck body's centre stay clear.
import { fit, scale, star, TAU } from 'file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js';
export const palettes = {main:['#733083','#bd53ac','#f48dcc','#ffd0ed','#fff6fb','#ffffff'],gold:['#a86b24','#edb643','#ffdf84','#fff9cf','#ffffff']};
function ray(p,x,y,dx,dy,w,c,hot) {
  const d=Math.hypot(dx,dy)||1,nx=-dy/d*w,ny=dx/d*w;
  p.poly([[x-nx,y-ny],[x+nx,y+ny],[x+dx,y+dy]],c);
  p.line(x,y,x+dx*.75,y+dy*.75,hot);
}
function littleStar(p,x,y,r,C,G,k,gold=false,turn=0) {
  if(r<.6||k<.055)return;
  const ramp=gold?G:C;
  p.poly(star(x,y,r*.42,r,5,-Math.PI/2+turn),scale(ramp[2],k));
  p.poly(star(x-.3,y-.4,r*.24,r*.61,5,-Math.PI/2+turn),scale(ramp[ramp.length-1],k));
  p.glow(x,y,r*1.35,ramp[2],.35*k);
}
export function drawEffect(p,t,o,D) {
  const loop=o.kind.startsWith('trail'),big=o.kind.endsWith('big'),C=fit(o.palette,6),G=fit(o.gold,5);
  if(!loop&&t>=D-1e-8)return;
  const q=loop?((t/D)%1+1)%1:t/D,fade=.18+.82*Math.pow(1-q,1.8);
  if(loop) {
    // Full-period phase-shifted emissions. Zero-size at birth/death, no seam reset.
    const count=big?4:3, start=big?34:20, length=big?91:67;
    for(let i=0;i<count;i++) {
      const age=(q+i/count)%1,k=Math.pow(Math.sin(Math.PI*age),.9),x=-start-length*age;
      const y=Math.sin(age*Math.PI*1.5+i*2.1)*(big?13:9);
      const radius=(big?5.2:3.7)*k;
      littleStar(p,x,y,radius,C,G,k,big&&i%2===0,.15*i);
      if(k>.14)ray(p,x-3,y,-(big?17:12)*k,0,.9*k,scale(C[1],k*.7),scale(big?G[2]:C[3],k*.85));
    }
    // Thin detached shoulder glints, never a solid beam or a new projectile silhouette.
    const pulse=.65+.35*Math.cos(q*TAU);
    for(const side of [-1,1])ray(p,-start-2,side*(big?12:8),-12,side*2,1,scale(C[1],pulse),scale(C[3],pulse));
    return;
  }
  if(o.kind.startsWith('launch')) {
    const n=big?7:5,spread=1-Math.pow(1-q,3),r0=big?17:11;
    for(let i=0;i<n;i++) {
      const a=-1.35+i*2.7/(n-1),r=r0+spread*(big?18:12),x=Math.cos(a)*r,y=Math.sin(a)*r;
      ray(p,x,y,Math.cos(a)*(big?19:13)*(1-q),Math.sin(a)*(big?11:8)*(1-q),(big?2.5:1.9)*(1-q),scale(big?G[2]:C[2],fade),scale(C[5],fade));
    }
    for(const s of [-1,1])littleStar(p,(big?8:5)+q*10,s*((big?21:15)+q*9),(big?5:3.8)*(1-q),C,G,fade,big,s*q*.2);
    return;
  }
  // Impact afterglow: all bright material starts outside the torso's central 44px.
  const spread=1-Math.pow(1-q,3),n=big?6:4;
  for(let i=0;i<n;i++) {
    const side=i%2?1:-1, lane=Math.floor(i/2),x=side*((big?34:27)+spread*(big?37:24));
    const y=lane===0?-13+q*4:lane===1?12+spread*7:30+spread*4;
    const k=fade*(lane===2?.9:1),r=(big?7.5:5.4)*(1-q*.95);
    littleStar(p,x,y,r,C,G,k,big||i===1,side*q*.7);
    if(q<.6)ray(p,x+side*5,y,side*(big?15:11)*(1-q),lane===0?-3:3,1.5*(1-q),scale(C[2],k),scale(C[5],k));
  }
}
