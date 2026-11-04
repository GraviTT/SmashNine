import { writeFileSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { scene,items,into,layout,HERE } from "./preview.mjs";
import { bench } from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
const {canvas,label,savePNG}=bench;
const overview=canvas(736,1340);
label(overview,"FREY CANDIDATE B / ACTUAL CELLS, BENCH COMPOSITE",10,8,[255,234,160]);
label(overview,"NOT A GAME RECORDING / EFFECT AGE 0.20S (HITS 0.10S)",10,18);
items.forEach((item,i)=>{
 const x=i%2*368,y=36+Math.floor(i/2)*326;
 const cv=scene(item,item.kind==="hit"?0.10:0.20);
 const panel=canvas(368,316);
 into(panel,cv,0,0);
 into(overview,panel,x,y);
});
savePNG(fileURLToPath(new URL("overview.png",HERE)),overview);
const rows=items.map(item=>({...item,...layout(item)}));
const html=String.raw`<!doctype html>
<html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Frey 후보 B · 프레임 검수</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#111820;color:#e8edf3;font:15px/1.6 system-ui,sans-serif}main{max-width:1120px;margin:30px auto;padding:0 20px}h1{font-size:26px;margin:0 0 8px;color:#ffe1a1}p{max-width:900px;color:#b7c3cf}nav{display:flex;gap:8px;flex-wrap:wrap;margin:16px 0}button,select{background:#23323f;color:#edf4f8;border:1px solid #5b6f80;border-radius:5px;padding:9px 14px;font:inherit;cursor:pointer}button[aria-pressed=true]{background:#a47a2c;color:#fff}#stage{border:1px solid #465766;overflow:auto;max-height:76vh;background:#0b1118;padding:16px}canvas{display:block;image-rendering:pixelated;image-rendering:crisp-edges}input{width:min(650px,90%)}output{font-variant-numeric:tabular-nums;color:#ffe1a1}small{color:#94a8b9}a{color:#b7dbff}
</style>
<main><h1>Frey · pixelfx 후보 B</h1>
<p>실제 Frey 셀과 기존 검 궤적·피격 불꽃을 합성한 검수 화면입니다. 실제 경기 녹화가 아닙니다. 공격은 활성 순간부터, 피격 잔광은 적중 0.075초 뒤부터 시작합니다. 게임 연결 및 채택 전 후보입니다.</p>
<nav><select id="pick" aria-label="효과"></select><button id="play">일시 정지</button><button id="prev">이전 프레임</button><button id="next">다음 프레임</button><button id="one" aria-pressed="true">1배</button><button id="four" aria-pressed="false">4배</button></nav>
<p id="note"></p><input id="seek" type="range" min="0" value="0" step="1" aria-label="프레임"><output id="time"></output>
<div id="stage"><canvas id="view"></canvas></div>
<p><a href="board.png">1배·4배 결과 보드</a> · <a href="README.md">측정 및 한계</a> · <a href="qa/manifest.json">전체 4배 검수 목록</a></p>
<small>20fps · 최근접 확대 · 몸과 효과 위치는 고정한 합성 검수입니다. 실제 이동, 넉백, 히트스톱, 8인 경기 가독성은 여기서 재현하지 않습니다.</small>
<script>
const rows=DATA_ROWS;
const pick=document.getElementById('pick'),view=document.getElementById('view'),ctx=view.getContext('2d'),seek=document.getElementById('seek'),stamp=document.getElementById('time');
let index=0,frame=0,zoom=1,playing=true,last=0,hold=0,imgs=new Map();
rows.forEach((r,i)=>{const o=document.createElement('option');o.value=i;o.textContent=r.id;pick.append(o)});
function load(){const r=rows[index];frame=0;seek.max=r.frames-1;document.getElementById('note').textContent=r.note;if(!imgs.has(r.id)){const img=new Image();img.src='qa/'+r.id+'-1x.png';imgs.set(r.id,img);img.onload=paint;}paint();}
function paint(){const r=rows[index],img=imgs.get(r.id);view.width=r.w;view.height=r.h;view.style.width=r.w*zoom+'px';view.style.height=r.h*zoom+'px';ctx.imageSmoothingEnabled=false;if(img&&img.complete)ctx.drawImage(img,(frame%6)*(r.w+8),Math.floor(frame/6)*(r.h+8),r.w,r.h,0,0,r.w,r.h);seek.value=frame;stamp.textContent=' '+(frame+1)+' / '+r.frames+' · '+(frame/20).toFixed(2)+'초';}
function stop(){playing=false;document.getElementById('play').textContent='재생';}
pick.onchange=()=>{index=+pick.value;load()};seek.oninput=()=>{stop();frame=+seek.value;paint()};
document.getElementById('play').onclick=()=>{playing=!playing;document.getElementById('play').textContent=playing?'일시 정지':'재생'};
document.getElementById('prev').onclick=()=>{stop();frame=Math.max(0,frame-1);paint()};document.getElementById('next').onclick=()=>{stop();frame=Math.min(rows[index].frames-1,frame+1);paint()};
function size(k){zoom=k;document.getElementById('one').setAttribute('aria-pressed',k===1);document.getElementById('four').setAttribute('aria-pressed',k===4);paint()}
document.getElementById('one').onclick=()=>size(1);document.getElementById('four').onclick=()=>size(4);
function tick(t){if(!last)last=t;let steps=Math.floor((t-last)/50);if(steps>0){last+=steps*50;if(playing){while(steps--){if(frame<rows[index].frames-1)frame++;else if(hold++>7){frame=0;hold=0}}paint()}}requestAnimationFrame(tick)}load();requestAnimationFrame(tick);
</script></main></html>`;
writeFileSync(new URL("preview.html",HERE),html.replace("DATA_ROWS",JSON.stringify(rows))+"\n");
console.log("Wrote overview.png and preview.html.");
