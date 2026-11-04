import {writeFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {bench} from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
import {specs,rootFor} from "./bake-lib.mjs";
import {encodePNG} from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs";
process.argv.push("--library");
const {panel,body,rotate,star}=await import("./render.mjs");
const {canvas,realm,drawBody,stripFrame,readPNG,drawStrip,blit,label,savePNG}=bench;
const OUT=new URL("./",import.meta.url),image=cv=>({w:cv.W,h:cv.H,data:cv.d});
function shot(big,t,angle,clipTail=false,starScale=1,kind="trail") {
  const cv=canvas(400,320),feet=[90,146],speed=big?930:1050,life=big?.36:.3;
  realm(cv,"center",{sx:600,sy:420});drawBody(cv,body("luna","idle",t),...feet);
  const at=[feet[0]+Math.cos(angle)*(45+(kind==="trail"?speed*t:0)),feet[1]-38+Math.sin(angle)*(45+(kind==="trail"?speed*t:0))];
  const s=specs.find(s=>s.id===`luna_star_${kind}${big?"_big":""}`),n=Math.round(s.duration*20),im=stripFrame(readPNG(new URL(`${s.id}-b.png`,rootFor(s))),n,Math.floor(t*20+1e-6)%n);
  if(clipTail)for(let y=0;y<im.h;y++)for(let x=0;x<im.w;x++)if(x-s.origin[0]<-speed*t-16)im.data.fill(0,(y*im.w+x)*4,(y*im.w+x)*4+4);
  const q=rotate(im,s.origin,angle),layer=canvas(400,320,[0,0,0]);drawStrip(layer,q.im,q.anchor,at,{mode:"add"});
  let head=0,core=0;
  for(let y=0;y<320;y++)for(let x=0;x<400;x++) {
    const j=(y*400+x)*4;if(Math.max(layer.d[j],layer.d[j+1],layer.d[j+2])<40)continue;
    const rx=x-feet[0],ry=y-feet[1];
    if(rx>=-24&&rx<29&&ry>=-96&&ry<-48)head++;
    if(rx>=-20&&rx<20&&ry>=-48&&ry<-10)core++;
  }
  if(t<(kind==="trail"?life:s.duration))drawStrip(cv,q.im,q.anchor,at,{mode:"add"});
  if(t<life)star(cv,big,t,[feet[0]+Math.cos(angle)*(45+speed*t),feet[1]-38+Math.sin(angle)*(45+speed*t)],angle,starScale);
  return {cv,head,core};
}
export function buildOfflinePreview() {
  const banks=[];
  for(const s of specs) {
    const n=s.loop?Math.round(s.duration*20):24,cols=6,rows=Math.ceil(n/cols),sheet=canvas(248*cols,184*rows);
    for(let i=0;i<n;i++){const cv=panel(s,i/20,{moving:s.kind==="trail"});blit(sheet,image(cv),i%cols*248,Math.floor(i/cols)*184);}
    banks.push({id:s.id,n,cols,fps:20,note:s.loop?"반복 이음새 검사: 카메라가 비행하는 별을 따라갑니다. 실제 탄 수명보다 오래 재생합니다.":s.note,png:encodePNG(sheet.W,sheet.H,sheet.d).toString("base64")});
  }
  const html=`<!doctype html><html lang="ko"><meta charset="utf-8"><title>VFX-08 B 검수</title><style>body{margin:24px;background:#14131c;color:#eee;font:15px system-ui}h1{font-size:24px}header{position:sticky;top:0;background:#14131cee;padding:12px;z-index:2}button,select,input{margin:4px;padding:6px}main{display:grid;grid-template-columns:repeat(2,minmax(270px,1fr));gap:20px}article{border:1px solid #454252;padding:12px;overflow:auto}h2{font-size:16px}p{color:#bdb7ce}canvas{image-rendering:pixelated;max-width:none}small{display:block}</style><header><h1>B · 움직임의 방향을 따라 남는 여운</h1><p>게임 자산을 합성한 벤치입니다. 실제 게임 녹화가 아닙니다. 후보는 항상 월드 1배이고 아래 배율은 검수 화면만 확대합니다.</p><button id="pause">일시정지</button><label>검수 배율 <select id="zoom"><option>1</option><option>2</option><option>4</option></select></label><label>속도 <select id="rate"><option value="1">정속</option><option value="0.25">1/4속도</option></select></label><input id="seek" type="range" min="0" max="119" value="0"><span id="time"></span><p>꼬리는 F1부터 재생하며 길이가 자랐다 줄어듭니다. 실제 비행 시점은 flight-small.png / flight-big.png에서 확인할 수 있습니다.</p></header><main></main><script>const banks=${JSON.stringify(banks)};let paused=false,t=0,last=performance.now();const root=document.querySelector('main');for(const b of banks){let a=document.createElement('article');a.innerHTML='<h2>'+b.id+'</h2><p>'+b.note+'</p><canvas width="248" height="184"></canvas><small></small>';b.cv=a.querySelector('canvas');b.ctx=b.cv.getContext('2d');b.img=new Image();b.img.src='data:image/png;base64,'+b.png;b.text=a.querySelector('small');root.append(a);}const pause=document.querySelector('#pause'),zoom=document.querySelector('#zoom'),rate=document.querySelector('#rate'),seek=document.querySelector('#seek');pause.onclick=()=>{paused=!paused;pause.textContent=paused?'재생':'일시정지'};zoom.onchange=()=>banks.forEach(b=>{b.cv.style.width=248*Number(zoom.value)+'px';b.cv.style.height=184*Number(zoom.value)+'px'});seek.oninput=()=>{t=Number(seek.value)/100;paused=true;pause.textContent='재생'};function tick(now){if(!paused)t=(t+(now-last)/1000*Number(rate.value))%1.2;last=now;for(const b of banks){const f=Math.floor(t*b.fps)%b.n;b.ctx.imageSmoothingEnabled=false;if(b.img.complete)b.ctx.drawImage(b.img,(f%b.cols)*248,Math.floor(f/b.cols)*184,248,184,0,0,248,184);b.text.textContent='F'+(f+1)+' / '+b.n+' · '+(f/b.fps).toFixed(2)+'초';}if(!paused)seek.value=Math.floor(t*100);document.querySelector('#time').textContent=t.toFixed(2)+'초';requestAnimationFrame(tick);}requestAnimationFrame(tick);</script></html>\n`;
  // Six seconds is a common multiple of the 0.5s, 0.6s and 1.2s banks: the viewer clock must
  // not force a 0.5s loop to jump back to F1 at the one-shot bank's unrelated 1.2s boundary.
  const timedHTML=html.replace("%1.2", "%6").replace('max="119"', 'max="599"');
  writeFileSync(new URL("preview.html",OUT),timedHTML,"utf8");console.log("Self-contained preview.html saved.");
}
if(process.argv.includes("--html-only")) { buildOfflinePreview(); }
else {
const overlap=[];
for(const big of [false,true])for(const angle of [-Math.PI/3,0,Math.PI/3])for(const clipped of [false,true]) {
  let head=0,core=0;
  for(let i=0;i<=(big?21:17);i++){const r=shot(big,i/60,angle,clipped);head=Math.max(head,r.head);core=Math.max(core,r.core);}
  overlap.push({kind:"trail",big,angle_degrees:Math.round(angle*180/Math.PI),reveal:clipped,max_head_pixels:head,max_core_pixels:core});
}
for(const big of [false,true])for(const angle of [-Math.PI/3,0,Math.PI/3]) {
  let head=0,core=0;
  for(let i=0;i<(big?36:27);i++){const r=shot(big,i/60,angle,false,1,"launch");head=Math.max(head,r.head);core=Math.max(core,r.core);}
  overlap.push({kind:"launch",big,angle_degrees:Math.round(angle*180/Math.PI),reveal:false,max_head_pixels:head,max_core_pixels:core});
}
writeFileSync(new URL("spawn-overlap.json",OUT),JSON.stringify({head_region:"Luna feet x=[-24,29), y=[-96,-48)",body_region:"Luna feet x=[-20,20), y=[-48,-10)",overlap},null,2)+"\n","utf8");
console.log(JSON.stringify(overlap));
for(const big of [false,true]) {
  const sheet=canvas(1200,4*344,[18,17,25]);
  for(let row=0;row<4;row++)for(let col=0;col<3;col++) {
    const t=[0,.05,.1,.2][row],angle=[-Math.PI/3,0,Math.PI/3][col],r=shot(big,t,angle,false);
    label(sheet,`${big?"BIG":"SMALL"} / ${Math.round(angle*180/Math.PI)} DEG / ${t.toFixed(2)}S / NATIVE STRIP`,col*400+8,row*344+8);
    blit(sheet,image(r.cv),col*400,row*344+24);
  }
  savePNG(fileURLToPath(new URL(`flight-${big?"big":"small"}.png`,OUT)),sheet);
}
const scaleBoard=canvas(496,400);
for(let row=0;row<2;row++)for(let col=0;col<2;col++) {
  const s=specs.find(s=>s.id===`luna_star_trail${row?"_big":""}`),cv=panel(s,.15,{starScale:col?1.5:1});
  blit(scaleBoard,image(cv),col*248,row*200+16);
  label(scaleBoard,`${row?"BIG":"SMALL"} STAR ${col?"1.5X CARD":"1X SOURCE"} / FX 1X`,col*248+4,row*200+4);
}
savePNG(fileURLToPath(new URL("star-scale-check-4x.png",OUT)),scaleBoard,4);
buildOfflinePreview();
}
