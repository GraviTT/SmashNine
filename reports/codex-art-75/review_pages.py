"""Exact nearest-neighbour 4x pages that fit without downsampling in the image tool."""
import sys
from pathlib import Path
from PIL import Image,ImageDraw
stem,row,attempt=sys.argv[1:4];root=Path('reports/codex-art-75');base=root/stem/row/f'attempt-{attempt}'
count={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6}[row]
im=Image.open(base/f'{stem}-{row}.png').convert('RGBA');cell=im.height
folder='yuki' if stem=='yuki' else 'nova';a=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
out=root/'qa4x';out.mkdir(exist_ok=True);per=1 if cell==192 else 2
for start in range(0,count,per):
 indices=list(range(start,min(count,start+per)));width=128*4+cell*4*len(indices);height=cell*4+48
 b=Image.new('RGB',(width,height),(31,38,55));d=ImageDraw.Draw(b);ay=48+(cell-128)*2
 b.paste(a.resize((512,512),Image.Resampling.NEAREST),(0,ay),a.getchannel('A').resize((512,512),Image.Resampling.NEAREST));d.text((4,8),'ANCHOR',fill='white')
 for j,i in enumerate(indices):
  f=im.crop((i*cell,0,(i+1)*cell,cell));x=512+j*cell*4;f=f.resize((cell*4,cell*4),Image.Resampling.NEAREST);b.paste(f,(x,48),f.getchannel('A'));d.text((x+4,8),f'{stem} {row} F{i+1}',fill='white')
 feet=152 if cell==192 else 120;d.line((0,48+feet*4,width,48+feet*4),fill=(240,70,80),width=1)
 b.save(out/f'{stem}-{row}-{start+1}.png')
