import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { specs } from './setup.mjs';
import { art, readPNG, crop, stripFrame, canvas, blit, drawBody, drawStrip, realm, label, savePNG, core, boxOf } from './bench.mjs';
import { encodeAPNG } from './apng.mjs';
const repo=fileURLToPath(new URL('../../',import.meta.url)), out=fileURLToPath(new URL('./',import.meta.url));
mkdirSync(resolve(out,'qa'),{recursive:true});
const images=new Map();
for(const s of specs)images.set(s.name,readPNG(resolve(repo,`art/bakeoff/effects/pixelfx/${s.char}/a/${s.name}-a.png`)));
const img=cv=>({w:cv.W,h:cv.H,data:cv.d});
function resized(im,k) {
  const w=Math.round(im.w*k),h=Math.round(im.h*k),data=new Uint8ClampedArray(w*h*4);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)data.set(im.data.subarray((Math.floor(y/k)*im.w+Math.floor(x/k))*4,(Math.floor(y/k)*im.w+Math.floor(x/k))*4+4),(y*w+x)*4);
  return {w,h,data};
}
function body(char,motion,t=0,angle=0) {
  let c;
  if(char==='frey'&&(motion==='jump'||motion==='air'||motion.startsWith('land'))) {
    const jumping=motion==='jump'||motion==='air',n=jumping?3:2;
    const sheet=art(`assets/art/frey/frey_${jumping?'jump':'land'}.png`);
    c=stripFrame(sheet,n,Math.min(n-1,Math.floor(t*(jumping?10:12))));c.root=[64,120];
  } else if(char==='luna'&&motion.startsWith('launch')) {
    const row=angle<0?0:angle>0?1:7,fps=angle<0?19.95:17.85;
    c=crop(art('assets/art/luna/luna_moves_sheet.png'),Math.min(5,2+Math.floor(t*fps))*192,row*192,192,192);c.root=[96,152];
  } else {
    const row=motion==='hurt'?7:0;
    c=crop(art(`assets/art/${char}/${char}_sheet.png`),(row?0:Math.floor(t*6.3)%6)*128,row*128,128,128);c.root=[64,120];
  }
  return c;
}
function oriented(im,anchor,angle) {
  if(!angle)return {im,anchor};
  const radius=Math.ceil(Math.hypot(im.w,im.h)),w=radius*2+1,h=w,data=new Uint8ClampedArray(w*h*4),co=Math.cos(angle),si=Math.sin(angle);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
    const u=x-radius,v=y-radius,sx=Math.round(u*co+v*si+anchor[0]),sy=Math.round(-u*si+v*co+anchor[1]);
    if(sx>=0&&sy>=0&&sx<im.w&&sy<im.h)data.set(im.data.subarray((sy*im.w+sx)*4,(sy*im.w+sx)*4+4),(y*w+x)*4);
  }
  return {im:{w,h,data},anchor:[radius,radius]};
}
function place(cv,im,anchor,at,angle=0,mode='add') {const r=oriented(im,anchor,angle);drawStrip(cv,r.im,r.anchor,at,{mode});}
function candidate(cv,s,t,at,angle=0) {
  if(!s.loop&&t>=s.frames/s.fps)return;
  const raw=Math.floor(t*s.fps+1e-7),frame=s.loop?raw%s.frames:Math.min(s.frames-1,raw);
  place(cv,stripFrame(images.get(s.name),s.frames,frame),s.anchor,at,angle);
}
export function scene(s,t,{moving=false,angle=0,background='midgard',baseline=false,full=false}={}) {
  const W=full?540:240,H=164,cv=canvas(W,H),floor=142;
  realm(cv,background,{sx:620,sy:510,floorY:floor,platform:s.kind!=='air'});
  if(s.char==='frey') {
    const air=s.kind==='air',jump=s.kind==='jump'||air,fx=120,fy=air?109:floor;
    const lift=moving&&jump?Math.min(70,t*210):0;
    drawBody(cv,body('frey',s.kind,t),fx,fy-lift);
    if(!baseline)candidate(cv,s,t,[fx,fy]);
  } else if(s.kind.startsWith('hit')) {
    const fx=120,fy=floor;
    drawBody(cv,body('frey','hurt'),fx,fy);
    const at=[fx,fy-32];
    // Current game hit spark: four cells at 44 fps, damage 3 / 2 and knockback 120 / 90.
    if(t<4/44) {
      const damage=s.kind.endsWith('big')?2:3,kb=s.kind.endsWith('big')?90:120;
      const sparkSize=Math.max(24,Math.min(56,18+damage*1.35+kb*.035))*1.5;
      const spark=stripFrame(art('assets/art/effects/hit/luna_hit.png'),4,Math.floor(t*44));
      const scaled=resized(spark,sparkSize*2/spark.h);
      place(cv,scaled,[scaled.w/2,scaled.h/2],at,0,'mix');
    }
    if(s.kind.endsWith('big')&&t<6/42.857) {
      const burst=stripFrame(art('assets/art/effects/skill/luna_comet_burst.png'),6,Math.min(5,Math.floor(t*42.857)));
      const scaled=resized(burst,1.25);
      place(cv,scaled,[140,140],at,0,'add');
    }
    if(!baseline)candidate(cv,s,t,at,angle);
  } else {
    const trail=s.loop,big=s.kind.endsWith('big'),fx=trail?45:75,fy=floor;
    drawBody(cv,body('luna',trail?'idle':s.kind,t,angle),fx,fy);
    const origin=[fx+Math.cos(angle)*45,fy-38+Math.sin(angle)*45];
    const speed=big?930:1050,lifetime=big?.36:.3;
    const movingShot=moving||!trail;
    const travel=movingShot?Math.min(t,lifetime)*speed:102;
    const at=[origin[0]+Math.cos(angle)*travel,origin[1]+Math.sin(angle)*travel];
    if(trail&&!baseline&&(!moving||t<lifetime))candidate(cv,s,t,at,angle);
    if(!trail&&!baseline)candidate(cv,s,t,origin,angle);
    if(!movingShot||t<lifetime) {
      // set_effect_art() uses Vfx.spawn screen_scale=1: the actual art is not multiplied by COMBAT.
      const shot=stripFrame(art(`assets/art/effects/luna_star_${big?'big':'shot'}.png`),4,Math.floor(t*16)%4);
      place(cv,shot,[big?48:24,big?48:24],at,angle,'mix');
    }
  }
  return cv;
}
function measure(s) {
  const strip=images.get(s.name),frames=[];let border=0,alphaBad=0,dim=0;
  for(let n=0;n<s.frames;n++) {
    const f=stripFrame(strip,s.frames,n);let minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity,count=0,energy=0;
    for(let y=0;y<f.h;y++)for(let x=0;x<f.w;x++) {
      const i=(y*f.w+x)*4,a=f.data[i+3];
      if(a!==0&&a!==255)alphaBad++;
      if(!a)continue;count++;energy+=Math.max(...f.data.subarray(i,i+3));
      if(Math.max(...f.data.subarray(i,i+3))<40)dim++;
      if(x===0||y===0||x===f.w-1||y===f.h-1)border++;
      minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);
    }
    frames.push({frame:n+1,time:n/s.fps,pixels:count,energy,box:count?[minX-s.anchor[0],minY-s.anchor[1],maxX-s.anchor[0],maxY-s.anchor[1]]:null});
  }
  const populated=frames.filter(f=>f.box),bounds=[Math.min(...populated.map(f=>f.box[0])),Math.min(...populated.map(f=>f.box[1])),Math.max(...populated.map(f=>f.box[2])),Math.max(...populated.map(f=>f.box[3]))];
  const peak=frames.reduce((a,b)=>a.energy>=b.energy?a:b);
  return {name:s.name,frames:s.frames,fps:s.fps,duration:s.frames/s.fps,firstVisible:populated[0].frame,peakFrame:peak.frame,peakTime:peak.time,paintedSize:[bounds[2]-bounds[0]+1,bounds[3]-bounds[1]+1],bounds,border,alphaBad,dim,perFrame:frames};
}
const measurements=specs.map(measure);
writeFileSync(resolve(out,'measurements.json'),JSON.stringify(measurements,null,2)+'\n','utf8');
if(!process.argv.includes('--board-only'))for(const s of specs) {
  // Every frame at actual sample time: native 1x sheet and 4x nearest-neighbour pages.
  const native=canvas(240*4,184*Math.ceil(s.frames/4));
  for(let n=0;n<s.frames;n++) {
    const cv=scene(s,n/s.fps),x=n%4*240,y=Math.floor(n/4)*184;
    label(native,`${s.name.toUpperCase()} F${n+1} ${(n/s.fps).toFixed(3)}S`,x+3,y+4);
    blit(native,img(cv),x,y+16);
  }
  savePNG(resolve(out,`qa/${s.name}-1x.png`),native);
  for(let start=0;start<s.frames;start+=4) {
    const page=canvas(480,368);
    for(let i=0;i<4&&start+i<s.frames;i++) {
      const n=start+i,x=i%2*240,y=Math.floor(i/2)*184;
      label(page,`${s.name.toUpperCase()} F${n+1} ${(n/s.fps).toFixed(3)}S`,x+3,y+4);
      blit(page,img(scene(s,n/s.fps)),x,y+16);
    }
    savePNG(resolve(out,`qa/${s.name}-4x-${Math.floor(start/4)+1}.png`),page,4);
  }
}
// A compact index: first contact at 1x; measured energy peak and late decay at 4x.
const board=canvas(1160,10*360+38,[19,20,30]);
label(board,'A / THE SHARP MOMENT - REAL GAME ART BENCH / NOT ENGINE CAPTURE',12,10,[255,220,140]);
for(let i=0;i<specs.length;i++) {
  const s=specs[i],m=measurements[i],y=38+i*360;
  label(board,`${s.name.toUpperCase()}  ${s.frames}F @${s.fps}FPS  ${(s.frames/s.fps).toFixed(3)}S`,12,y+2,[255,220,140]);
  blit(board,img(scene(s,0)),12,y+28);label(board,'FIRST / 1X',12,y+200);
  const n=s.kind.startsWith('hit')?(s.kind.endsWith('big')?5:3):m.peakFrame-1,cv=scene(s,n/s.fps);
  const cropY=s.char==='frey'?(s.kind==='air'?64:84):s.kind.startsWith('hit')?80:64;
  const slice=crop(img(cv),10,cropY,220,80),scaled=resized(slice,4);
  blit(board,scaled,270,y+28);
  label(board,`${s.kind.startsWith('hit')?'AFTER EXISTING SPARK':'PEAK DETAIL'} / 4X  F${n+1} ${(n/s.fps).toFixed(3)}S`,270,y+16);
}
savePNG(resolve(out,'board.png'),board);
// Aim extremes, and every 25ms step of the star's flight (actual world speed).
if(!process.argv.includes('--board-only'))for(const name of ['luna_star_launch','luna_star_launch_big']) {
  const s=specs.find(s=>s.name===name),cv=canvas(480,368);
  for(let a=0;a<2;a++)for(let f=0;f<2;f++) {
    const angle=(a===0?-1:1)*Math.PI/3,t=f/s.fps;
    blit(cv,img(scene(s,t,{angle})),f*240,a*184+16);
    label(cv,`${name.toUpperCase()} ${a===0?'-60':'+60'} DEG F${f+1}`,f*240+3,a*184+4);
  }
  savePNG(resolve(out,`qa/${name}-aim-4x.png`),cv,4);
}
if(!process.argv.includes('--board-only'))for(const name of ['luna_star_trail','luna_star_trail_big']) {
  const s=specs.find(s=>s.name===name),count=s.kind.endsWith('big')?15:13;
  const cv=canvas(540,184*count);
  for(let n=0;n<count;n++) {
    const t=n/40;
    blit(cv,img(scene(s,t,{moving:true,full:true})),0,n*184+16);
    label(cv,`${name.toUpperCase()} T=${t.toFixed(3)} ${s.kind.endsWith('big')?930:1050}PX/S`,4,n*184+4);
  }
  savePNG(resolve(out,`qa/${name}-moving-1x.png`),cv);
}
if(process.argv.includes('--animation')) {
  const frames=[],fps=40,seconds=1;
  for(let n=0;n<fps*seconds;n++) {
    const cv=canvas(540,328),t=n/fps%1;
    for(const [j,name] of ['luna_star_trail','luna_star_trail_big'].entries()) {
      const s=specs.find(s=>s.name===name),v=scene(s,t,{moving:true,full:true});
      label(v,`${name.toUpperCase()} ${j?930:1050}PX/S  T=${t.toFixed(3)}`,4,4);
      blit(cv,img(v),0,j*164);
    }
    frames.push(cv.d);
  }
  writeFileSync(resolve(out,'moving-stars.apng'),encodeAPNG(540,328,frames,fps));
  console.log('moving-stars.apng: 40 fps, one-second looping inspection');
}
console.log(measurements.map(m=>({name:m.name,first:m.firstVisible,peak:m.peakFrame,size:m.paintedSize,border:m.border,alphaBad:m.alphaBad})));
