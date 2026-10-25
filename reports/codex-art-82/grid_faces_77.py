import sys
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import head_scale as h
stem,row,att=sys.argv[1:4];base=Path(f'reports/codex-art-82/{stem}/{row}/attempt-{att}')
sheet=Image.open(base/f'{stem}-{row}.png').convert('RGBA');c=sheet.height
frames=[Image.open(f'art/bakeoff/rio/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))]+h.cells(base/f'{stem}-{row}.png')
for i,f in enumerate(frames):
 cy,cx=h.face_centre(np.array(f));ox,oy=round(cx)-12,round(cy)-10
 out=Image.new('RGB',(650,590),(30,38,55));d=ImageDraw.Draw(out)
 crop=f.crop((ox,oy,ox+26,oy+22)).resize((572,484),Image.Resampling.NEAREST);out.paste(crop,(50,50),crop)
 for k in range(27):
  d.text((50+k*22,27),str(ox+k),fill='white');d.line((50+k*22,50,50+k*22,534),fill=(70,70,70))
 for k in range(23):
  d.text((20,50+k*22),str(oy+k),fill='white');d.line((50,50+k*22,622,50+k*22),fill=(70,70,70))
 out.save(base/f'grid-F{i}.png')
