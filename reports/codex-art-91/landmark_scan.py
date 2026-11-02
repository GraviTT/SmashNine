"""Colour-connected landmark measurement; outputs new files only."""
from pathlib import Path
import sys,json,importlib.util
import numpy as np
from PIL import Image
sys.dont_write_bytecode=True
s=importlib.util.spec_from_file_location('r91',Path(__file__).with_name('row_pipeline.py'));p=importlib.util.module_from_spec(s);s.loader.exec_module(p)
def component(im,kind):
 a=np.asarray(im).astype(int);r,g,b=a[:,:,0],a[:,:,1],a[:,:,2]
 if kind=='gold':mask=(r>140)&(g>65)&(b<130)&(r>g*1.1)&(a[:,:,3]>127)
 elif kind=='red':mask=(r>140)&(r>g*1.5)&(r>b*1.5)&(a[:,:,3]>127)
 else:raise ValueError(kind)
 seen=np.zeros(mask.shape,bool);groups=[]
 for y,x in zip(*np.where(mask)):
  if seen[y,x]:continue
  q=[(int(x),int(y))];seen[y,x]=True
  for xx,yy in q:
   for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
    if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
  groups.append(q)
 q=max(groups,key=len);xs,ys=zip(*q)
 return dict(bbox=[min(xs),min(ys),max(xs)+1,max(ys)+1],height=max(ys)-min(ys)+1,width=max(xs)-min(xs)+1,area=len(q))
if __name__=='__main__':
 im=Image.open(sys.argv[1]).convert('RGBA');cols=int(sys.argv[2]);kind=sys.argv[3]
 data=[component(im.crop((round(i*im.width/cols),0,round((i+1)*im.width/cols),im.height)),kind) for i in range(cols)]
 print(json.dumps(data))
