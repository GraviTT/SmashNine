"""ART-72 package.py exact 4x page layout, available for individual attempts."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw
stem,row,attempt=sys.argv[1:4]
base=Path(f'reports/codex-art-78/{stem}/{row}/attempt-{attempt}')
sheet=Image.open(base/f'{stem}-{row}.png').convert('RGBA');cell=sheet.height
n={'jump':3,'fall':2,'hurt':3,'victory':6}[row]
folder='frey' if stem=='frey' else 'luna';v={'frey':2,'luna':3,'luna_brave':4}[stem]
a=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v{v}.png').convert('RGBA').crop((0,0,128,128))
out=base/'qa4x';out.mkdir(exist_ok=True)
step=2 if cell==192 else 3
for start in range(0,n,step):
 frames=[sheet.crop((i*cell,0,(i+1)*cell,cell)) for i in range(start,min(n,start+step))]
 canvas=Image.new('RGB',((128+cell*len(frames))*4,cell*4),(31,38,55));d=ImageDraw.Draw(canvas);x=0
 for k,f in enumerate([a]+frames):
  y=(cell//2+56-120)*4 if k==0 else 0
  t=f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST);canvas.paste(t,(x,y),t)
  d.text((x+4,y+4),'ANCHOR' if k==0 else f'F{start+k}',fill='white');x+=t.width
 canvas.save(out/f'{start+1:02d}-{min(n,start+step):02d}.png')
