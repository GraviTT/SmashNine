"""4x nearest QA of rejected source cells; never repairs or publishes them."""
from pathlib import Path
import json
from PIL import Image
import numpy as np

raw=Path('art/raw/motions-78');manifest=[]
for stem,row,attempt,cols,rows in [('frey','victory',1,3,2),('frey','victory',3,3,2),('luna_brave','hurt',1,3,1)]:
 key=f'{stem}-{row}-{attempt}';im=Image.open(raw/f'{key}.png').convert('RGB')
 out=raw/'invalid-review4x'/key;out.mkdir(parents=True,exist_ok=True)
 for k in range(cols*rows):
  x,y=k%cols,k//cols
  cell=im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows)))
  a=np.array(cell);mask=(a[:,:,0]>60)|(a[:,:,1]<160)|(a[:,:,2]>60);yy,xx=np.nonzero(mask)
  box=(max(0,int(xx.min())-4),max(0,int(yy.min())-4),min(cell.width,int(xx.max())+5),min(cell.height,int(yy.max())+5))
  enlarged=cell.crop(box).resize(((box[2]-box[0])*4,(box[3]-box[1])*4),Image.Resampling.NEAREST)
  pages=[];limit=2048
  xs=[0] if enlarged.width<=limit else [0,enlarged.width-limit]
  ys=[0] if enlarged.height<=limit else [0,enlarged.height-limit]
  for v,oy in enumerate(ys):
   for u,ox in enumerate(xs):
    p=out/f'F{k+1}-{u}-{v}.png';enlarged.crop((ox,oy,min(ox+limit,enlarged.width),min(oy+limit,enlarged.height))).save(p);pages.append(p.as_posix())
  manifest.append({'key':key,'frame':k+1,'source_crop':box,'scale':4,'pages':pages})
(raw/'invalid-review4x/manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps({'frames':len(manifest),'pages':sum(len(m['pages']) for m in manifest)}))
