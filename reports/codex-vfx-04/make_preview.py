"""Self-contained human playback review; embeds candidate images and two idle anchors."""
import base64
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'reports/codex-vfx-04'


def uri(path):
    return 'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode('ascii')


data=[]
for item in json.loads((OUT/'processing.json').read_text(encoding='utf-8')):
    if item['frames']==1:
        continue
    path=Path(item['path'])
    data.append(dict(name=path.stem,n=item['frames'],fps=item['fps'],loop=item['loop'],
                     size=item['frame_size'][0],src=uri(ROOT/path),note=item['note']))
idle=[uri(ROOT/'art/bakeoff/luna'/name) for name in ['luna-idle-v3.png','luna_brave-idle-v4.png']]
html='''<!doctype html>
<html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Luna VFX-04 후보 재생</title>
<style>
body{margin:24px;background:#111a2b;color:#e6edff;font:15px system-ui,sans-serif}h1{font-size:22px}p{color:#b9c8dd;max-width:980px}
header{position:sticky;top:0;background:#111a2bf5;padding:12px 0;z-index:2}button,select{padding:8px 12px;background:#26334d;color:white;border:1px solid #607392;border-radius:4px;margin-right:8px}
main{display:grid;grid-template-columns:repeat(2,minmax(320px,1fr));gap:18px}article{border:1px solid #354461;padding:12px;overflow:auto}h2{font-size:16px;margin:0 0 6px}canvas{image-rendering:pixelated;display:block}small{color:#92b4cf}label{margin-right:12px}
@media(max-width:750px){main{grid-template-columns:1fr}}
</style>
<h1>Luna 새 기술 이펙트 후보</h1>
<p>실제 게임 실행 화면이 아닌 후보 합성 미리보기입니다. 반복 효과는 지정 fps로 계속 재생하며, 일회성 효과는 끝난 뒤 0.7초 쉬고 다시 시작합니다. 정지 후 프레임을 넘겨 마지막→첫 프레임 연결을 확인할 수 있습니다.</p>
<header><button id="play">정지</button><button id="prev">이전 프레임</button><button id="next">다음 프레임</button><select id="zoom"><option value="1">1배</option><option value="2">2배</option><option value="4">4배</option></select><label><input id="guides" type="checkbox" checked>판정 가이드</label><label><input id="fired" type="checkbox">회오리 발사 상태</label></header>
<main id="cards"></main>
<script>
const specs=__DATA__;
const idleSources=__IDLE__;
let playing=true, frozen=0, started=performance.now(), stepOffset=0;
const idleImages=idleSources.map(src=>{const im=new Image();im.src=src;return im});
const cards=specs.map(s=>{
 const article=document.createElement('article');
 const title=document.createElement('h2');title.textContent=s.name;article.append(title);
 const note=document.createElement('p');note.textContent=s.note;article.append(note);
 const status=document.createElement('small');article.append(status);
 const canvas=document.createElement('canvas');canvas.width=320;canvas.height=300;article.append(canvas);
 document.getElementById('cards').append(article);
 const img=new Image();img.src=s.src;
 return {s,img,canvas,status,ctx:canvas.getContext('2d')};
});
const play=document.getElementById('play');
play.onclick=()=>{if(playing){frozen=performance.now()-started;playing=false}else{started=performance.now()-frozen;playing=true}play.textContent=playing?'정지':'재생'};
function step(n){if(playing){frozen=performance.now()-started;playing=false;play.textContent='재생'}stepOffset+=n}
document.getElementById('prev').onclick=()=>step(-1);
document.getElementById('next').onclick=()=>step(1);
document.getElementById('zoom').onchange=e=>cards.forEach(c=>{c.canvas.style.width=320*Number(e.target.value)+'px';c.canvas.style.height=300*Number(e.target.value)+'px'});
function render(now){
 const elapsed=(playing?now-started:frozen)/1000;
 const guides=document.getElementById('guides').checked;
 const fired=document.getElementById('fired').checked;
 cards.forEach(({s,img,canvas,status,ctx})=>{
  const base=Math.floor(elapsed*s.fps);
  const duration=s.n/s.fps;
  const phase=s.loop?elapsed:elapsed%(duration+.7);
  let f=((Math.floor(phase*s.fps)+stepOffset)%s.n+s.n)%s.n;
  const blank=playing&&!s.loop&&phase>=duration;
  ctx.imageSmoothingEnabled=false;ctx.globalCompositeOperation='source-over';ctx.fillStyle='#111a2b';ctx.fillRect(0,0,320,300);
  const cx=160,cy=145,cyc=s.name.includes('cyclone'),shot=s.name.includes('star_shot')||s.name.includes('star_big');
  if(guides){ctx.strokeStyle='#76804d';ctx.lineWidth=1;ctx.beginPath();if(s.name.includes('barrier'))ctx.arc(cx,cy,105,0,Math.PI*2);else if(s.name.includes('warp'))ctx.rect(cx-97.5,cy-82.5,195,165);else if(cyc&&fired)ctx.rect(cx-52.5,cy-75,105,150);else if(shot){let z=s.size===48?33:60;ctx.rect(cx-z/2,cy-z/2,z,z)}ctx.stroke()}
  if(!shot&&!(cyc&&fired)){const ch=idleImages[cyc?1:0];if(ch.complete)ctx.drawImage(ch,0,0,128,128,cx-64,cy-86,128,128)}
  let scale=cyc&&!fired?1.25:1;
  if(!blank&&img.complete){ctx.globalCompositeOperation=shot?'source-over':'lighter';ctx.drawImage(img,f*s.size,0,s.size,s.size,cx-s.size*scale/2,cy-s.size*scale/2,s.size*scale,s.size*scale);ctx.globalCompositeOperation='source-over'}
  status.textContent=`${s.fps} fps / ${s.loop?'반복':'일회성'} / ${blank?'재생 사이 휴지':`프레임 ${f+1}/${s.n}`} / ${s.size}×${s.size}`;
 });
 requestAnimationFrame(render);
}
requestAnimationFrame(render);
</script></html>
'''.replace('__DATA__',json.dumps(data,ensure_ascii=False)).replace('__IDLE__',json.dumps(idle))
(OUT/'preview.html').write_text(html,encoding='utf-8')
# Same script without image payload for a syntax check, never loaded by the preview.
script=html.split('<script>',1)[1].split('</script>',1)[0]
(OUT/'preview-syntax.js').write_text(script,encoding='utf-8')
print('Preview:',len(html.encode('utf-8')),'bytes')
