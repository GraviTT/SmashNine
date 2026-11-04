// CODEX-VFX-08 B. Analytic downwash and floor-skimming feather dust.
// The pixelfx checkout is imported read-only. Coordinates are native screen pixels.
import { Rng, fit, scale } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
export const palette = ["#63452f", "#a67c45", "#dcb66d", "#f7db99", "#fff3ce", "#ffffff"];
const clamp = x => Math.max(0, Math.min(1, x));

function feather(p, x, y, len, angle, C, k, mixed=false) {
  const dx = Math.cos(angle), dy = Math.sin(angle);
  if(mixed) {
    // Normal blend fades alpha, not RGB: dying feathers must not turn into dark opaque grit.
    const radius=Math.ceil(len*.65);
    for(let yy=-radius;yy<=radius;yy++)for(let xx=-radius;xx<=radius;xx++) {
      const u=xx*dx+yy*dy,v=-xx*dy+yy*dx,w=2.8*Math.max(0,1-Math.abs(u)/(len*.6));
      if(Math.abs(u)>len*.6||Math.abs(v)>Math.max(.55,w))continue;
      const c=Math.abs(v)<.6?C[5]:v<0?C[3]:Math.floor(u+len)%3===0?C[1]:C[2];
      p.blend(x+xx,y+yy,c,k);
    }
    p.glow(x,y,5,C[2],.18*k);
    return;
  }
  const at = (u, v) => [x + dx * u - dy * v, y + dy * u + dx * v];
  const pts = [[-len * .55, 0], [-len * .15, -2.1], [len * .36, -1.8], [len * .58, 0], [len * .1, 2.6]].map(([u,v])=>at(u,v));
  p.poly(pts, scale(C[3], k));
  p.line(...at(-len * .55, 0), ...at(len * .5, 0), scale(C[5], k));
  for (const u of [-.23, .04, .28]) p.line(...at(len*u, 0), ...at(len*(u-.13), 1.7), scale(C[1], k));
  p.glow(x, y, 5, C[2], .22*k);
}

export function drawMotion(p, t, o) {
  if (t >= o.duration) return;
  const C = fit(o.palette, 6), q = t/o.duration;
  const air = o.kind === "air", jump = air || o.kind === "jump", big = o.big;
  const reach = big ? 91 : air ? 64 : jump ? 62 : 59;
  // Layered translucent puffs travel out along the floor. Air jump uses light feathers only.
  if (!air) for (const side of [-1, 1]) for (let i=0;i<(big?5:3);i++) {
    const R = new Rng(o.seed+101+i*997+side*31);
    const life = o.duration * R.range(.72, 1), age = t + .025;
    if(age>=life) continue;
    const a=age/life, push=1-Math.exp(-a*3.2);
    const x=side*(8+push*(reach-20)*R.range(.7,1.05)) + (jump?-4:9)*a;
    const ry=(big?7:5)+a*(big?5:3), rx=ry*(1.5+.4*a);
    const y=jump?1+a*6:-2-ry*.4-Math.sin(a*Math.PI)*R.range(1,4);
    const alpha=.57*Math.pow(1-a,1.12);
    for(let yy=-Math.ceil(ry);yy<=ry;yy++)for(let xx=-Math.ceil(rx);xx<=rx;xx++) {
      const d=Math.hypot(xx/rx,yy/ry);
      if(d<1) p.blend(x+xx,y+yy, yy < -ry*.22 ? C[3] : C[1], alpha*Math.pow(1-d*d,.7));
    }
  }
  // First-frame foot accents are already spread, so there is no invisible spawn frame.
  if(t<.14)for(const side of [-1,1]) {
    const a=1-t/.14, x0=side*7, x1=side*(20+t*105);
    p.line(x0,-2,x1,jump?4:-2,scale(C[4],a*.8));
    p.line(x0,-1,x1,jump?5:0,scale(C[2],a*.65));
  }
  // Feather vanes fan down at launch; landings sweep sideways close to the floor.
  for(let i=0;i<(big?8:air?8:jump?6:4);i++) {
    const R = new Rng(o.seed+211+i*997);
    const side=i%2?1:-1, life=o.duration*R.range(.75,1.03);
    if(t>=life)continue;
    const a=t/life, eased=1-Math.exp(-3.4*a), k=Math.pow(1-a,.65);
    const spread=Math.floor(i/2)*4;
    const x=side*(12+spread+eased*(reach-23-spread)*R.range(.58,1))+(jump?-7:7)*a;
    const y=jump?2+i%3*4+eased*R.range(air?12:8,air?25:15)+Math.sin(a*5+i)*2:-3-i%3*3-Math.sin(a*Math.PI)*R.range(6,big?19:12)+a*5;
    const angle=jump?side*(.15+i%3*.22)+.3*Math.sin(a*5+i):side*.12+.25*Math.sin(a*4+i);
    feather(p,x,y,(big?13:air?12:10)*(1-a*.4),angle,C,k,!air);
  }
  for(let i=0;i<(big?18:12);i++) {
    const R = new Rng(o.seed+311+i*997);
    const side=i%2?1:-1, life=o.duration*R.range(.48,.93);
    if(t>=life)continue;
    const a=t/life, x=side*(8+(1-Math.exp(-a*2.8))*R.range(25,reach-5));
    const y=jump?2+a*R.range(8,air?34:21):-2-Math.sin(a*Math.PI)*R.range(4,big?22:13);
    const k=Math.pow(1-a,.8), c=scale(i%3?C[3]:C[5],k);
    if(air)p.line(x-side*(2+3*(1-a)),y,x,y+(jump?1:0),c);
    else for(let d=0;d<2+3*(1-a);d++)p.blend(x-side*d,y+(jump?d*.2:0),i%3?C[3]:C[5],k);
    if(i%4===0)p.glow(x,y,4,C[2],.3*k);
  }
}
