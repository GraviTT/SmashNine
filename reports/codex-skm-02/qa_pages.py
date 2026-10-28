"""Remove label column only: exact 4x pages fit 2048 px without display downsampling."""
from pathlib import Path
from PIL import Image,ImageDraw
root=Path('reports/codex-skm-02')
for p in root.glob('*/*/attempt-*/page-*.png'):
 im=Image.open(p)
 if im.width==2238:im=im.crop((190,0,im.width,im.height))
 if im.width==2048:
  d=ImageDraw.Draw(im);page=int(p.stem.split('-')[-1])
  for x,label in [(0,'ANCHOR'),(512,f'F{page*2-1}'),(1280,f'F{page*2}')]:
   d.rectangle((x,0,x+120,24),fill=(31,38,55));d.text((x+5,5),label,fill='white')
 im.save(p)
