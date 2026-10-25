"""ART-77: invoke the existing normaliser, then measure and build review boards."""
import os,sys,json,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
import head_scale as h
from PIL import Image,ImageDraw
import numpy as np

stem,row,attempt,factor=sys.argv[1:5]
attempt=int(attempt);factor=float(factor)
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6}
versions={'rio_male':2,'rio_female':2}
folder='rio'
anchor=f'art/bakeoff/{folder}/{stem}-idle-v{versions[stem]}.png'
out=Path(f'reports/codex-art-82/{stem}/{row}/attempt-{attempt}')
cell=192 if row=='victory' else 128
cmd=[sys.executable,'tools/sprite_pipeline/normalize.py','--sheet',f'art/raw/motions-82/{stem}-{row}-{attempt}.png','--grid',f'{3 if row=="victory" else counts[row]}x{2 if row=="victory" else 1}','--bg','#00ff00','--cell',str(cell),'--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--reference',anchor+':0:1','--compare-scale','4','--out-dir',str(out),'--name',f'{stem}-{row}','--title',f'{stem} {row} attempt {attempt}']
if row in ['hurt','land','victory']:cmd+=['--ground-all']
else:cmd+=['--lift-all','11' if row=='jump' else '8']
if len(sys.argv)>5:cmd+=['--lift-scale',sys.argv[5]]
if len(sys.argv)>6 and '--lift-all' in cmd:
 cmd[cmd.index('--lift-all')+1]=sys.argv[6]
if len(sys.argv)>7:cmd+=['--offset-x',sys.argv[7]]
subprocess.run(cmd,check=True)
im=Image.open(out/f'{stem}-{row}.png').convert('RGBA');a=Image.open(anchor).convert('RGBA').crop((0,0,128,128));frames=[im.crop((i*cell,0,(i+1)*cell,cell)) for i in range(counts[row])]
report=h.measure(out/f'{stem}-{row}.png',h.head_template(a),counts[row],.6)
(out/'head-scale.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
n.render_anchor_candidates(a,frames,cell//2+56,4).save(out/'review4x.png')
faceboard=Image.new('RGB',(256*(len(frames)+1),280),(31,38,55));d=ImageDraw.Draw(faceboard)
def face_centre(f,index):
 ar=np.array(f)
 if stem=='luna_brave' and row=='hurt' and index==2:ar[80:,:,3]=0
 return h.face_centre(ar)
for i,f in enumerate([a]+frames):
 cy,cx=face_centre(f,i);x,y=round(cx)-24,round(cy)-24
 cr=f.crop((x,y,x+48,y+48)).resize((192,192),Image.Resampling.NEAREST);faceboard.paste(cr,(i*256+32,40),cr)
 d.text((i*256+4,6),f'{"ANCHOR" if i==0 else "F"+str(i)} origin {x},{y}',fill='white')
 for k in range(0,49,4):
  d.text((i*256+32+k*4,235),str(x+k),fill='white')
  d.text((i*256,40+k*4),str(y+k),fill='white')
faceboard.save(out/'faces4x.png')
big=Image.new('RGB',(576*(len(frames)+1),640),(31,38,55));bd=ImageDraw.Draw(big)
for i,f in enumerate([a]+frames):
 cy,cx=face_centre(f,i);x,y=round(cx)-16,round(cy)-16
 cr=f.crop((x,y,x+32,y+32)).resize((512,512),Image.Resampling.NEAREST);big.paste(cr,(i*576+48,48),cr)
 for k in range(33):
  if k%2==0:
   bd.text((i*576+48+k*16,25),str(x+k),fill='white');bd.text((i*576+16,48+k*16),str(y+k),fill='white')
  bd.line((i*576+48+k*16,48,i*576+48+k*16,560),fill=(80,80,80),width=1)
  bd.line((i*576+48,48+k*16,i*576+560,48+k*16),fill=(80,80,80),width=1)
big.save(out/'landmark-grid.png')
