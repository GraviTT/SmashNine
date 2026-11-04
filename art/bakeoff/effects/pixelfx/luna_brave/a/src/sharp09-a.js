// CODEX-VFX-09 A: sharp contact, distinct stars for feet, fists and kicks.
// Pure trajectories keep gravity in world-down coordinates and have no floor collision.
import {fit,scale,star} from 'file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js';
export const palettes={main:['#803286','#be4f9f','#f17cbd','#ffc7e6','#fff3fa','#ffffff'],gold:['#a76721','#ebac3e','#ffdc78','#fff3be','#ffffff']};
function ray(p,x,y,dx,dy,w,c,hot){const len=Math.hypot(dx,dy)||1,nx=-dy/len*w,ny=dx/len*w;p.poly([[x-nx,y-ny],[x+nx,y+ny],[x+dx,y+dy]],c);p.line(x,y,x+dx*.75,y+dy*.75,hot);}
function glint(p,x,y,r,C,k,turn=0){if(r<.65||k<.04)return;p.poly(star(x,y,r*.43,r,5,-Math.PI/2+turn),scale(C[2],k));p.poly(star(x-.4,y-.5,r*.25,r*.63,5,-Math.PI/2+turn),scale(C.at(-1),k));p.glow(x,y,r*1.25,C[2],.27*k);}
export function drawSharp(p,t,o,D){
  if(t>=D-1e-8)return;
  const q=t/D,C=fit(o.palette,6),G=fit(o.gold,5),fade=.2+.8*(1-q)**2,spread=1-(1-q)**3;
  if(o.kind==='step'){
    // Contact stays near the toe. Everything else trails toward -x.
    if(q<.58){ray(p,-3,-2,-18*(1-q),-3,1.6*(1-q),scale(C[2],fade),scale(C[5],fade));ray(p,1,-2,6*(1-q),-4,1.4*(1-q),scale(G[2],fade),scale(G[4],fade));}
    for(let i=0;i<3;i++){const x=-9-i*13-spread*(9+i*3),y=-4-i*2-Math.sin(q*Math.PI)*(4+i*2),r=(i===0?4.9:3.7)*(1-q*.98);glint(p,x,y,r,i===1?G:C,fade,-q*.4);}
    return;
  }
  if(o.kind==='jump'||o.kind==='air'){
    const air=o.kind==='air';
    for(let i=0;i<(air?5:4);i++){
      const side=i%2?1:-1,lane=Math.floor(i/2),x=side*(17+lane*19+spread*(10+lane*4)),y=air?9+lane*9+q*16+q*q*10:-2+lane*4+q*10;
      const radius=(air?7.6:6.4)*(1-q*.97);glint(p,x,y,radius,i%3===0?G:C,fade,side*q*.5);
      if(q<.65)ray(p,x,y,side*(air?16:19)*(1-q),air?10*(1-q):3,1.8*(1-q),scale(C[2],fade),scale(G[4],fade));
    }
    if(!air&&q<.3)for(const side of [-1,1])ray(p,side*7,1,side*18*(1-q),-2,1.2,scale(C[2],fade),scale(C[5],fade));
    return;
  }
  if(o.kind.startsWith('hit')){
    const big=o.kind==='hit_big',n=big?6:4;
    for(let i=0;i<n;i++){
      const side=i%2?1:-1,lane=Math.floor(i/2),x=side*((big?52:42)+spread*(big?36:25)),y=-12+lane*23+t*12+t*t*80;
      glint(p,x,y,(big?9:6.5)*(1-q*.96),i%3===1?C:G,fade,side*q*.5);
      if(q<.64)ray(p,x+side*5,y,side*(big?20:14)*(1-q),(lane-1)*7*(1-q),2*(1-q),scale(C[2],fade),scale(G[4],fade));
    }
    return;
  }
  const a=o.aim*Math.PI/180,dx=Math.cos(a),dy=Math.sin(a),nx=-dy,ny=dx,R=o.reach;
  const strong=['spin','upper','dive'].includes(o.kind),n=strong?3:2,base=o.kind==='upper'?.83:o.kind==='dive'?.65:.70;
  const offsetY=o.kind==='low'?21:0;
  // Separate radial points, not another filled slash. Uppercut points live above the head zone.
  for(let i=0;i<n;i++){
    const lane=i-(n-1)/2,along=R*(base+i*.075)+spread*12,across=lane*(strong?22:o.kind==='low'?10:18);
    const x=dx*along+nx*across,y=dy*along+ny*across+offsetY+t*10+t*t*95;
    glint(p,x,y,(strong?8.5:6.2)*(1-q*.97),i%2?C:G,fade,q*(i%2?-.6:.6));
    if(q<.6){const len=(strong?28:22)*(1-q);ray(p,x-dx*4,y-dy*4,dx*len+nx*lane*9,dy*len+ny*lane*9,(strong?2.4:1.8)*(1-q),scale(C[2],fade),scale(G[4],fade));}
    if(q<.35)for(const sign of [-1,1])ray(p,x,y,nx*sign*12*(1-q),ny*sign*12*(1-q),1.2,scale(C[2],fade),scale(C[5],fade));
  }
  // Just a few sparks fall away; gravity is applied after the local attack direction.
  for(let i=0;i<3;i++){
    const age=t,along=R*(base+i*.09)+age*(24+i*8),off=(i-1)*(strong?21:16);
    const x=dx*along+nx*off+age*(i-1)*15,y=dy*along+ny*off+offsetY+age*20+age*age*150;
    if(q<.86){p.line(x,y,x-dx*3*(1-q),y-dy*3*(1-q)-2,scale(i%2?C[3]:G[3],fade));}
  }
}
