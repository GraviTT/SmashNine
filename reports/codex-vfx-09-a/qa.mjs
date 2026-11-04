import {mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {specs} from './specs.mjs';
import {art,readPNG,crop,stripFrame,canvas,blit,drawBody,drawStrip,realm,label} from '../codex-vfx-08-a/bench.mjs';
import {encodePNG} from './fast-png.mjs';
import {encodeAPNG} from '../codex-vfx-08-a/apng.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)),out=fileURLToPath(new URL('./',import.meta.url));
mkdirSync(resolve(out,'qa'),{recursive:true});
const img=cv=>({w:cv.W,h:cv.H,data:cv.d});
function savePNG(path,cv,k=1){const r=k===1?img(cv):resize(img(cv),k);writeFileSync(path,encodePNG(r.w,r.h,r.data));}
export function resize(im,k,ky=k){const w=Math.round(im.w*k),h=Math.round(im.h*ky),data=new Uint8ClampedArray(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++){const j=(Math.min(im.h-1,Math.floor(y/ky))*im.w+Math.min(im.w-1,Math.floor(x/k)))*4;data.set(im.data.subarray(j,j+4),(y*w+x)*4);}return{w,h,data};}
function place(cv,im,anchor,at,angle=0,mode='add',alpha=1){
 if(!angle){drawStrip(cv,im,anchor,at,{mode,alpha});return;}
 const r=Math.ceil(Math.hypot(im.w,im.h)),w=r*2+1,data=new Uint8ClampedArray(w*w*4),co=Math.cos(angle),si=Math.sin(angle);
 for(let y=0;y<w;y++)for(let x=0;x<w;x++){const u=x-r,v=y-r,sx=Math.round(u*co+v*si+anchor[0]),sy=Math.round(-u*si+v*co+anchor[1]);if(sx>=0&&sy>=0&&sx<im.w&&sy<im.h)data.set(im.data.subarray((sy*im.w+sx)*4,(sy*im.w+sx)*4+4),(y*w+x)*4);}
 drawStrip(cv,{w,h:w,data},[r,r],at,{mode,alpha});
}
export const assets=new Map(specs.map(s=>{const base=resolve(repo,`art/bakeoff/effects/pixelfx/${s.char}/a/${s.name}-a`);return[s.name,{meta:JSON.parse(readFileSync(base+'.json','utf8')),strip:readPNG(base+'.png')}];}));
function body(s,t,secondStep=false){
 let b;
 if(s.kind==='step'){const col=((secondStep?7:3)+Math.floor(t*11.31))%8;b=crop(art('assets/art/luna/luna_sheet.png'),col%6*128,(1+Math.floor(col/6))*128,128,128);b.root=[64,120];}
 else if(s.char==='luna'){b=stripFrame(art('assets/art/luna/luna_jump.png'),3,Math.min(2,Math.floor(t*10)));b.root=[64,120];}
 else if(s.kind.startsWith('hit')){b=stripFrame(art('assets/art/luna/luna_brave_hurt.png'),3,Math.min(2,Math.floor(t*12)));b.root=[64,120];}
 else{const col=s.row===0?s.pose:Math.min(5,s.pose+Math.floor(t*s.bodyFps));b=crop(art('assets/art/luna/luna_brave_moves_sheet.png'),col*192,s.row*192,192,192);b.root=[96,152];}
 return b;
}
const blooms={jab:[68,-34,24,.1],kick:[78,-22,27,.11],spin:[88,-30,35,.14],upper:[42,-106,31,.13],low:[80,-8,28,.12],flying:[92,-28,29,.12],dive:[46,74,32,.13]};
export function scene(s,t,{baseline=false,onlyCandidate=false,background='midgard',move=false,flip=false,secondStep=false}={}){
 const upper=s.kind==='upper',dive=s.kind==='dive',W=280,H=upper?300:dive?340:s.kind==='air'?220:172,cv=canvas(W,H),fx=s.char==='luna'||s.kind.startsWith('hit')?140:upper||dive?110:65,fy=upper?270:dive?116:140;
 realm(cv,background,{sx:600,sy:510,floorY:fy,platform:!['upper','dive','flying','air'].includes(s.kind)});
 const feet=[fx,fy],at=s.kind==='step'?[fx+(secondStep?18:17),fy]:s.char==='luna'?feet:[fx,fy-32];
 const bloom=blooms[s.kind];
 if(bloom&&!onlyCandidate&&t<bloom[3]){
  const raw=stripFrame(art('assets/art/effects/skill/luna_star_bloom.png'),6,Math.min(5,Math.floor(t*6/bloom[3]))),k=bloom[2]*1.5*2.5/204/(raw.w/256),im=resize(raw,k);
  place(cv,im,[im.w/2,im.h/2],[fx+bloom[0]*1.5,fy-32+(bloom[1]+32)*1.5],0,'add',.72);
 }
 const bt=body(s,t,secondStep),lift=move&&['jump','air'].includes(s.kind)?Math.min(80,t*230):0;
 drawBody(cv,bt,fx+(move&&s.kind==='step'?t*140:0),fy-lift);
 if(s.reach&&!onlyCandidate&&t<6/36){
  const raw=stripFrame(art('assets/art/attack_vfx/luna_brave_slash.png'),6,Math.floor(t*36)),k=s.reach/raw.w,im=resize(raw,k,k*.62);
  place(cv,im,[0,im.h/2],at,s.aim*Math.PI/180);
 }
 if(s.kind.startsWith('hit')&&!onlyCandidate&&t<4/44){
  const big=s.kind==='hit_big',sparkSize=Math.min(56,18+(big?10:5)*1.35+(big?520:150)*.035)*1.5,raw=stripFrame(art('assets/art/effects/hit/luna_brave_hit.png'),4,Math.floor(t*44)),im=resize(raw,sparkSize*2/raw.h);
  place(cv,im,[im.w/2,im.h/2],at,0,'mix');
 }
 if(!baseline){const {strip,meta}=assets.get(s.name),duration=s.kind==='step'?4/11.31:s.frames/s.fps,frame=Math.floor(t/duration*s.frames+1e-6);if(frame<s.frames)drawStrip(cv,stripFrame(strip,s.frames,frame),meta.anchor,at,{mode:'add'});}
 if(flip){const reflected=canvas(W,H);blit(reflected,img(cv),0,0,{flip:true});return reflected;}
 return cv;
}
const measurements=[];
for(const s of specs){
 const {strip,meta}=assets.get(s.name),perFrame=[];let border=0,alphaBad=0,dim=0;
 for(let n=0;n<s.frames;n++){
  const f=stripFrame(strip,s.frames,n);let loX=Infinity,loY=Infinity,hiX=-Infinity,hiY=-Infinity,count=0,energy=0;
  for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++){const i=(y*f.w+x)*4,a=f.data[i+3],v=Math.max(f.data[i],f.data[i+1],f.data[i+2]);if(a!==0&&a!==255)alphaBad++;if(!a)continue;count++;energy+=v;if(v<40)dim++;if(x===0||y===0||x===f.w-1||y===f.h-1)border++;loX=Math.min(loX,x);loY=Math.min(loY,y);hiX=Math.max(hiX,x);hiY=Math.max(hiY,y);}
  perFrame.push({frame:n+1,time:n/s.fps,pixels:count,energy,bounds:count?[loX-meta.anchor[0],loY-meta.anchor[1],hiX-meta.anchor[0],hiY-meta.anchor[1]]:null});
 }
 const painted=perFrame.filter(f=>f.bounds),bounds=[Math.min(...painted.map(f=>f.bounds[0])),Math.min(...painted.map(f=>f.bounds[1])),Math.max(...painted.map(f=>f.bounds[2])),Math.max(...painted.map(f=>f.bounds[3]))],peak=perFrame.reduce((a,b)=>a.energy>=b.energy?a:b);
 measurements.push({name:s.name,frames:s.frames,fps:s.fps,duration:s.frames/s.fps,stepGameDuration:s.kind==='step'?4/11.31:undefined,firstVisible:painted[0]?.frame,peakFrame:peak.frame,paintedSize:[bounds[2]-bounds[0]+1,bounds[3]-bounds[1]+1],bounds,border,alphaBad,dim,perFrame});
 if(process.argv.includes('--board-only'))continue;
 const duration=s.kind==='step'?4/11.31:s.frames/s.fps,H=scene(s,0).H,ph=H+18;
 const native=canvas(4*280,ph*Math.ceil(s.frames/4));
 for(let n=0;n<s.frames;n++){const cv=scene(s,n/s.frames*duration),x=n%4*280,y=Math.floor(n/4)*ph;label(native,`F${n+1} T=${(n/s.frames*duration).toFixed(3)}S`,x+3,y+3);blit(native,img(cv),x,y+16);}
 savePNG(resolve(out,`qa/${s.name}-1x.png`),native);
 // 4x pages preserve all world pixels; no photographic interpolation.
 for(let n=0;n<s.frames;n+=3){const page=canvas(280*3,ph);for(let j=0;j<3&&n+j<s.frames;j++){const time=(n+j)/s.frames*duration;label(page,`${s.name.toUpperCase()} F${n+j+1} ${time.toFixed(3)}S`,j*280+3,3);blit(page,img(scene(s,time)),j*280,16);}savePNG(resolve(out,`qa/${s.name}-4x-${Math.floor(n/3)+1}.png`),page,4);}
}
writeFileSync(resolve(out,'measurements.json'),JSON.stringify(measurements,null,2)+'\n','utf8');
const heights=specs.map(s=>scene(s,0).H*4+42),board=canvas(1440,heights.reduce((a,b)=>a+b,0)+30,[19,20,30]);
label(board,'VFX-09 A / SHARP MOMENT / REAL GAME ART BENCH - NOT ENGINE CAPTURE',12,9,[255,220,140]);
let rowY=30;
for(let i=0;i<specs.length;i++){
 const s=specs[i],y=rowY,m=measurements[i],t=0;
 label(board,`${s.name.toUpperCase()} ${s.frames}F ${s.fps}FPS ${(s.frames/s.fps).toFixed(3)}S`,12,y+2,[255,220,140]);
 const first=scene(s,0),late=scene(s,t);
 blit(board,img(first),10,y+20);label(board,'FIRST / 1X',12,y+20+first.H);
 blit(board,resize(img(late),4),310,y+24);
 label(board,'FIRST / 4X - FULL SPRITE AND EFFECT',310,y+12);
 rowY+=heights[i];
}
savePNG(resolve(out,'board.png'),board);
const compact=canvas(1120,660,[19,20,30]);
for(const [i,name] of ['luna_step','luna_jump','luna_air_jump','brave_rush_3','brave_rush_1','brave_rush_2','brave_low','brave_side_air','brave_hit_after','brave_hit_after_big','brave_up','brave_down_air'].entries()){
 const s=specs.find(s=>s.name===name),x=i%4*280,y=Math.floor(i/4)*220;
 const scale=i>=10?.55:1,v=resize(img(scene(s,0)),scale);
 label(compact,name.toUpperCase()+` / F1 / ${scale}X`,x+4,y+4,[255,220,140]);blit(compact,v,x+(280-v.w)/2,y+16);
}
savePNG(resolve(out,'overview.png'),compact);
const step=specs[0],feetBoard=canvas(560,190);
for(let i=0;i<2;i++){label(feetBoard,`WALK F${i?8:4} / TOE +${i?18:17}PX`,i*280+3,3);blit(feetBoard,img(scene(step,0,{secondStep:!!i})),i*280,16);}
savePNG(resolve(out,'qa/luna_step-both-feet-4x.png'),feetBoard,4);
if(process.argv.includes('--animation')){
 const group=specs.filter(s=>['luna_step','luna_jump','luna_air_jump','brave_rush_3'].includes(s.name)),frames=[];
 for(let n=0;n<30;n++){const cv=canvas(560,440),t=n/30;group.forEach((s,i)=>{const v=scene(s,t);blit(cv,img(v),i%2*280,Math.floor(i/2)*220);label(cv,s.name.toUpperCase(),i%2*280+3,Math.floor(i/2)*220+3);});frames.push(cv.d);}
 writeFileSync(resolve(out,'timing.apng'),encodeAPNG(560,440,frames,30));
}
console.log(JSON.stringify(measurements.map(({perFrame,...m})=>m)));
