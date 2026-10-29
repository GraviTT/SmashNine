"""Exact 4x boards, no sprite alteration. Existing outputs are never overwritten."""
import sys,json
from pathlib import Path
from PIL import Image,ImageDraw
base=Path('reports/codex-art-82')
versions={'frey':2,'luna':3,'luna_brave':4,'yuki':2,'nova_female':2,'rio_male':2,'rio_female':2}
counts={'jump':3,'fall':2,'hurt':3,'victory':6}
for f in base.glob('*/*/attempt-*/*.png'):
 stem,row=f.parent.parent.parent.name,f.parent.parent.name
 if f.name!=f'{stem}-{row}.png':continue
 cell=Image.open(f).height;count=counts[row]
 folder=stem.split('_')[0];a=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v{versions[stem]}.png').convert('RGBA').crop((0,0,128,128))
 im=Image.open(f).convert('RGBA');per=2 if cell==192 else 3
 facepath=f.parent/'face-proposed.json';faces=json.loads(facepath.read_text())['frames'] if facepath.exists() else []
 for start in range(0,count,per):
  out=f.parent/f'page4x-{start+1:02d}-{min(start+per,count):02d}.png'
  if out.exists():continue
  num=min(per,count-start);width=512+cell*4*num;height=cell*4+48
  b=Image.new('RGB',(width,height),(31,38,55));d=ImageDraw.Draw(b)
  aa=a.resize((512,512),Image.Resampling.NEAREST);b.paste(aa,(0,32+(cell-128)*2),aa);d.text((8,8),'ANCHOR 4x',fill='white')
  for j in range(num):
   k=start+j;fr=im.crop((k*cell,0,(k+1)*cell,cell)).resize((cell*4,cell*4),Image.Resampling.NEAREST);x=512+j*cell*4;b.paste(fr,(x,32),fr)
   caption=f'F{k+1}'
   if faces:caption+=f" E={faces[k].get('eye_ratio')} W={faces[k].get('face_width_ratio')}"
   d.text((x+8,8),caption,fill='white')
  b.save(out)
  print(out.as_posix())
