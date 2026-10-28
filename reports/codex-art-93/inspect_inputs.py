"""ART-93 immutable input inventory and reference board. No product writes."""
import os
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
import json, hashlib, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'reports/codex-art-93'
CONFIG = [
 ('alfheim_moon_moth',1,2,2),('yggdrasil_root_oracle',1,2,1),
 ('asgard_aegis_ram',2,2,1),('asgard_runic_raven',1,2,1),
 ('niflheim_frost_owl',1,1,2),('ember_imp',2,1,1),
 ('yggdrasil_root_guardian',1,1,2),('jotunheim_storm_wisp',1,1,1)]

def fresh(p):
 p=Path(p)
 if p.exists(): raise FileExistsError(p)
 p.parent.mkdir(parents=True,exist_ok=True)
 return p
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,data):fresh(p).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def frames(p,count=4,row=0):
 im=Image.open(p).convert('RGBA')
 return [im.crop((i*96,row*96,(i+1)*96,(row+1)*96)) for i in range(count)]
def board(p,groups,title):
 font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
 w=24+max(len(fs) for _,fs in groups)*400
 im=Image.new('RGB',(w,40+len(groups)*422),(25,30,43));d=ImageDraw.Draw(im)
 d.text((12,8),title,font=font,fill='white')
 for ri,(label,fs) in enumerate(groups):
  yy=40+ri*422;d.text((12,yy),label,font=font,fill='white')
  for i,f in enumerate(fs):
   x=12+i*400;y=yy+26
   bg=Image.new('RGB',(384,384),(37,45,61));b=ImageDraw.Draw(bg)
   for a in range(0,384,32):
    for c in range(0,384,32):
     if (a+c)//32%2:b.rectangle((a,c,a+31,c+31),fill=(43,52,70))
   z=f.resize((384,384),Image.Resampling.NEAREST);bg.paste(z,(0,0),z);im.paste(bg,(x,y))
   d.rectangle((x+16,y+16,x+367,y+367),outline=(100,130,145))
   d.line((x,y+292,x+383,y+292),fill=(245,115,160))
 im.save(fresh(p))

if __name__=='__main__':
 paths=set(subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode().split('\0'))
 # Include every pre-existing candidate, even untracked ones; product tracked files
 # are protected without traversing Godot's cache or writing to its project.
 paths={p for p in paths if p and (ROOT/p).is_file()}
 paths.update(str(p.relative_to(ROOT)).replace('\\','/') for p in (ROOT/'art/bakeoff/monsters').glob('*') if p.is_file())
 for base in ['art/raw/monsters-71','art/raw/monsters-76','art/raw/monsters-83']:
  paths.update(str(p.relative_to(ROOT)).replace('\\','/') for p in (ROOT/base).glob('*.png'))
 dump(OUT/'input-hashes.json',{p:sha(ROOT/p) for p in sorted(paths)})
 mid='yggdrasil_root_oracle';sheet=ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png'
 board(OUT/'oracle-reference-4x.png',[
  ('KEPT IDLE F1-F4',frames(sheet)),
  ('KEPT ATTACK F1-F4',frames(sheet,row=3)),
  ('PICKED WINDUP F1-F4',frames(ROOT/f'art/bakeoff/monsters/{mid}-windup-v2.png'))],
  'ROOT ORACLE | EXACT NEAREST 4x | pink = below y72; blue = 4px safe area')
 print('Protected files:',len(paths))
