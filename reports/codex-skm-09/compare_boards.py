"""Build 4x anchor / opposite-body / candidate boards without touching assets."""
import sys,json
from PIL import Image,ImageDraw
from pathlib import Path
from config import ROOT
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
for r in json.loads((ROOT/'selection.json').read_text(encoding='utf-8')):
 stem,row=r['stem'],r['row']; key=stem+'-'+row; base=ROOT/stem/row/f"attempt-{r['attempt']}"
 a=Image.open(f'art/bakeoff/rio/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
 other='rio_male' if stem=='rio_female' else 'rio_female'
 ref=Image.open(f'art/bakeoff/rio/{other}-{row}-v1.png').convert('RGBA')
 src=Image.open(base/(key+'.png')).convert('RGBA'); pages=[]
 for i in range(6):
  frames=[im.crop((i*192,0,(i+1)*192,192)) for im in [ref,src]]
  page=n.render_anchor_candidates(a,frames,152,4)
  d=ImageDraw.Draw(page);d.rectangle((0,0,page.width,40),fill=(24,30,43))
  d.text((16,8),f'{stem} IDLE / 4x',font=n.font(20,True),fill='white')
  d.text((page.width//3+16,8),f'ACCEPTED {other} F{i+1}',font=n.font(20,True),fill='white')
  d.text((page.width*2//3+16,8),f'NEW {stem} F{i+1}',font=n.font(20,True),fill='white')
  pages.append(page)
 board=Image.new('RGB',(pages[0].width,pages[0].height*6),(24,30,43))
 for i,p in enumerate(pages):board.paste(p,(0,i*p.height))
 board.save(ROOT/(key+'.png'),optimize=True)
 for i,p in enumerate(pages):p.save(base/f'comparison-{i+1}.png')
print('Wrote 4x comparison boards')
