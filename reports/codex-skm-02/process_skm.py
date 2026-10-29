"""SKM-02 adaptation of ART-72 process.py; use silhouette inputs, 192 cells."""
import os,sys,json,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
import head_scale as h
from PIL import Image,ImageDraw
import numpy as np
stem,row,attempt,factor=sys.argv[1:5];factor=float(factor);assert 0<factor<=1
if stem=='yuki':
 # ART-75's near-white skin threshold; default Frey threshold selects Yuki's hands.
 def tuned_skin_mask(a):
  r,g,b,al=[a[...,j].astype(int) for j in range(4)]
  return (al>0)&(r>180)&(g>125)&(b>105)&(r>g)&(g>b)&(r-b>12)&(r-b<120)
 h.skin_mask=tuned_skin_mask
folder=stem.split('_')[0];anchor=f'art/bakeoff/{folder}/{stem}-idle-v2.png'
out=Path(f'reports/codex-skm-02/{stem}/{row}/attempt-{attempt}');out.mkdir(parents=True,exist_ok=True)
cmd=[sys.executable,'tools/sprite_pipeline/normalize.py','--frames',f'art/raw/skm-02/{stem}-{row}-{attempt}/frames','--bg','#00ff00','--cell','192','--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--reference',anchor+':0:1','--compare-scale','4','--out-dir',str(out),'--name',f'{stem}-{row}','--title',f'{stem} {row} attempt {attempt}']
if row!='pogo_bounce':cmd+=['--ground-all']
else:cmd+=['--lift-all','8','--lift-scale',sys.argv[5] if len(sys.argv)>5 else '1']
subprocess.run(cmd,check=True)
im=Image.open(out/f'{stem}-{row}.png').convert('RGBA');a=Image.open(anchor).convert('RGBA').crop((0,0,128,128));frames=[im.crop((i*192,0,(i+1)*192,192)) for i in range(6)]
report=h.measure(out/f'{stem}-{row}.png',h.head_template(a),6,.6)
(out/'head-scale.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
n.render_anchor_candidates(a,frames,152,4).save(out/'review4x.png')
for page in range(3):
 n.render_anchor_candidates(a,frames[page*2:page*2+2],152,4).save(out/f'page-{page+1}.png')
faceboard=Image.new('RGB',(256*7,280),(31,38,55));d=ImageDraw.Draw(faceboard);origins=[]
for i,f in enumerate([a]+frames):
 cy,cx=h.face_centre(np.array(f));x,y=round(cx)-24,round(cy)-24;origins.append([x,y])
 cr=f.crop((x,y,x+48,y+48)).resize((192,192),Image.Resampling.NEAREST);faceboard.paste(cr,(i*256+32,40),cr)
 d.text((i*256+4,6),f'{"ANCHOR" if i==0 else "F"+str(i)} origin {x},{y}',fill='white')
 for k in range(0,49,4):
  d.text((i*256+32+k*4,235),str(x+k),fill='white');d.text((i*256,40+k*4),str(y+k),fill='white')
faceboard.save(out/'faces4x.png')
(out/'face-origins.json').write_text(json.dumps(origins),encoding='utf-8')
