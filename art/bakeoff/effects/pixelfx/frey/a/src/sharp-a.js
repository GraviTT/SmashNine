// CODEX-VFX-08 A: a flash, a steel edge, then feather vanes; feet-relative.
// Pure, deterministic pixelfx geometry. The shared pixelfx checkout is read-only.
import { fit, scale, ease } from 'file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js';
export const palettes = { main:['#735134','#bd8235','#f2ba60','#ffe7a2','#fff9df','#ffffff'], gold:['#967044','#e1aa58','#fff0ba','#ffffff'] };
function ray(p,x,y,dx,dy,w,c,hot) {
  const d=Math.hypot(dx,dy)||1, nx=-dy/d*w,ny=dx/d*w;
  p.poly([[x-nx,y-ny],[x+nx,y+ny],[x+dx,y+dy]],c);
  p.line(x,y,x+dx*.8,y+dy*.8,hot);
}
function feather(p,x,y,length,angle,C,k) {
  const u=[Math.cos(angle),Math.sin(angle)], v=[-u[1],u[0]], w=length*.14;
  const pt=(a,b)=>[x+u[0]*a+v[0]*b,y+u[1]*a+v[1]*b];
  p.poly([pt(-length*.48,0),pt(-length*.15,-w),pt(length*.24,-w*.7),pt(length*.54,0),pt(length*.1,w),pt(-length*.3,w*.55)],scale(C[2],k));
  const a=pt(-length*.4,0),b=pt(length*.5,0);
  p.line(...a,...b,scale(C[5],k));
  for(const q of [-.22,0,.22]) {
    p.line(...pt(length*q,0),...pt(length*(q-.14),-w*.7),scale(C[3],k));
  }
}
export function drawEffect(p,t,o,D) {
  if(t>=D-1e-8)return;
  const C=fit(o.palette,6), q=t/D, air=o.kind==='air', jump=o.kind==='jump'||air, big=o.kind==='land_big';
  const spread=ease.outCubic(Math.min(1,q/.85)), fade=.18+.82*Math.pow(1-q,1.8), extent=air?64:big?86:jump?53:56;
  const hot=scale(C[5],fade), gold=scale(C[2],fade);
  // First two frames: bright but flat at the feet, no torso fill.
  if(t<.075) {
    const k=1-t/.085, width=(big?36:air?26:22)*(1+t*4);
    ray(p,-3,-1,-width+3,-2,1.5*k,scale(C[3],k),scale(C[5],k));
    ray(p,3,-1,width-3,1,1.5*k,scale(C[3],k),scale(C[5],k));
    ray(p,-3,0,-8,-(big?12:7),1.6*k,scale(C[2],k),scale(C[5],k));
    ray(p,3,0,9,-(big?11:6),1.6*k,scale(C[2],k),scale(C[5],k));
    p.glow(0,-1,big?19:13,C[3],.42*k);
    if(jump)ray(p,0,2,0,air?14:9,2*k,scale(C[3],k),scale(C[5],k));
  }
  for(const side of [-1,1]) {
    const count=air?3:big?4:3;
    for(let i=0;i<count;i++) {
      const u=(i+1)/count, r=12+i*3+(extent-12-i*3)*spread*(.72+.28*u);
      const x=side*r, y=jump?(air?6:1)+i*4+spread*(i*4+3): -3-i*3-spread*(i*5+(big?4:0));
      const dx=side*(10+10*(1-q))*(.65+.3*u),dy=jump?5+i*1.5:-(1+i*2);
      if(q<.7)ray(p,x-dx,y-dy,dx,dy,(big?2.0:1.3)*(1-q),gold,hot);
      if((jump&&i<(air?3:2))||(big&&i===2))feather(p,x,y,(air?18:big?16:13)*(1-q*.95),side<0?-.3+q:.3-q,C,fade);
      else {
        p.line(x,y,x+side*3*(1-q),y-1,hot);
        if(q<.5)p.glow(x,y,4,C[2],.45*fade);
      }
    }
    // Broken floor/contact line: an angular slash, not a persistent ring.
    if(!air&&q<.65) {
      const r=8+spread*(big?70:45);
      p.line(side*(r-14*(1-q)),2,side*r,1,scale(C[3],fade));
      p.line(side*(r+3),1,side*(r+7),0,scale(C[2],fade));
    }
  }
}
