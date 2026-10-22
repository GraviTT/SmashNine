"""Coordinate grid for checking proposed landmarks; this never changes sprite pixels."""
import sys
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np
sys.path.insert(0,'tools/sprite_pipeline');import head_scale as h
stem,row,attempt,index=sys.argv[1:5];index=int(index)-1
def skin(a):
 r,g,b,al=[a[...,j].astype(int) for j in range(4)]
 return (al>0)&(r>180)&(g>125)&(b>105)&(r>g)&(g>b)&(r-b>12)&(r-b<120)
h.skin_mask=skin
root=Path('reports/codex-art-75');base=root/stem/row/f'attempt-{attempt}';im=Image.open(base/f'{stem}-{row}.png').convert('RGBA');cell=im.height
f=im.crop((index*cell,0,(index+1)*cell,cell));a=Image.open(f'art/raw/motions-75/{stem}-anchor.png').convert('RGBA')
b=Image.new('RGB',(1152,640),(32,38,55));d=ImageDraw.Draw(b)
for j,fr in enumerate([a,f]):
 cy,cx=(float(sys.argv[6]),float(sys.argv[5])) if j and len(sys.argv)>5 else h.face_centre(np.array(fr))
 x,y=round(cx)-16,round(cy)-16;c=fr.crop((x,y,x+32,y+32));b.paste(c.resize((512,512),Image.Resampling.NEAREST),(j*576+48,48),c.getchannel('A').resize((512,512),Image.Resampling.NEAREST))
 for k in range(33):
  if k%2==0:d.text((j*576+48+k*16,25),str(x+k),fill='white');d.text((j*576+16,48+k*16),str(y+k),fill='white')
  d.line((j*576+48+k*16,48,j*576+48+k*16,560),fill=(80,80,80));d.line((j*576+48,48+k*16,j*576+560,48+k*16),fill=(80,80,80))
b.save(base/f'manual-pair-f{index+1}.png')
