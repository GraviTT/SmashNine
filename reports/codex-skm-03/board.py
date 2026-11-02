"""Build ART-72 4x boards, and the requested hover-to-dash hand-off comparison."""
import os,sys
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
from PIL import Image,ImageDraw
row,attempt=sys.argv[1:3]
root=Path('reports/codex-skm-03');base=root/'frey'/row/('attempt-'+attempt)
sheet=Image.open(base/f'frey-{row}.png').convert('RGBA')
frames=[sheet.crop((i*192,0,(i+1)*192,192)) for i in range(6)]
anchor=Image.open('art/bakeoff/frey/frey-idle-v2.png').convert('RGBA').crop((0,0,128,128))
pages=[]
for j in range(3):
 page=n.render_anchor_candidates(anchor,frames[j*2:j*2+2],152,4)
 page=page.crop((190,0,page.width,page.height));draw=ImageDraw.Draw(page)
 draw.rectangle((0,0,511,35),fill=(15,21,34));draw.text((8,6),'IDLE REFERENCE / 4x',font=n.font(18,True),fill='white')
 for k in range(2):
  x=512+k*768;draw.rectangle((x,0,x+340,35),fill=(15,21,34))
  draw.text((x+8,6),f'{row} F{j*2+k+1} / 4x',font=n.font(18,True),fill='white')
 page.save(base/f'final4x-{j+1}.png');pages.append(page)
if row=='wing_hover':
 game=Image.open('smash-nine-prototype/assets/art/frey/frey_moves_sheet.png').convert('RGBA')
 dash=game.crop((2*192,3*192,3*192,4*192))
 page=n.render_anchor_candidates(anchor,[frames[5],dash],152,4)
 page=page.crop((190,0,page.width,page.height));draw=ImageDraw.Draw(page)
 draw.rectangle((0,0,511,35),fill=(15,21,34));draw.text((8,6),'IDLE REFERENCE / 4x',font=n.font(18,True),fill='white')
 for k,label in enumerate(['wing_hover F6 ->','current dash_strike F3']):
  x=512+k*768;draw.rectangle((x,0,x+490,35),fill=(15,21,34));draw.text((x+8,6),label,font=n.font(18,True),fill='white')
 page.save(base/'handoff4x.png');pages.append(page)
board=Image.new('RGB',(2048,768*len(pages)),(31,38,55))
for i,page in enumerate(pages):board.paste(page,(0,i*768))
board.save(root/f'frey-{row}.png',optimize=True)
