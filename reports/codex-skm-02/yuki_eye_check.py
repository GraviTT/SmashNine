"""Yuki red-pupil centres on 4x nearest crops, replacing inappropriate magenta weighting."""
import sys,json,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
base=Path('reports/codex-skm-02/yuki/seal_link')/f'attempt-{sys.argv[1]}'
d=json.loads((base/'face-proposed.json').read_text(encoding='utf-8'))
sheet=Image.open(base/'yuki-seal_link.png').convert('RGBA');a=Image.open('art/bakeoff/yuki/yuki-idle-v2.png').convert('RGBA').crop((0,0,128,128))
frames=[a]+[sheet.crop((i*192,0,(i+1)*192,192)) for i in range(6)]
board=Image.new('RGB',(7*256,280),(31,38,55));draw=ImageDraw.Draw(board);results=[]
for i,f in enumerate(frames):
 marks=[{'x':83.5,'y':63},{'x':90.5,'y':62.5}] if i==0 else d['frames'][i-1]['landmarks'][:2]
 ar=np.array(f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST)).astype(float);pts=[]
 for m in marks:
  x,y=round(m['x']*4),round(m['y']*4);sx,sy=x-8,y-8;p=ar[sy:y+8,sx:x+8];r,g,b=p[:,:,:3].transpose(2,0,1)
  w=np.maximum(r-np.maximum(g,b),0)*((r>80)&(g<135)&(b<135)&(r>g*1.5)&(p[:,:,3]>0))
  yy,xx=np.indices(w.shape);assert w.sum()>0
  pts.append([(sx+(xx*w).sum()/w.sum()+.5)/4,(sy+(yy*w).sum()/w.sum()+.5)/4])
 dist=math.dist(*pts)
 if i==0:ref=dist
 ox=round(sum(p[0] for p in pts)/2)-24;oy=round(sum(p[1] for p in pts)/2)-24
 cr=f.crop((ox,oy,ox+48,oy+48)).resize((192,192),Image.Resampling.NEAREST);board.paste(cr,(i*256+32,40),cr)
 for x,y in pts:
  xx=i*256+32+(x-ox)*4;yy=40+(y-oy)*4;draw.line((xx-3,yy,xx+3,yy),fill='cyan');draw.line((xx,yy-3,xx,yy+3),fill='cyan')
 draw.text((i*256+6,6),f'{i}: E={dist/ref:.4f}',fill='white');results.append({'frame':i,'eyes':pts,'eye_distance':dist,'eye_ratio':dist/ref})
board.save(base/'red-eye-landmarks.png');(base/'red-eye-measured.json').write_text(json.dumps({'method':'Red pupil weighted centre in bounded 4x crops, visual review required','frames':results},indent=2),encoding='utf-8');print(json.dumps(results))
