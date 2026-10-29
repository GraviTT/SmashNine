"""Rebuild exact nearest 4x pages <=2048 pixels wide, with global frame labels."""
from pathlib import Path
import sys
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
root=Path('reports/codex-skm-01')
a=Image.open('art/bakeoff/frey/frey-idle-v2.png').convert('RGBA').crop((0,0,128,128))
for out in (root/'frey').glob('*/attempt-*'):
 row=out.parent.name;path=out/f'frey-{row}.png'
 if not path.exists():continue
 im=Image.open(path).convert('RGBA');frames=[im.crop((i*192,0,(i+1)*192,192)) for i in range(6)]
 for j in range(3):
  p=n.render_anchor_candidates(a,frames[j*2:j*2+2],152,4);p=p.crop((190,0,p.width,p.height));d=ImageDraw.Draw(p)
  for k in range(2):
   d.rectangle((512+k*768,0,650+k*768,32),fill=(31,38,55));d.text((520+k*768,8),f'F{j*2+k+1}',fill='white')
  p.save(out/f'review4x-{j+1}.png')
