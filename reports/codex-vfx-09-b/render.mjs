import {readFileSync,writeFileSync,mkdirSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {bench} from "./bench-link.mjs";
import {specs,rootFor,metaFor} from "./bake-lib.mjs";
import {upscale} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/fxlib.mjs";
const {art,canvas,crop,blit,drawBody,drawStrip,realm,stripFrame,label,readPNG}=bench;
export const image=cv=>({w:cv.W,h:cv.H,data:cv.d});
export const zoom=(im,k)=>({w:im.w*k,h:im.h*k,data:upscale(im.data,im.w,im.h,k)});
export const playFps=s=>s.kind==="step"?s.frames*11.31/4:s.fps;
export const playDuration=s=>s.frames/playFps(s);
const out=new URL("./",import.meta.url),qa=new URL("qa/",out);
export const save=(file,cv)=>bench.savePNG(fileURLToPath(file),cv);
const cached=new Map();
export function sheet(s){if(!cached.has(s.id))cached.set(s.id,readPNG(new URL(`${s.id}-b.png`,rootFor(s))));return cached.get(s.id);}
export function body(s,t) {
  let name=s.family,col=0,row=0,cell=128,root=[64,120];
  if(s.family==="luna") {
    if(s.kind==="step") {const f=(3+Math.floor(t*11.31))%8;row=1+Math.floor(f/6);col=f%6;}
    else {const c=stripFrame(art("assets/art/luna/luna_jump.png"),3,Math.min(2,Math.floor(t*10)));c.root=root;return c;}
  } else if(s.kind==="hit") {name="luna";row=7;}
  else {
    const fps={upper:20.4,low:18,fly:19.2,dive:18}[s.kind];
    const busy=s.row===0?t<s.recovery:t<4/Math.min(20,fps);
    if(busy){row=s.row;col=s.row===0?s.strike:Math.min(5,2+Math.floor((t+.0005)*Math.min(20,fps)));cell=192;root=[96,152];}
    else if(['upper','fly','dive'].includes(s.kind))row=4;
    else col=Math.floor(Math.max(0,t-(s.row===0?s.recovery:4/Math.min(20,fps)))*5.36)%6;
  }
  const c=crop(art(`assets/art/luna/${name}${cell===192?"_moves":""}_sheet.png`),col*cell,row*cell,cell,cell);c.root=root;return c;
}
export function rotate(im,anchor,a,scaleX=1,scaleY=scaleX) {
  const w=Math.ceil(Math.hypot(im.w*scaleX,im.h*scaleY))*2+4,c={w,h:w,data:new Uint8ClampedArray(w*w*4)},o=[w>>1,w>>1];
  const cs=Math.cos(a),sn=Math.sin(a);
  for(let y=0;y<w;y++)for(let x=0;x<w;x++) {
    const dx=x-o[0],dy=y-o[1],sx=Math.round((dx*cs+dy*sn)/scaleX+anchor[0]),sy=Math.round((-dx*sn+dy*cs)/scaleY+anchor[1]);
    if(sx>=0&&sy>=0&&sx<im.w&&sy<im.h)c.data.set(im.data.subarray((sy*im.w+sx)*4,(sy*im.w+sx)*4+4),(y*w+x)*4);
  }
  return {im:c,anchor:o};
}
export function layout(s) {
  const m=metaFor(s),x0=Math.min(-80,-m.anchor[0]-7),y0=Math.min(-125,-m.anchor[1]-7),x1=Math.max(85,m.frame_size[0]-m.anchor[0]+7),y1=Math.max(45,m.frame_size[1]-m.anchor[1]+7);
  return {w:x1-x0,h:y1-y0,at:[-x0,-y0]};
}
export function panel(s,t,{existing=true,bright=false,flip=false,moving=false}={}) {
  const l=layout(s),cv=canvas(l.w,l.h),at=l.at,m=metaFor(s),isFeet=s.family==="luna";
  const floor=!['air','upper','fly','dive','hit'].includes(s.kind)?at[1]+(isFeet?0:32):null;
  realm(cv,bright?"asgard":"center",{sx:600,sy:420,floorY:floor});
  let fx=at[0],fy=at[1]+(isFeet?0:32);
  if(s.kind==="step")fx-=17;
  if(moving&&isFeet&&s.kind!=="step")fy-=Math.min(45,t*250);
  drawBody(cv,body(s,t),fx,fy,{flip});
  if(t<playDuration(s))drawStrip(cv,stripFrame(sheet(s),s.frames,Math.min(s.frames-1,Math.floor(t*playFps(s)+1e-7))),m.anchor,at,{mode:s.blend,flip});
  if(existing&&s.family==="luna_brave"&&s.kind!=="hit"&&t<6/36) {
    const a=s.aimDeg*Math.PI/180,im=stripFrame(art("assets/art/attack_vfx/luna_brave_slash.png"),6,Math.floor(t*36)),scale=Math.max(.5,Math.min(3,s.reach/224))/(im.w/224),q=rotate(im,[0,im.h/2],a,scale,scale*.62);
    drawStrip(cv,q.im,q.anchor,at,{mode:"add",flip});
  }
  if(existing&&s.kind==="hit"&&t<4/44) {
    const im=stripFrame(art("assets/art/effects/hit/luna_brave_hit.png"),4,Math.floor(t*44)),size=Math.max(24,Math.min(56,18+(s.big?10:5)*1.35+(s.big?520:150)*.035))*3,q=rotate(im,[48,48],0,size/96);
    drawStrip(cv,q.im,q.anchor,at,{flip});
  }
  return cv;
}
export function makeBoard() {
  const previews=specs.map(s=>{
    const t=s.id==="luna_step"?0:s.kind==="hit"?.15:.1,im=image(panel(s,t));
    const l=layout(s),vertical=s.kind==="upper"||s.kind==="dive";
    const cy=vertical?(s.kind==="upper"?l.at[1]-190:l.at[1]+65):s.family==="luna"?l.at[1]-30:l.at[1]-65;
    const cx=vertical?l.at[0]-65:s.kind==="hit"?l.at[0]-70:l.at[0]-15,cut=crop(im,cx,cy,155,vertical?180:110);
    return {s,t,im,cut,height:im.h+cut.h*4+110};
  });
  const heights=Array.from({length:6},(_,r)=>Math.max(previews[r*2].height,previews[r*2+1].height));
  const cv=canvas(1320,heights.reduce((a,b)=>a+b,0)+60,[18,18,27]);
  const title=canvas(650,20,[18,18,27]);
  label(title,"CODEX VFX 09 / B DIRECTIONAL LINGER / 12 STRIPS / BENCH COMPOSITE",5,4);
  blit(cv,zoom(image(title),2),10,5);
  let rowY=60;
  for(const [i,{s,t,im,cut}] of previews.entries()) {
    const x=i%2*660,y=rowY,heading=canvas(320,17,[18,18,27]);
    label(heading,`${s.id} / ${s.frames}F ${s.duration.toFixed(2)}S`,0,2);
    blit(cv,zoom(image(heading),2),x+10,y);
    label(cv,`NATIVE 1X / F${Math.floor(t*playFps(s)+1e-7)+1} / ${t.toFixed(2)}S`,x+10,y+36);
    blit(cv,im,x+10,y+50);
    label(cv,"EXACT 4X DETAIL / SAME FRAME / FULL FRAMES IN QA",x+10,y+im.h+64);
    blit(cv,zoom(cut,4),x+10,y+im.h+80);
    if(i%2===1)rowY+=heights[Math.floor(i/2)];
  }
  save(new URL("board.png",out),cv);
}
if(process.argv[1]&&new URL(`file:///${process.argv[1].replaceAll("\\","/")}`).href===import.meta.url) {
  if(process.argv.includes("--qa")) {
    mkdirSync(qa,{recursive:true});
    for(const s of specs) {
      const l=layout(s),cw=l.w*4+10,ch=l.h*4+28,per=s.kind==="dive"||s.kind==="upper"?2:4;
      for(let start=0;start<s.frames;start+=per) {
        const count=Math.min(per,s.frames-start),cv=canvas(cw*2,ch*Math.ceil(count/2),[18,18,27]);
        for(let j=0;j<count;j++) {
          const f=start+j,x=j%2*cw,y=Math.floor(j/2)*ch;
          label(cv,`${s.id} F${f+1}/${s.frames} ${(f/playFps(s)).toFixed(3)}S EXACT 4X`,x+5,y+7);
          blit(cv,zoom(image(panel(s,f/playFps(s))),4),x+5,y+22);
        }
        save(new URL(`${s.id}-${Math.floor(start/per)+1}.png`,qa),cv);
      }
      const cw1=l.w+10,ch1=l.h+24,cv1=canvas(cw1*4,ch1*Math.ceil(s.frames/4),[18,18,27]);
      for(let f=0;f<s.frames;f++){
        const x=f%4*cw1,y=Math.floor(f/4)*ch1;
        label(cv1,`${s.id} F${f+1} ${(f/playFps(s)).toFixed(3)}S 1X`,x+4,y+6);
        blit(cv1,image(panel(s,f/playFps(s))),x+4,y+20);
      }
      save(new URL(`${s.id}-1x.png`,qa),cv1);
    }
  }
  makeBoard();console.log("Board rendered.");
}
