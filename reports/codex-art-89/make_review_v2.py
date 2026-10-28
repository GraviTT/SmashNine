from PIL import Image,ImageDraw
from pathlib import Path
import sys,json
stem,row,path,label=sys.argv[1:5]
root=Path('reports/codex-art-89');d=root/'review'/label;assert not d.exists();d.mkdir(parents=True)
raw=Path('art/raw/motions-89');a=Image.open(raw/f'{stem}-{row}-anchor-original.png').convert('RGBA').crop((0,0,128,128));old=Image.open(raw/f'{stem}-{row}-current-original.png').convert('RGBA');im=Image.open(path).convert('RGBA');cell=im.height
count={'victory':6,'jump':3,'hurt':3,'fall':2,'walk':8}[row]; per=2 if cell==192 else 3
for start in range(0,count,per):
 n=min(per,count-start);b=Image.new('RGB',(512+n*cell*4,cell*4+48),(31,38,55));dr=ImageDraw.Draw(b);dr.text((8,8),'ANCHOR',fill='white');aa=a.resize((512,512),Image.Resampling.NEAREST);b.paste(aa,(0,48+(cell//2+56-120)*4),aa)
 for k in range(n):
  frame=im.crop(((start+k)*cell,0,(start+k+1)*cell,cell)).resize((cell*4,cell*4),Image.Resampling.NEAREST);x=512+k*cell*4;b.paste(frame,(x,48),frame);dr.text((x+8,8),f'{stem} {row} F{start+k+1} | {label} | 4x nearest',fill='white')
 b.save(d/f'F{start+1:02d}-{start+n:02d}.png')
# Each final row board contains the anchor and every before/after frame, all at native 4x.
b=Image.new('RGB',(512+count*cell*4,2*(cell*4+48)),(31,38,55));dr=ImageDraw.Draw(b)
for j,strip in enumerate([old,im]):
 y=j*(cell*4+48);dr.text((8,y+8),'CURRENT BEST' if j==0 else 'ART-89 BEST ATTEMPT',fill='white');aa=a.resize((512,512),Image.Resampling.NEAREST);b.paste(aa,(0,y+48+(cell//2+56-120)*4),aa)
 for k in range(count):
  f=strip.crop((k*cell,0,(k+1)*cell,cell)).resize((cell*4,cell*4),Image.Resampling.NEAREST);b.paste(f,(512+k*cell*4,y+48),f);dr.text((520+k*cell*4,y+8),f'F{k+1}',fill='white')
b.save(d/'comparison.png')
print(d.as_posix())
