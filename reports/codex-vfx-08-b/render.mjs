import {readFileSync,mkdirSync,writeFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {bench} from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
import {specs,rootFor} from "./bake-lib.mjs";
import {upscale} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/fxlib.mjs";
const {art,canvas,blit,crop,drawBody,drawStrip,realm,stripFrame,label,readPNG}=bench;
const savePNG=(file,cv)=>bench.savePNG(fileURLToPath(file),cv);
const OUT=new URL("./",import.meta.url),QA=new URL("qa/",OUT);mkdirSync(QA,{recursive:true});
const metrics=JSON.parse(readFileSync(new URL("measurements.json",OUT),"utf8")).measurements;
const image=cv=>({w:cv.W,h:cv.H,data:cv.d});
const zoom=(im,k)=>({w:im.w*k,h:im.h*k,data:upscale(im.data,im.w,im.h,k)});
const load=s=>readPNG(new URL(`${s.id}-b.png`,rootFor(s)));
export function body(family,motion,t) {
  if(family==="frey"&&["jump","land"].includes(motion)) {
    const n=motion==="jump"?3:2,fps=motion==="jump"?10:12;
    const c=stripFrame(art(`assets/art/frey/frey_${motion}.png`),n,Math.min(n-1,Math.floor(Math.max(0,t)*fps)));c.root=[64,120];return c;
  }
  const sheet=art(`assets/art/${family}/${family}_sheet.png`),row=motion==="hurt"?7:0;
  const c=crop(sheet,motion==="hurt"?0:Math.floor(t*6.3)%6*128,row*128,128,128);c.root=[64,120];return c;
}
// Inverse mapping for nearest-neighbour rotation at a real game scale; candidates always stay at 1x.
export function rotate(im,anchor,a,scale=1) {
  const w=Math.ceil(Math.hypot(im.w,im.h)*scale)+4,out={w,h:w,data:new Uint8ClampedArray(w*w*4)},o=[Math.floor(w/2),Math.floor(w/2)];
  for(let y=0;y<w;y++)for(let x=0;x<w;x++) {
    const dx=(x-o[0])/scale,dy=(y-o[1])/scale,sx=Math.round(dx*Math.cos(a)+dy*Math.sin(a)+anchor[0]),sy=Math.round(-dx*Math.sin(a)+dy*Math.cos(a)+anchor[1]);
    if(sx>=0&&sy>=0&&sx<im.w&&sy<im.h)out.data.set(im.data.subarray((sy*im.w+sx)*4,(sy*im.w+sx)*4+4),(y*w+x)*4);
  }
  return {im:out,anchor:o};
}
const cached=new Map();
export function fx(cv,s,t,at,angle=0) {
  if(!s.loop&&t>=s.duration)return;
  const n=Math.round(s.duration*20),i=Math.floor(Math.max(0,t)*20+1e-6)%n;
  const key=s.id+":"+i+":"+angle;
  if(!cached.has(key)) {const im=stripFrame(load(s),n,i);cached.set(key,angle?rotate(im,s.origin,angle):{im,anchor:s.origin});}
  const q=cached.get(key);drawStrip(cv,q.im,q.anchor,at,{mode:s.blend});
}
export function star(cv,big,t,at,angle=0,scale=1) {
  const im=stripFrame(art(`assets/art/effects/luna_star_${big?"big":"shot"}.png`),4,Math.floor(t*16)%4),q=rotate(im,[im.w/2,im.h/2],angle,scale);
  drawStrip(cv,q.im,q.anchor,at);
}
export function panel(s,t,{moving=false,angle=0,starScale=1,bright=false,existing=true}={}) {
  const distance=moving&&s.kind==="trail"?t*(s.big?930:1050):0;
  const cv=canvas(248,184);realm(cv,bright?"asgard":"center",{sx:600+Math.round(distance),sy:420,floorY:s.family==="frey"&&s.kind!=="air"?153:null});
  if(s.family==="frey") {
    const jump=s.kind==="jump"||s.kind==="air",motion=jump?"jump":t<2/12?"land":"idle";
    // Inspection stays registered to the feet; motion preview uses a bounded illustrative takeoff.
    const lift=moving&&jump?Math.min(45,Math.max(0,270*t-240*t*t)):0,fy=jump?132:153;
    drawBody(cv,body("frey",motion,t),121,fy-lift);fx(cv,s,t,[121,fy]);
  } else if(s.kind==="hit") {
    const target=body("frey","hurt",t),at=[111,111];drawBody(cv,target,at[0],at[1]+32);
    fx(cv,s,t,at);
    if(existing&&t<4/44) {
      const hit=stripFrame(art("assets/art/effects/hit/luna_hit.png"),4,Math.min(3,Math.floor(t*44))),damage=s.big?2:3,kb=s.big?90:120;
      const size=Math.max(24,Math.min(56,18+damage*1.35+kb*.035))*1.5*2;
      const q=rotate(hit,[hit.w/2,hit.h/2],0,size/hit.h);drawStrip(cv,q.im,q.anchor,at);
    }
    if(existing&&s.big&&t<6/42.857) {
      const burst=stripFrame(art("assets/art/effects/skill/luna_comet_burst.png"),6,Math.min(5,Math.floor(t*42.857))),q=rotate(burst,[112,112],0,1.25);
      drawStrip(cv,q.im,q.anchor,at,{mode:"add"});
    }
  } else {
    const movingTrail=s.kind==="trail",launchX=movingTrail?189:119,at=[launchX,112];
    // Body is a genuine adopted star_side cell (row 7, the transform uses two rows).
    const sheet=art("assets/art/luna/luna_moves_sheet.png"),col=t<.23?Math.min(5,2+Math.floor(t*17.85)):0;
    let c=t<.23?crop(sheet,col*192,7*192,192,192):body("luna","idle",t);if(t<.23)c.root=[96,184];
    drawBody(cv,c,movingTrail?45-distance:74,150);
    fx(cv,s,t,at,angle);
    // At fixed registration the actual star remains on its anchor; moving previews scroll with it.
    const travel=movingTrail?0:t*(s.big?930:1050);
    if(movingTrail||t<(s.big?.36:.3))star(cv,!!s.big,t,[at[0]+Math.cos(angle)*travel,at[1]+Math.sin(angle)*travel],angle,starScale);
  }
  return cv;
}
// Full-frame inspection: six consecutive effect frames per page, each at native 1x and exact 4x.
if(!process.argv.includes("--library")) {
if(!process.argv.includes("--board-only"))for(const s of specs.filter(s=>(!process.argv.includes("--frey-only")||s.family==="frey")&&(!process.argv.includes("--luna-flight-only")||s.family==="luna"&&s.kind!=="hit"))) {
  const n=Math.round(s.duration*20),pages=Math.ceil(n/6);
  for(let page=0;page<pages;page++) {
    const count=Math.min(6,n-page*6),cols=2,rows=Math.ceil(count/cols),w=1000,h=946;
    const sheet=canvas(cols*w,rows*h,[20,19,28]);
    for(let k=0;k<count;k++) {
      const i=page*6+k,cv=panel(s,i/20),x=k%cols*w,y=Math.floor(k/cols)*h;
      label(sheet,`${s.id}  F${i+1}/${n}  ${(i/20).toFixed(2)}S`,x+8,y+8);
      blit(sheet,image(cv),x+8,y+22);
      blit(sheet,zoom(image(cv),4),x+4,y+208);
    }
    savePNG(new URL(`${s.id}-${page+1}.png`,QA),sheet);
  }
}
// Compact delivery board: native composition and a genuine 4x crop of the peak effect.
const board=canvas(1280,5*500+32,[18,17,25]);label(board,"CODEX VFX 08 / B / DIRECTIONAL LINGER / 1X + 4X DETAIL",12,10);
specs.forEach((s,i)=>{
  const m=metrics.find(m=>m.id===s.id),shown=s.kind==="hit"?.15:m.peak_time,cv=panel(s,shown),x=i%2*640,y=32+Math.floor(i/2)*500;
  label(board,`${s.id}  ${s.duration.toFixed(2)}S  PEAK F${m.peak_frame}`,x+12,y+8);
  label(board,`PAINT ${m.painted_size.join("X")} / FIRST F1 / SHOWN F${Math.round(shown*20)+1}`,x+12,y+21);
  blit(board,image(cv),x+12,y+40);label(board,"1X",x+12,y+228);
  const cut=s.family==="frey"?crop(image(cv),43,95,160,64):crop(image(cv),43,75,160,64);
  blit(board,zoom(cut,4),x,y+244);label(board,"4X DETAIL",x+12,y+480);
});
savePNG(new URL("board.png",OUT),board);
// Every phase of both trail loops while a star moves at the game's speed. Camera follows star.
for(const s of specs.filter(s=>s.kind==="trail")) {
  const n=Math.round(s.duration*20),sheet=canvas(1000,Math.ceil(n/2)*400,[20,19,28]);
  for(let i=0;i<n;i++) {
    const cv=panel(s,i/20,{moving:true}),x=i%2*500,y=Math.floor(i/2)*400;
    label(sheet,`${s.id} F${i+1} DIST ${Math.round(i/20*(s.big?930:1050))}PX`,x+8,y+8);
    blit(sheet,zoom(image(cv),2),x,y+24);
  }
  savePNG(new URL(`${s.id}-motion.png`,OUT),sheet);
}
console.log("Rendered board and all-frame 1x/4x QA sheets.");
}
