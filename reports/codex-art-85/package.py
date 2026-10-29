"""Package reviewed draft-1 once; refuses every overwrite."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2]
RAW=ROOT/'art/raw/projectiles-85'
SRC=RAW/'draft-1'
REPORT=ROOT/'reports/codex-art-85'
OUT=ROOT/'art/bakeoff/monsters'
IDS=['svartalfheim_cog_drone','niflheim_frost_owl','yggdrasil_root_guardian']
OTHERS=['ember_imp','jotunheim_storm_wisp','midgard_rooftop_slinger','vanaheim_seed_sprite','yggdrasil_root_oracle']

def copy(src,dst):
    with src.open('rb') as a,dst.open('xb') as b:shutil.copyfileobj(a,b)

def save(im,dst):
    with dst.open('xb') as f:im.save(f,format='PNG')

for id in IDS:
    stem=id+('-shockwave-v1' if id==IDS[2] else '-projectile-v2')
    for ext in ['.png','.json']:copy(SRC/(stem+ext),OUT/(stem+ext))
for id in IDS+OTHERS:
    review=Image.open(SRC/(id+('' if id in IDS else '-review')+'.png')).convert('RGBA')
    context=Image.open(SRC/(id+'-context.png')).convert('RGBA')
    board=Image.new('RGBA',(1120,review.height+context.height),'#202936')
    board.alpha_composite(review);board.alpha_composite(context,(0,review.height));save(board,REPORT/(id+'.png'))
for name in ['measurements.json','processing.json']:copy(SRC/name,REPORT/name)
refs=json.loads((RAW/'reference-sources.json').read_text(encoding='utf-8'))
for item in refs:
    old=(ROOT/item['original']).read_bytes();stored=(ROOT/item['copy']).read_bytes();assert old==stored
    item['sha256']=hashlib.sha256(stored).hexdigest()
gens=[('bomb-gen1','exec-d740d411-848d-4ef5-be89-cd84ef50d3e5.png',False),('bomb-gen2','exec-e2a2d341-db85-4e16-902b-9e5b8f7fe0b6.png',True),('ice-gen1','exec-87607238-6644-47b7-bcfc-e1e8fdf7e7b5.png',True),('guardian-gen1','exec-0aa49fe0-50ee-48a5-8571-f6eafad2063b.png',True)]
sources={'references':refs,'generations':[{'raw':'art/raw/projectiles-85/'+n+'.png','builtin_output_basename':o,'selected':s,'sha256':hashlib.sha256((RAW/(n+'.png')).read_bytes()).hexdigest()} for n,o,s in gens]}
with (REPORT/'sources.json').open('x',encoding='utf-8',newline='\n') as f:json.dump(sources,f,ensure_ascii=False,indent=2);f.write('\n')
overview=Image.new('RGBA',(920,480),'#202936');d=ImageDraw.Draw(overview)
font=lambda size:ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',size)
d.text((22,15),'ART-85  새 후보 3종 · 게임 미적용',font=font(24),fill='white')
names=['폭탄 v2 / 8프레임 / 45° 간격','얼음 v2 / 4프레임 / 본체 고정','수호자 충격파 v1 / 4프레임 / 바닥 y=44']
for row,id in enumerate(IDS):
    y=68+row*130;d.text((22,y),names[row],font=font(18),fill='#d8e4f4')
    stem=id+('-shockwave-v1' if row==2 else '-projectile-v2');im=Image.open(OUT/(stem+'.png')).convert('RGBA');w=64 if row==2 else 48
    for i in range(im.width//w):
        f=im.crop((i*w,0,(i+1)*w,48));overview.alpha_composite(f.resize((w*2,96),Image.Resampling.NEAREST),(22+i*(w*2+8),y+28))
save(overview,REPORT/'overview.png')
print('Packaged 3 PNG/JSON pairs, 8 combined comparison/context boards, overview, measurements and sources. No overwrites.')
