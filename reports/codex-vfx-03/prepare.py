from pathlib import Path
import json, hashlib
from PIL import Image, ImageDraw, ImageFont
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
R=Path(__file__).resolve().parent
P=ROOT/'smash-nine-prototype'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
def paste(b,im,x,y): b.alpha_composite(im.convert('RGBA'),(x,y))
board=Image.new('RGBA',(1200,780),'#172031');d=ImageDraw.Draw(board)
refs=[('attack_vfx/frey_k.png',6),('attack_vfx/frey_l.png',6),('vfx/frey_ult_wave.png',8),('vfx/frey_ult_charge.png',6)]
for i,(p,n) in enumerate(refs):
 im=Image.open(P/'assets/art'/p);w=im.width//n;frame=im.crop((w*3,0,w*4,im.height));frame.thumbnail((400,210),Image.Resampling.NEAREST)
 x=(i%2)*430;y=(i//2)*250;paste(board,frame,x+20,y+30);d.text((x+20,y+5),p,fill='white',font=font)
for j,n in enumerate(['stun','super_armor']):
 im=Image.open(P/'assets/art/ui/status'/f'{n}.png');paste(board,im.resize((144,144),Image.Resampling.NEAREST),880,20+j*210);d.text((880,170+j*210),n,fill='white',font=font)
for j,n in enumerate(['frey_j','frey_k','frey_l','frey_i','rio_j','luna_brave_k']):
 im=Image.open(P/'assets/art/skill_icons'/f'{n}.png');paste(board,im.resize((160,160),Image.Resampling.NEAREST),20+j*195,550);d.text((20+j*195,730),n,fill='white',font=font)
board.convert('RGB').save(R/'references.png')
im=Image.open(P/'assets/art/frey/frey_moves_sheet.png');im.crop((0,3*192,192,4*192)).save(R/'hover-reference.png')
info={}
for p in sorted((ROOT/'art/raw/vfx-03').glob('*.png')):
 im=Image.open(p).convert('RGBA');a=np.array(im)
 info[p.name]={'size':im.size,'alpha_percentiles':np.percentile(a[:,:,3],[0,50,80,90,99,100]).tolist()}
(R/'raw-info.json').write_text(json.dumps(info,indent=2),encoding='utf-8')
# Snapshot all product files except engine caches, without modifying the product tree.
snap={}
for p in P.rglob('*'):
 if p.is_file() and '.godot' not in p.parts:
  snap[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
(R/'product-baseline.json').write_text(json.dumps(snap,indent=2),encoding='utf-8')
print(json.dumps(info,indent=2));print('product files hashed',len(snap))
