"""ART-72 process/boards, with variable-width blob extraction before normalize.py.
Keep common source y coordinates; never split at fixed cell edges or resize parts.
"""
import os,sys,json,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
import head_scale as h
import numpy as np
from collections import deque
from PIL import Image,ImageDraw
row,attempt,factor=sys.argv[1:4];attempt=int(attempt);factor=float(factor)
assert 0<factor<=1
stem='nova_'+sys.argv[4]
root=Path('reports/codex-skm-05');out=root/stem/row/f'attempt-{attempt}';out.mkdir(parents=True,exist_ok=True)
raw=Path(f'art/raw/skm-05/{stem}-{row}-{attempt}.png')
src=Image.open(raw).convert('RGBA');clean,info=n.clean_background(src,'#00ff00')
mask=np.array(clean)[...,3]>0
seen=np.zeros(mask.shape,bool);components=[]
for yy,xx in zip(*np.nonzero(mask)):
 if seen[yy,xx]:continue
 q=deque([(int(yy),int(xx))]);seen[yy,xx]=True;pts=[]
 while q:
  y,x=q.popleft();pts.append((y,x))
  for dy,dx in [(0,1),(0,-1),(1,0),(-1,0)]:
   ny,nx=y+dy,x+dx
   if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((ny,nx))
 components.append(np.array(pts))
components.sort(key=len,reverse=True)
assert len(components)>=6 and len(components[5])>1000,[len(c) for c in components[:10]]
major=sorted(components[:6],key=lambda c:c[:,1].mean());centers=[c.mean(axis=0) for c in major]
for c in components[6:]:
 j=int(np.argmin([np.linalg.norm(c.mean(axis=0)-p) for p in centers]));major[j]=np.concatenate([major[j],c])
boxes=[];inp=out/'source-frames';inp.mkdir(exist_ok=True)
for i,c in enumerate(major):
 l,r=int(c[:,1].min()),int(c[:,1].max())+1;yy=c[:,0];boxes.append([l,int(yy.min()),r,int(yy.max())+1])
 assert l>0 and r<src.width and yy.min()>0 and yy.max()<src.height-1,'raw source border contact'
 # Green padding, full source y retained. No fixed-width slicing.
 arr=np.zeros((src.height,r-l+32,4),np.uint8);arr[:]=[0,255,0,255];arr[c[:,0],c[:,1]-l+16]=np.array(src)[c[:,0],c[:,1]];Image.fromarray(arr).save(inp/f'{i:02}.png')
(out/'extraction.json').write_text(json.dumps({'raw':str(raw),'size':src.size,'method':'six largest connected silhouette blobs, small islands assigned nearest body; no fixed-width cuts; common source y preserved','component_sizes':[len(c) for c in components],'boxes':boxes},indent=2),encoding='utf-8')
anchor=f'art/bakeoff/nova/{stem}-idle-v2.png'
cmd=[sys.executable,'tools/sprite_pipeline/normalize.py','--frames',str(inp/'*.png'),'--bg','#00ff00','--cell','192','--feet-y','152','--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--reference',anchor+':0:1','--compare-scale','4','--out-dir',str(out),'--name',stem+'-'+row,'--title',row]
cmd+=['--ground-all']
res=subprocess.run(cmd,capture_output=True,text=True);(out/'process.log').write_text(res.stdout+res.stderr,encoding='utf-8');print(res.stdout,res.stderr);res.check_returncode()
im=Image.open(out/f'{stem}-{row}.png').convert('RGBA');a=Image.open(anchor).convert('RGBA').crop((0,0,128,128));frames=[im.crop((i*192,0,(i+1)*192,192)) for i in range(6)]
report=h.measure(out/f'{stem}-{row}.png',h.head_template(a),6,.6);(out/'head-scale.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
n.render_anchor_candidates(a,frames,152,4).save(out/'review4x.png')
for j in range(3):
 page=n.render_anchor_candidates(a,frames[j*2:j*2+2],152,4);page=page.crop((190,0,page.width,page.height))
 d=ImageDraw.Draw(page)
 for k in range(2):d.rectangle((512+k*768,0,650+k*768,32),fill=(31,38,55));d.text((520+k*768,8),f'F{j*2+k+1}',fill='white')
 page.save(out/f'review4x-{j+1}.png')
faceboard=Image.new('RGB',(256*7,280),(31,38,55));d=ImageDraw.Draw(faceboard)
for i,f in enumerate([a]+frames):
 cy,cx=h.face_centre(np.array(f)) or (80,96);x,y=round(cx)-24,round(cy)-24
 cr=f.crop((x,y,x+48,y+48)).resize((192,192),Image.Resampling.NEAREST);faceboard.paste(cr,(i*256+32,40),cr);d.text((i*256+4,6),f'{"ANCHOR" if i==0 else "F"+str(i)} origin {x},{y}',fill='white')
faceboard.save(out/'faces4x.png')
