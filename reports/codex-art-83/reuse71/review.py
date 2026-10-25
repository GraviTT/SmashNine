"""ART-71 fix-1: candidate-only measurement, raw rebuild and evidence."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import sys, json, shutil, hashlib, importlib.util, math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
ROOT=Path(__file__).resolve().parents[3]
FIX=Path(__file__).resolve().parent
BAKE=ROOT/'art/bakeoff/monsters'
OLD=FIX/'before'
IDS=['mossling','ember_imp','asgard_aegis_ram','asgard_runic_raven','alfheim_moon_stag','alfheim_moon_moth']
ROWS=['idle','walk','windup','attack','hurt','defeat']
COUNTS=dict(zip(ROWS,[6,6,4,6,2,4]))
spec=importlib.util.spec_from_file_location('n',ROOT/'tools/sprite_pipeline/normalize.py')
n=importlib.util.module_from_spec(spec);spec.loader.exec_module(n)
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
SMALL=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',12)
MANUAL={
 'mossling':[(64,47,86,62),(66,48,90,63),(66,51,89,66),(65,51,88,63),(63,51,85,65),(63,52,85,67)],
 'ember_imp':[(51,27,71,44),(50,27,71,43),(54,28,74,44),(54,30,74,45),(57,35,77,51),(62,22,85,40)],
}
STAG_POINTS=[[(31,57),(51,44)],[(35,55),(57,44)],[(34,52),(57,40)],[(29,60),(52,53)],[(30,61),(48,44)],[(32,57),(54,43)]]
PARTS={'mossling':'잎·아래턱을 뺀 윗얼굴 가로폭', 'ember_imp':'뿔·뒤쪽 가시를 뺀 두개골 가로폭',
 'asgard_aegis_ram':'금색 주뿔 연결 영역 세로높이', 'asgard_runic_raven':'금색 어깨 원판 테두리 가로폭',
 'alfheim_moon_stag':'몸통의 엉덩이–어깨 중심 거리(털끝·목 제외)', 'alfheim_moon_moth':'밝은 구형 머리 연결 영역 √면적(등가 선형크기)'}
FACTORS={
 'mossling':[.21527778,.1925,.16,.215,.125,.165],
 'ember_imp':[.17,.17,.145,.185,.102,.14782609],
 'asgard_aegis_ram':[.17,.22,.17,.21,.11733333,.17],
 'asgard_runic_raven':[.175,.19,.177,.239,.1265625,.16],
 'alfheim_moon_stag':[.16,.18,.1471,.18,.1,.1372],
 'alfheim_moon_moth':[.18,.188,.17,.184,.15,.19],
}
PREP={}

def groups(mask):
 from collections import deque
 h,w=mask.shape;seen=np.zeros(mask.shape,bool);out=[]
 for sy,sx in zip(*np.where(mask)):
  if seen[sy,sx]:continue
  q=deque([(int(sx),int(sy))]);seen[sy,sx]=True;pts=[]
  while q:
   x,y=q.popleft();pts.append((x,y))
   for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
    if 0<=nx<w and 0<=ny<h and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
  if len(pts)>6:
   xs,ys=zip(*pts);out.append(dict(area=len(pts),box=[min(xs),min(ys),max(xs)+1,max(ys)+1]))
 return sorted(out,key=lambda z:-z['area'])

def sample_index(mid,row):
 if mid=='alfheim_moon_stag':return 5 if row=='attack' else 0
 return selected(row)

def feature(mid,row,im,old=None,factor=None,idx=None):
 ri=ROWS.index(row)
 if mid in MANUAL:
  box=MANUAL[mid][ri]
  if old is not None:
   ob=old.getbbox();nb=im.getbbox();s=factor/meta(mid,row)['factor']
   box=[round(nb[k%2]+(box[k]-ob[k%2])*s) for k in range(4)]
  return dict(box=list(box),size=box[2]-box[0],kind='manual_width',uncertainty_px=1)
 if mid=='alfheim_moon_stag':
  points=STAG_POINTS[ri]
  if old is not None:
   ob=old.getbbox();nb=im.getbbox();s=factor/meta(mid,row)['factor']
   points=[[round(nb[k]+(pt[k]-ob[k])*s,2) for k in range(2)] for pt in points]
  return dict(points=points,size=math.dist(*points),kind='manual_axis_length',uncertainty_px=1)
 a=np.array(im).astype(float);r,g,b,al=[a[:,:,k] for k in range(4)]
 if 'moth' in mid:
  mask=(r>190)&(g>170)&(b>210)&(al>0);gg=groups(mask)[0]
  size=math.sqrt(gg['area'])
 else:
  mask=(r>110)&(g>65)&(r>b*1.6)&(g>b*1.4)&(al>0)
  gs=groups(mask)
  if 'ram' in mid:
   # Largest gold component above the leg line is the near curled horn.
   gs=[gr for gr in gs if gr['box'][1]<55 and gr['box'][2]>50]
   gg=max(gs,key=lambda gr:gr['area']);size=gg['box'][3]-gg['box'][1]
  else:
   cx=60 if row=='defeat' else 49;cy=48 if row=='defeat' else 50
   gg=min(gs,key=lambda gr:math.dist(((gr['box'][0]+gr['box'][2])/2,(gr['box'][1]+gr['box'][3])/2),(cx,cy)))
   size=gg['box'][2]-gg['box'][0]
 return dict(box=gg['box'],size=size,kind='connected_colour_pixels',uncertainty_px=0,area=gg['area'])

def prepare(mid,row):
 key=(mid,row)
 if key not in PREP:
  path=ROOT/f'art/raw/monsters-71/{mid}-{row}.png'
  if not path.exists():raise FileNotFoundError(path)
  grid=(3,2) if COUNTS[row]==6 else (2,2) if COUNTS[row]==4 else (2,1)
  ims,_=n.split_sheet(path,grid)
  clean=[n.clean_background(im,'#00ff00')[0] for im in ims]
  n.validate_source_cell_margin(clean,[str(i) for i in range(len(clean))])
  PREP[key]=clean
 return PREP[key]

def render_raw(mid,row,factor):
 clean=prepare(mid,row);m=metrics(mid,row);s=m['summary'];ground=s['ground_all'] or (mid=='asgard_aegis_ram' and row=='attack')
 source_ground=max(im.getbbox()[3]-1 for im in clean)
 oldims=frames(OLD/f'{mid}-{row}-v1.png',COUNTS[row]);result=[];placements=[]
 for i,src in enumerate(clean):
  work,_,_=n.normalize_frame(src,factor,source_ground,None,'off','lanczos',60,'auto',s['common_offset_x'],ground,0,1,256,152)
  box=work.getbbox();w,h=box[2]-box[0],box[3]-box[1];x=box[0]-80;y=box[1]-80
  if not ground:
   pass
  # Original live flyers were aligned to raw anatomical landmarks, not feet.
  align=m.get('body_alignment',{}).get('frames',[])
  if align and row!='defeat':
   point=align[i]['source_point'];sb=src.getbbox();target=align[i].get('body_centre_after',align[i]['target'])
   current=[x+(point[0]-sb[0])*factor,y+(point[1]-sb[1])*factor]
   x+=round(target[0]-current[0]);y+=round(target[1]-current[1])
  if mid=='alfheim_moon_stag' and row=='attack':
   target=oldims[i].getbbox()[3]-1;y=target-h+1
  if w>90 or h>90:raise ValueError(f'{mid}/{row} F{i+1}: {w}x{h} exceeds 90px')
  dx=max(3-x,min(0,93-w-x));dy=max(3-y,min(0,93-h-y))
  # Grounded rows must keep y72. If height cannot fit, lower the row factor.
  grounded=ground and not (mid in ['asgard_runic_raven','alfheim_moon_moth'] and row!='defeat')
  if grounded and dy:raise ValueError(f'{mid}/{row} F{i+1}: grounded height {h} top {y}')
  x+=dx;y+=dy;out=Image.new('RGBA',(96,96));out.alpha_composite(work.crop(box),(x,y));result.append(out)
  assert np.count_nonzero(np.array(out)[:,:,3])==np.count_nonzero(np.array(work)[:,:,3])
  placements.append(dict(frame=i+1,output_bbox=out.getbbox(),translation_from_work=[x-box[0],y-box[1]],margin_adjustment=[dx,dy]))
 return result,placements

def rebuild(write=False):
 output={}
 for mid in IDS:
  output[mid]=[]
  for ri,row in enumerate(ROWS):
   f=FACTORS[mid][ri];oldfactor=meta(mid,row)['factor'];changed=f!=oldfactor or (mid=='asgard_aegis_ram' and row=='attack')
   oldims=frames(OLD/f'{mid}-{row}-v1.png',COUNTS[row]);idx=sample_index(mid,row)
   if changed:
    try:ims,placement=render_raw(mid,row,f)
    except ValueError as exc:
     if write:raise
     print(str(exc));continue
   else:ims=oldims;placement=[]
   before=feature(mid,row,oldims[idx]);after=feature(mid,row,ims[idx],oldims[idx],f)
   print(mid,row,oldfactor,'->',f,round(before['size'],2),'->',round(after['size'],2),'changed',changed)
   item=dict(monster=mid,row=row,frame=idx+1,part=PARTS[mid],before=before,after=after,before_factor=oldfactor,after_factor=f,changed=changed,placement=placement)
   if mid=='alfheim_moon_moth' and row=='attack':
    item['last_frame']=dict(frame=6,before=feature(mid,row,oldims[5]),after=feature(mid,row,ims[5]))
   output[mid].append(item)
   if write and changed:
    n.save_sheet(ims,BAKE/f'{mid}-{row}-v1.png',96)
    mm=meta(mid,row);mm['factor']=f;mm['note']+=' ART-71 fix-1: 원본에서 행 공통 배율로 idle 크기 보정.'
    if mid=='asgard_aegis_ram' and row=='attack':mm['note']+=' 전 프레임 발 y72 접지(프레임 전체 평행 이동).'
    (BAKE/f'{mid}-{row}-v1.json').write_text(json.dumps(mm,ensure_ascii=False,indent=2)+'\n','utf-8')
  if write:
   sheet=Image.new('RGBA',(576,576))
   for ri,row in enumerate(ROWS):sheet.alpha_composite(Image.open(BAKE/f'{mid}-{row}-v1.png').convert('RGBA'),(0,96*ri))
   sheet.save(BAKE/f'{mid}_sheet-v1.png')
 for mid,items in output.items():
  if not items:continue
  for item in items:
   item['before_ratio']=item['before']['size']/items[0]['before']['size'];item['after_ratio']=item['after']['size']/items[0]['after']['size']
   item['within_5_percent']=.95<=item['after_ratio']<=1.05
   if 'last_frame' in item:
    last=item['last_frame'];last['before_ratio']=last['before']['size']/items[0]['before']['size'];last['after_ratio']=last['after']['size']/items[0]['after']['size'];last['within_5_percent']=.95<=last['after_ratio']<=1.05
 print('SIZE FAILURES',[(mid,x['row'],round(x['after_ratio'],3)) for mid,items in output.items() for x in items if not x['within_5_percent']])
 if write:(FIX/'sizes.json').write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n','utf-8')

def evidence():
 data=json.loads((FIX/'sizes.json').read_text('utf-8'))
 for mid,items in data.items():
  # 6 columns; exact 4x artwork, before above after. Separate full-row boards
  # are small enough to inspect at native size without browser downsampling.
  board=Image.new('RGB',(1272,4*432),(24,29,40))
  for ri,item in enumerate(items):
   row=item['row'];idx=item['frame']-1
   for side,base in enumerate([OLD,BAKE]):
    im=frames(base/f'{mid}-{row}-v1.png',COUNTS[row])[idx];f=item['before' if side==0 else 'after']
    size=f['size'];ratio=item['before_ratio' if side==0 else 'after_ratio']
    tt=tile(im,f'{row} F{idx+1} {"BEFORE" if side==0 else "AFTER"} {size:.2f}px / {ratio:.3f}',f.get('box'))
    if 'points' in f:
     d=ImageDraw.Draw(tt);pts=[(32+p[0]*4,36+p[1]*4) for p in f['points']];d.line(pts,fill='#ff74bc',width=2)
     for p in pts:d.ellipse((p[0]-3,p[1]-3,p[0]+3,p[1]+3),fill='#ff74bc')
    board.paste(tt,(((ri%3)*424),((ri//3)*2+side)*432))
   if item['changed']:
    for base,suffix in [(OLD,'before'),(BAKE,'after')]:
     ims=frames(base/f'{mid}-{row}-v1.png',COUNTS[row]);panel=Image.new('RGB',(1272,math.ceil(len(ims)/3)*432),(24,29,40))
     for i,im in enumerate(ims):panel.paste(tile(im,f'{row} F{i+1} / {suffix}'),((i%3)*424,(i//3)*432))
     panel.save(FIX/f'{mid}-{row}-{suffix}-all-4x.png')
  board.save(FIX/f'{mid}-size-before-after-4x.png')
 # Compact overview of the 11 changed rows: a representative before/after.
 changed=[x for items in data.values() for x in items if x['changed']]
 overview=Image.new('RGB',(848,len(changed)*240),(24,29,40));d=ImageDraw.Draw(overview)
 for k,item in enumerate(changed):
  mid=item['monster'];row=item['row'];idx=item['frame']-1;y=k*240
  d.text((8,y+2),f'{mid} / {row}  {item["before_ratio"]:.3f} -> {item["after_ratio"]:.3f}',font=FONT,fill='white')
  for j,base in enumerate([OLD,BAKE]):
   im=frames(base/f'{mid}-{row}-v1.png',COUNTS[row])[idx]
   bg=n.checker((192,192),16);large=im.resize((192,192),Image.Resampling.NEAREST);bg.paste(large,(0,0),large)
   overview.paste(bg,(j*424+100,y+26));d.text((j*424+10,y+30),'BEFORE' if j==0 else 'AFTER',font=FONT,fill='white')
 overview.save(FIX/'overview-2x.png')
 feet=Image.new('RGB',(1272,864),(24,29,40))
 for side,base in enumerate([OLD,BAKE]):
  ims=frames(base/'asgard_aegis_ram-attack-v1.png',6)
  for j,i in enumerate([3,4,5]):
   y=ims[i].getbbox()[3]-1;feet.paste(tile(ims[i],f'charge F{i+1} {"BEFORE" if side==0 else "AFTER"}: foot y{y}'),(j*424,side*432))
 feet.save(FIX/'ram-feet-before-after-4x.png')

def verify():
 data=json.loads((FIX/'sizes.json').read_text('utf-8'));fail=[];checks=[];raws={}
 hashes=json.loads((FIX/'baseline-hashes.json').read_text('utf-8'))
 for mid,items in data.items():
  sheet=Image.open(BAKE/f'{mid}_sheet-v1.png').convert('RGBA');assert sheet.size==(576,576)
  for ri,item in enumerate(items):
   row=item['row'];path=BAKE/f'{mid}-{row}-v1.png';im=Image.open(path).convert('RGBA');ims=frames(path,COUNTS[row])
   assert im.size==(576,96)
   assert np.array_equal(np.array(im),np.array(sheet.crop((0,96*ri,576,96*(ri+1)))))
   assert im.crop((96*COUNTS[row],0,576,96)).getbbox() is None if COUNTS[row]<6 else True
   rows=[]
   for i,f in enumerate(ims):
    box=f.getbbox();margin=n.margins(box,96)['minimum'];binary=set(f.getchannel('A').get_flattened_data())<={0,255};spill=n.spill_pixel_count(f)
    detail=n.interior_detail(f);assert margin>=3 and binary and spill==0,(mid,row,i,margin,binary,spill)
    rows.append(dict(frame=i+1,bbox=box,margin=margin,bottom=box[3]-1,alpha_binary=binary,spill=spill,detail=detail))
   assert len({hashlib.sha256(f.tobytes()).hexdigest() for f in ims})==len(ims)
   assert item['within_5_percent'],(mid,row,item['after_ratio'])
   if 'last_frame' in item:assert item['last_frame']['within_5_percent']
   if not item['changed']:
    for ext in ['png','json']:assert sha(BAKE/f'{mid}-{row}-v1.{ext}')==sha(OLD/f'{mid}-{row}-v1.{ext}')
   metadata=json.loads(path.with_suffix('.json').read_text('utf-8'));assert metadata['factor']==item['after_factor']
   for key in ['fps','frames','loop','cell','feet']:assert metadata[key]==meta(mid,row)[key]
   raw=ROOT/f'art/raw/monsters-71/{mid}-{row}.png';rawkey=raw.relative_to(ROOT).as_posix();assert sha(raw)==hashes[rawkey];raws[rawkey]=sha(raw)
   checks.append(dict(monster=mid,row=row,changed=item['changed'],ratio=item['after_ratio'],frames=rows))
 ram_before=frames(OLD/'asgard_aegis_ram-attack-v1.png',6);ram_after=frames(BAKE/'asgard_aegis_ram-attack-v1.png',6)
 beforefeet=[f.getbbox()[3]-1 for f in ram_before];afterfeet=[f.getbbox()[3]-1 for f in ram_after];assert afterfeet==[72]*6
 report=dict(monsters=6,rows=36,frames=sum(COUNTS.values())*6,changed_rows=sum(x['changed'] for x in checks),failures=fail,ram_feet_before=beforefeet,ram_feet_after=afterfeet,raw_hashes_unchanged=True,checks=checks)
 (FIX/'verification.json').write_text(json.dumps(report,indent=2)+'\n','utf-8')
 print('VERIFIED',report['monsters'],report['rows'],report['frames'],'changed',report['changed_rows'],'ram feet',beforefeet,'->',afterfeet)

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def frames(path,count):
 im=Image.open(path).convert('RGBA')
 return [im.crop((96*i,0,96*(i+1),96)) for i in range(count)]
def meta(mid,row):return json.loads((OLD/f'{mid}-{row}-v1.json').read_text('utf-8'))
def metrics(mid,row):return json.loads((ROOT/f'reports/codex-art-71/{mid}/{row}/metrics.json').read_text('utf-8'))
def selected(row):return 1 if row=='hurt' else 0

def bootstrap():
 OLD.mkdir(exist_ok=True)
 paths=[]
 for mid in IDS:
  for row in ROWS:
   for ext in ['png','json']:paths.append(BAKE/f'{mid}-{row}-v1.{ext}')
  paths.append(BAKE/f'{mid}_sheet-v1.png')
 for path in paths:
  dest=OLD/path.name
  if not dest.exists():shutil.copy2(path,dest)
 inv={p.relative_to(ROOT).as_posix():sha(p) for p in paths}
 inv.update({p.relative_to(ROOT).as_posix():sha(p) for mid in IDS for row in ROWS for p in [ROOT/f'art/raw/monsters-71/{mid}-{row}.png'] if p.exists()})
 (FIX/'baseline-hashes.json').write_text(json.dumps(inv,indent=2),'utf-8')
 for mid in IDS:representatives(mid)

def tile(im,label,box=None):
 out=Image.new('RGB',(424,432),(24,29,40));d=ImageDraw.Draw(out)
 d.text((8,4),label,font=FONT,fill='white')
 bg=n.checker((384,384),32);bg.paste(im.resize((384,384),Image.Resampling.NEAREST),(0,0),im.resize((384,384),Image.Resampling.NEAREST))
 out.paste(bg,(32,36));d=ImageDraw.Draw(out)
 for v in range(0,97,8):
  d.text((32+v*4-5,22),str(v),font=SMALL,fill='#aebdd0');d.text((8,36+v*4-6),str(v),font=SMALL,fill='#aebdd0')
 d.line((32,36+72*4,415,36+72*4),fill='#8c3549')
 if box:d.rectangle(tuple([32+box[0]*4,36+box[1]*4,32+box[2]*4-1,36+box[3]*4-1]),outline='#ff74bc',width=2)
 return out

def representatives(mid):
 board=Image.new('RGB',(1272,864),(24,29,40))
 for ri,row in enumerate(ROWS):
  idx=selected(row);im=frames(OLD/f'{mid}-{row}-v1.png',COUNTS[row])[idx]
  board.paste(tile(im,f'{row} F{idx+1}'),((ri%3)*424,(ri//3)*432))
 board.save(FIX/f'{mid}-measure-before-4x.png')

def crops():
 regions={
 'mossling':[(58,43,89,66),(60,44,92,66),(59,47,92,69),(58,47,90,72),(58,46,88,68),(58,47,89,72)],
 'ember_imp':[(40,18,80,52),(38,18,78,52),(40,18,80,52),(40,25,80,59),(40,26,80,60),(48,12,88,46)],
 'alfheim_moon_stag':[(48,23,76,44),(49,24,79,46),(49,22,82,45),(52,46,82,64),(49,35,79,55),(49,24,82,49)],
 }
 for mid,boxes in regions.items():
  board=Image.new('RGB',(3*448,2*480),(24,29,40));d=ImageDraw.Draw(board)
  for ri,(row,box) in enumerate(zip(ROWS,boxes)):
   im=frames(OLD/f'{mid}-{row}-v1.png',COUNTS[row])[selected(row)]
   im=im.crop(box);bg=n.checker(im.size,4);bg.paste(im,(0,0),im)
   x=(ri%3)*448+36;y=(ri//3)*480+40
   board.paste(bg.resize((im.width*12,im.height*12),Image.Resampling.NEAREST),(x,y))
   d.text((x,y-36),row,font=FONT,fill='white')
   for v in range(box[0],box[2]+1):
    if v%2==0:d.text((x+(v-box[0])*12,y-18),str(v),font=SMALL,fill='white')
   for v in range(box[1],box[3]+1):
    if v%2==0:d.text((x-26,y+(v-box[1])*12),str(v),font=SMALL,fill='white')
  board.save(FIX/f'{mid}-head-crops-12x.png')

def probes():
 from collections import deque
 for mid in ['asgard_aegis_ram','asgard_runic_raven','alfheim_moon_moth']:
  board=Image.new('RGB',(1272,864),(24,29,40));data=[]
  for ri,row in enumerate(ROWS):
   im=frames(OLD/f'{mid}-{row}-v1.png',COUNTS[row])[selected(row)]
   a=np.array(im).astype(float);r,g,b,al=[a[:,:,k] for k in range(4)]
   if 'moth' in mid:mask=(r>190)&(g>170)&(b>210)&(al>0)
   else:mask=(r>110)&(g>65)&(r>b*1.6)&(g>b*1.4)&(al>0);mask[58:]=False
   seen=np.zeros(mask.shape,bool);groups=[]
   for sy,sx in zip(*np.where(mask)):
    if seen[sy,sx]:continue
    q=deque([(int(sx),int(sy))]);seen[sy,sx]=True;pts=[]
    while q:
     x,y=q.popleft();pts.append((x,y))
     for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
      if 0<=nx<96 and 0<=ny<96 and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
    if len(pts)>6:
     xs,ys=zip(*pts);groups.append(dict(area=len(pts),box=[min(xs),min(ys),max(xs)+1,max(ys)+1]))
   groups.sort(key=lambda z:-z['area']);data.append(dict(row=row,groups=groups[:8]))
   tt=tile(im,row);d=ImageDraw.Draw(tt)
   for gi,gr in enumerate(groups[:4]):
    box=gr['box'];d.rectangle((32+box[0]*4,36+box[1]*4,32+box[2]*4-1,36+box[3]*4-1),outline='#ff74bc');d.text((32+box[0]*4,36+box[1]*4),str(gi),font=FONT,fill='#ff74bc')
   board.paste(tt,((ri%3)*424,(ri//3)*432))
  board.save(FIX/f'{mid}-probes-4x.png')
  (FIX/f'{mid}-probes.json').write_text(json.dumps(data,indent=2),'utf-8')
  print(mid,json.dumps(data))

def allrows(mid,base=OLD,suffix='before'):
 for row in ROWS:
  ims=frames(base/f'{mid}-{row}-v1.png',COUNTS[row]);board=Image.new('RGB',(3*424,math.ceil(len(ims)/3)*432),(24,29,40))
  for i,im in enumerate(ims):board.paste(tile(im,f'{mid} {row} F{i+1} / {suffix}'),((i%3)*424,(i//3)*432))
  board.save(FIX/f'{mid}-{row}-{suffix}-all-4x.png')

if __name__=='__main__':
 if sys.argv[1]=='bootstrap':bootstrap()
 elif sys.argv[1]=='crops':crops()
 elif sys.argv[1]=='probes':probes()
 elif sys.argv[1]=='allrows':allrows(sys.argv[2])
 elif sys.argv[1]=='preview':rebuild(False)
 elif sys.argv[1]=='rebuild':rebuild(True)
 elif sys.argv[1]=='evidence':evidence()
 elif sys.argv[1]=='verify':verify()
