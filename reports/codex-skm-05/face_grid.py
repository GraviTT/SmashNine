"""ART-72 pixel-grid board, split into readable pages for landmark inspection."""
import os,sys,json
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import head_scale as h
from PIL import Image,ImageDraw
import numpy as np
row,attempt=sys.argv[1:3]
stem='nova_'+sys.argv[3]
base=Path('reports/codex-skm-05')/stem/row/('attempt-'+attempt)
im=Image.open(base/(stem+'-'+row+'.png')).convert('RGBA')
a=Image.open(f'art/bakeoff/nova/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
frames=[a]+[im.crop((j*192,0,(j+1)*192,192)) for j in range(6)]
for j in range(6):
 board=Image.new('RGB',(1152,640),(31,38,55));d=ImageDraw.Draw(board)
 for i,f in enumerate([a,frames[j+1]]):
  arr=np.array(f);box=f.getbbox();arr[round(box[1]+(box[3]-box[1])*.48):,:,3]=0
  cy,cx=h.face_centre(arr) or h.face_centre(np.array(f)) or (80,96);x,y=round(cx)-16,round(cy)-16
  cr=f.crop((x,y,x+32,y+32)).resize((512,512),Image.Resampling.NEAREST)
  ox=i*576+48;oy=48;board.paste(cr,(ox,oy),cr)
  d.text((i*576+8,8),'ANCHOR' if i==0 else f'{row} F{j+1}',fill='white')
  for k in range(33):
   if k%2==0:
    d.text((ox+k*16,27),str(x+k),fill='white');d.text((i*576+14,oy+k*16),str(y+k),fill='white')
   d.line((ox+k*16,oy,ox+k*16,oy+512),fill=(70,70,70));d.line((ox,oy+k*16,ox+512,oy+k*16),fill=(70,70,70))
 board.save(base/f'face-grid-{j+1}.png')
