"""Extract six real connected silhouettes, never fixed-width cells. Preserve source y."""
import os,sys,json
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from pathlib import Path
from collections import deque
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
src=Path(sys.argv[1]); out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
im=n.clean_background(Image.open(src),'#00ff00')[0];a=np.array(im);mask=a[:,:,3]>0;hh,ww=mask.shape
labels=np.zeros(mask.shape,np.int32);parts=[]
for y,x in zip(*np.nonzero(mask)):
 if labels[y,x]:continue
 idx=len(parts)+1;q=deque([(int(y),int(x))]);labels[y,x]=idx;pts=[]
 while q:
  cy,cx=q.popleft();pts.append((cy,cx))
  for dy,dx in ((0,1),(0,-1),(1,0),(-1,0),(1,1),(1,-1),(-1,1),(-1,-1)):
   yy,xx=cy+dy,cx+dx
   if 0<=yy<hh and 0<=xx<ww and mask[yy,xx] and not labels[yy,xx]:labels[yy,xx]=idx;q.append((yy,xx))
 ys,xs=zip(*pts);parts.append({'id':idx,'area':len(pts),'box':[min(xs),min(ys),max(xs)+1,max(ys)+1]})
major=sorted([p for p in parts if p['area']>1000],key=lambda p:(p['box'][0]+p['box'][2])/2)
assert len(major)==6,[(p['area'],p['box']) for p in major]
groups={p['id']:[p['id']] for p in major}
for p in parts:
 if p in major:continue
 x0,y0,x1,y1=p['box'];cx=(x0+x1)/2;cy=(y0+y1)/2
 def dist(m):
  l,t,r,b=m['box'];return max(l-cx,0,cx-r)**2+max(t-cy,0,cy-b)**2
 near=min(major,key=dist);groups[near['id']].append(p['id'])
report=[]
for i,p in enumerate(major):
 use=np.isin(labels,groups[p['id']]);ys,xs=np.nonzero(use);left,right=int(xs.min()),int(xs.max()+1)
 assert left>0 and right<ww and ys.min()>0 and ys.max()<hh-1,'source canvas clipping'
 # Keep the full original height and its airborne arc; horizontal padding only.
 b=np.zeros((hh,right-left+16,4),np.uint8);sub=a[:,left:right].copy();sub[:,:,3][~use[:,left:right]]=0;b[:,8:-8]=sub
 Image.fromarray(b).save(out/f'{i:02}.png');report.append({'frame':i+1,'source_bbox':[left,int(ys.min()),right,int(ys.max()+1)],'parts':groups[p['id']],'pixels':int(use.sum())})
(out.parent/'extraction.json').write_text(json.dumps({'source':str(src),'method':'8-connected silhouette extraction, all foreground pixels assigned, no fixed-width slicing; original y retained','frames':report},indent=2),encoding='utf-8')
print(json.dumps(report))
