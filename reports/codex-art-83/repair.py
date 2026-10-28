"""ART-83: ART-71 normalization / ART-74 padded placement; new files only."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import sys,json,hashlib,shutil
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
import process71 as p
n=p.n
ROOT=p.ROOT
REPORT=Path(__file__).resolve().parent
RAW=ROOT/'art/raw/monsters-83'
BAKE=p.BAKE
ROWS=p.ROWS
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
def fresh(path):
 path=Path(path);assert not path.exists(),f'Never overwrite: {path}';path.parent.mkdir(parents=True,exist_ok=True);return path
def jsave(path,data):fresh(path).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def save(path,im):im.save(fresh(path))
def frames(path,count):return p.frames(path,count)
def audit(ims):
 return [dict(frame=i+1,bbox=f.getbbox(),margin=n.margins(f.getbbox(),96)['minimum'],bottom=f.getbbox()[3]-1,detail=n.interior_detail(f),spill=n.spill_pixel_count(f),alpha_binary=set(f.getchannel('A').get_flattened_data())<={0,255}) for i,f in enumerate(ims)]
def strip(ims):
 out=Image.new('RGBA',(576,96))
 for i,f in enumerate(ims):out.alpha_composite(f,(i*96,0))
 return out
def panel(ims,label,scale=4):
 cols=3 if scale==4 else 6;cw=400 if scale==4 else 100;ch=410 if scale==4 else 125
 out=Image.new('RGB',(cols*cw,30+((len(ims)+cols-1)//cols)*ch),(24,29,40));d=ImageDraw.Draw(out);d.text((8,4),label,font=FONT,fill='white')
 for i,f in enumerate(ims):
  x=(i%cols)*cw;y=30+(i//cols)*ch;d.text((x+4,y),f'F{i+1}',font=FONT,fill='white');bg=n.checker((96*scale,96*scale),8*scale);big=f.resize(bg.size,Image.Resampling.NEAREST);bg.paste(big,(0,0),big);out.paste(bg,(x+4,y+22))
 return out
def trial(mid,row,rawname,factor,label,positions=None):
 count=p.COUNTS[row];grid=(3,2) if count==6 else (2,2) if count==4 else (2,1)
 raw=RAW/rawname;src,_=n.split_sheet(raw,grid);clean=[n.clean_background(f,'#00ff00')[0] for f in src];n.validate_source_cell_margin(clean,[str(i) for i in range(count)])
 outdir=REPORT/'trials'/f'{mid}-{row}-{label}';assert not outdir.exists();outdir.mkdir(parents=True)
 ims=[];placements=[]
 for i,s in enumerate(clean):
  work,_,_=n.normalize_frame(s,factor,max(c.getbbox()[3]-1 for c in clean),None,'off','lanczos',60,'auto',0,True,0,1,256,152)
  b=work.getbbox();w,h=b[2]-b[0],b[3]-b[1];x=b[0]-80;y=73-h
  if positions:
   if positions[i][0] is not None:x=positions[i][0]
   if positions[i][1] is not None:y=positions[i][1]-h+1
  x=max(3,min(x,93-w));assert w<=90 and h<=90 and y>=3 and y+h<=93,(i,w,h,x,y)
  im=Image.new('RGBA',(96,96));im.alpha_composite(work.crop(b),(x,y));assert n.alpha_area(im)==n.alpha_area(work);ims.append(im);placements.append(dict(frame=i+1,source_bbox=s.getbbox(),work_bbox=b,output_bbox=im.getbbox()))
 save(outdir/'strip.png',strip(ims));save(outdir/'review-4x.png',panel(ims,f'{mid} {row} {label} / 4x'));save(outdir/'review-1x.png',panel(ims,f'{mid} {row} {label} / 1x',1))
 old=frames(BAKE/f'{mid}-{row}-v1.png',count)
 data=dict(monster=mid,row=row,raw=str(raw.relative_to(ROOT)),factor=factor,method='ART-71 Lanczos sharpen60 despill auto palette none; ART-74 padded canvas, whole-frame translation',placements=placements,before=audit(old),after=audit(ims))
 jsave(outdir/'metrics.json',data);print(json.dumps(data,ensure_ascii=False));return ims
def deliver(mid,row,label,note):
 t=REPORT/'trials'/f'{mid}-{row}-{label}';m=json.loads((t/'metrics.json').read_text('utf-8'));ims=frames(t/'strip.png',p.COUNTS[row]);assert all(x['margin']>=3 and x['alpha_binary'] for x in m['after'])
 dst=BAKE/f'{mid}-{row}-v2.png';shutil.copyfile(t/'strip.png',fresh(dst));meta=json.loads((BAKE/f'{mid}-{row}-v1.json').read_text('utf-8'));meta.update(factor=m['factor'],note=note,replaces=f'{mid}-{row}-v1.png');jsave(dst.with_suffix('.json'),meta)
 old=frames(BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row]);current=Image.open(RAW/'references'/f'{mid}_current.png').convert('RGBA');ri=ROWS.index(row) if current.height==576 else {'idle':0,'walk':1,'attack':2,'hurt':3}.get(row)
 blocks=[]
 for scale in [1,4]:
  if ri is not None:
   cnt=p.COUNTS[row] if current.height==576 else {'idle':4,'walk':6,'attack':4,'hurt':1}[row]
   game=[current.crop((i*96,ri*96,(i+1)*96,(ri+1)*96)) for i in range(cnt)];blocks.append(panel(game,'CURRENT GAME / '+str(scale)+'x',scale))
  blocks.extend([panel(old,'V1 / '+str(scale)+'x',scale),panel(ims,'V2 / '+str(scale)+'x',scale)])
 board=Image.new('RGB',(max(b.width for b in blocks),sum(b.height for b in blocks)),(24,29,40));y=0
 for b in blocks:board.paste(b,(0,y));y+=b.height
 save(REPORT/f'{mid}-{row}.png',board)
def assemble(mid):
 out=Image.new('RGBA',(576,576))
 for i,r in enumerate(ROWS):
  f=BAKE/f'{mid}-{r}-v2.png';f=f if f.exists() else BAKE/f'{mid}-{r}-v1.png';out.alpha_composite(Image.open(f).convert('RGBA'),(0,96*i))
 save(BAKE/f'{mid}_sheet-v2.png',out)
if __name__=='__main__':
 cmd=sys.argv[1]
 if cmd=='trial':trial(sys.argv[2],sys.argv[3],sys.argv[4],float(sys.argv[5]),sys.argv[6],json.loads(sys.argv[7]) if len(sys.argv)>7 else None)
 elif cmd=='deliver':deliver(*sys.argv[2:])
 elif cmd=='assemble':assemble(sys.argv[2])
