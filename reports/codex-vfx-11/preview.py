"""Build an offline review player, embedding only task art and reference frames."""
import base64
from io import BytesIO
import json

from PIL import Image

from build import ROOT, REPORT, FX, ICONS, SPECS, write_text, manifest
from qa import LABELS, sprite


def data(im):
    f=BytesIO();im.save(f,format='PNG')
    return 'data:image/png;base64,'+base64.b64encode(f.getvalue()).decode()


def build():
    payload={'effects':{},'sprites':{},'icons':{}}
    for name,spec in SPECS.items():
        payload['effects'][name]={'label':LABELS[name],'spec':spec,
            'a':data(Image.open(FX/f'{name}-a-v1.png')),
            'b':data(Image.open(FX/f'{name}-b-v1.png'))}
    for kind in ['male','female','foe']:
        im,anchor=sprite(kind)
        payload['sprites'][kind]={'image':data(im),'anchor':anchor}
    for kind in ['male','female']:
        im,anchor=sprite(kind,True)
        payload['sprites'][kind+'_throw']={'image':data(im),'anchor':anchor}
    for key in 'jklui':payload['icons'][key]=data(Image.open(ICONS/f'rio_{key}-v1.png'))
    html=HTML.replace('__DATA__',json.dumps(payload,ensure_ascii=False,separators=(',',':')))
    write_text(REPORT/'preview.html',html)
    manifest()


HTML='''<!doctype html>
<html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Rio VFX-11 후보 검수</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#101829;color:#dcecf2;font:15px/1.6 system-ui,sans-serif}
main{padding:24px;max-width:1600px;margin:auto}h1{font-size:24px;margin:0 0 6px}p{margin:0 0 20px;color:#9eb8ca}
.controls{display:flex;flex-wrap:wrap;gap:12px;align-items:center;margin-bottom:18px}label{display:flex;gap:6px;align-items:center}
button,select{font:inherit;color:#e3f3ff;background:#21364e;border:1px solid #43627a;border-radius:4px;padding:6px 10px;cursor:pointer}
button:focus-visible,select:focus-visible,input:focus-visible{outline:2px solid #39d8ff}input{accent-color:#39d8ff}
.pair{display:flex;gap:20px;flex-wrap:wrap}.panel{padding:12px;border:1px solid #324e66;background:#152239;overflow:auto;max-width:100%}
h2{margin:0;font-size:18px;color:#39d8ff}canvas{display:block;image-rendering:pixelated;image-rendering:crisp-edges;margin-top:10px}
.status{margin:18px 0;font-variant-numeric:tabular-nums}.icons{display:flex;gap:14px;align-items:center;margin-top:24px}
.icon{text-align:center}.icon img{image-rendering:pixelated;width:80px;height:80px;background:#182d49;border:1px solid #35556a}
.foot{margin-top:24px;max-width:900px;color:#9eb8ca}.disabled{opacity:.4}
</style><main>
<h1>리오 기술 이펙트 · A/B 후보</h1>
<p>실제 시트와 후보 그림을 합성한 검수용 재생기입니다. 게임 실행 화면은 아닙니다. 외부 연결 없이 이 파일만 열어 볼 수 있습니다.</p>
<div class="controls">
<label>항목 <select id="effect"></select></label>
<label>스프라이트 <select id="body"><option value="male">남 리오</option><option value="female">여 리오</option></select></label>
<label>마검 장면 <select id="scene"><option value="flying">던지는 손 앞</option><option value="body">적 몸에 꽂힘</option><option value="wall">벽에 꽂힘</option><option value="air">공중 대기</option></select></label>
<label>배경 <select id="background"><option value="#101829">어두움</option><option value="#99aabb">밝음</option></select></label>
<label>보기 <select id="scale"><option value="1">1×</option><option value="2" selected>2×</option><option value="4">4×</option></select></label>
<label>재생 속도 <select id="speed"><option value="1">정속</option><option value="0.25">1/4 느리게</option></select></label>
</div><div class="controls">
<button id="play">일시정지</button><button id="restart">처음부터</button><button id="step">한 프레임</button>
<label>프레임 <input id="frame" type="range" min="0" max="5" value="0"></label>
<label><input id="anchor" type="checkbox">앵커 표시</label>
</div>
<div class="pair"><section class="panel"><h2>A</h2><canvas id="a" width="256" height="192"></canvas></section><section class="panel"><h2>B</h2><canvas id="b" width="256" height="192"></canvas></section></div>
<div class="status" id="status" role="status"></div>
<div class="icons" id="icons"></div>
<div class="foot">정속은 JSON의 fps를 사용합니다. 단발 효과는 한 번 끝나면 0.65초 쉬고 반복합니다. 마검·받아치기는 쉬는 구간 없이 반복합니다. 마검은 오른쪽 진행 예시이며, 본체 동작은 현재 게임의 임시 K 자세입니다. 급소·분신의 몸 중심은 현재 GameScale 값인 발 위 32px, 받아치기 아트 중심은 카드대로 발 위 약 50px입니다.</div>
</main><script>
const DATA=__DATA__;
const $=id=>document.getElementById(id);
const images={};
let playing=true,elapsed=0,last=null,current=0,visible=true;
const load=(id,src)=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>{images[id]=im;resolve()};im.onerror=reject;im.src=src});
const jobs=[];
for(const [name,e] of Object.entries(DATA.effects)){const o=document.createElement('option');o.value=name;o.textContent=e.label;$('effect').append(o);for(const v of ['a','b'])jobs.push(load(name+v,e[v]));}
for(const [name,s] of Object.entries(DATA.sprites))jobs.push(load(name,s.image));
for(const [key,src] of Object.entries(DATA.icons)){const div=document.createElement('div');div.className='icon';const im=document.createElement('img');im.src=src;im.alt=key.toUpperCase();div.append(im,document.createElement('br'),key.toUpperCase());$('icons').append(div);}
function figure(ctx,key,x,y,tint=[1,1,1,1]){
 const im=images[key],a=DATA.sprites[key].anchor;
 if(tint.every(v=>v===1)){ctx.drawImage(im,x-a[0],y-a[1]);return;}
 const temp=document.createElement('canvas');temp.width=im.width;temp.height=im.height;const tc=temp.getContext('2d');tc.drawImage(im,0,0);
 const pixels=tc.getImageData(0,0,temp.width,temp.height);for(let i=0;i<pixels.data.length;i+=4)for(let c=0;c<4;c++)pixels.data[i+c]=Math.round(pixels.data[i+c]*tint[c]);tc.putImageData(pixels,0,0);ctx.drawImage(temp,x-a[0],y-a[1]);
}
function draw(v){
 const name=$('effect').value,e=DATA.effects[name],[w,h,n,fps,anchor,loop,blend]=e.spec;
 const cv=$(v),ctx=cv.getContext('2d'),isSword=name.includes('mana_sword');cv.width=isSword?256:192;cv.height=isSword?160:192;
 cv.style.width=cv.width*Number($('scale').value)+'px';cv.style.height=cv.height*Number($('scale').value)+'px';ctx.imageSmoothingEnabled=false;ctx.fillStyle=$('background').value;ctx.fillRect(0,0,cv.width,cv.height);
 let at,kind=$('body').value,foot=[96,170],scene=$('scene').value;
 if(isSword){
  if(scene==='flying'){figure(ctx,kind+'_throw',64,144);at=[188,92];}
  else if(scene==='body'){figure(ctx,'foe',112,144);at=[112,112];}
  else if(scene==='wall'){ctx.fillStyle='#314154';ctx.fillRect(116,18,68,126);ctx.strokeStyle='#63798e';ctx.strokeRect(116.5,18.5,67,125);at=[110,90];}
  else at=[112,77];
 }else{
  let tint=[1,1,1,1];if(name==='rio_backstab')kind='foe';if(name==='rio_counter_stance')tint=[.45,.52,1,1];if(name==='rio_decoy_burst')tint=[.5,.78,1,.62];figure(ctx,kind,...foot,tint);
  at=['rio_shadow_blink','rio_counter_stance'].includes(name)?foot:[96,138];
 }
 ctx.fillStyle='#2c3d4c';ctx.fillRect(4,isSword?145:171,cv.width-8,1);
 if(visible){ctx.globalCompositeOperation=blend==='additive'?'lighter':'source-over';ctx.drawImage(images[name+v],current*w,0,w,h,at[0]-anchor[0],at[1]-anchor[1],w,h);ctx.globalCompositeOperation='source-over';}
 if($('anchor').checked){ctx.fillStyle='#f3b96d';ctx.fillRect(at[0]-3,at[1],7,1);ctx.fillRect(at[0],at[1]-3,1,7);}
}
function render(){draw('a');draw('b');const e=DATA.effects[$('effect').value],[w,h,n,fps,anchor,loop,blend]=e.spec;$('status').textContent=`${e.label} | F${current+1}/${n} | ${fps} fps | ${w}×${h} px | ${loop?'반복':'단발 '+(n/fps).toFixed(3)+'초'} | anchor (${anchor.join(', ')}) | ${blend}${visible?'':' | 쉬는 구간'}`;}
function reset(){elapsed=0;current=0;visible=true;const name=$('effect').value,e=DATA.effects[name];$('frame').max=e.spec[2]-1;$('frame').value=0;$('scene').disabled=!name.includes('mana_sword');if(name==='rio_mana_sword')$('scene').value='flying';if(name==='rio_mana_sword_stuck'&&$('scene').value==='flying')$('scene').value='body';render();}
$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'일시정지':'재생';};
$('restart').onclick=reset;
$('step').onclick=()=>{playing=false;$('play').textContent='재생';const e=DATA.effects[$('effect').value];current=(current+1)%e.spec[2];elapsed=current/e.spec[3];visible=true;$('frame').value=current;render();};
$('frame').oninput=()=>{playing=false;$('play').textContent='재생';current=Number($('frame').value);elapsed=current/DATA.effects[$('effect').value].spec[3];visible=true;render();};
$('effect').onchange=reset;for(const id of ['body','scene','background','scale','anchor'])$(id).onchange=render;
function tick(t){if(last===null)last=t;const dt=Math.min((t-last)/1000,.1);last=t;if(playing){elapsed+=dt*Number($('speed').value);const e=DATA.effects[$('effect').value],[w,h,n,fps,a,loop]=e.spec,duration=n/fps,phase=elapsed%(duration+(loop?0:.65));visible=phase<duration;current=Math.min(n-1,Math.floor(phase*fps));$('frame').value=current;render();}requestAnimationFrame(tick);}
Promise.all(jobs).then(()=>{reset();requestAnimationFrame(tick);}).catch(()=>{$('status').textContent='이미지를 읽지 못했습니다.';});
</script></html>
'''


if __name__=='__main__':build()
