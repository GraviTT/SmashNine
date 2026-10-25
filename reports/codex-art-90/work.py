"""ART-90 local processing; writes only this report and art/raw/art-90."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import sys,json,hashlib,shutil,importlib.util
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-90'
RAW=ROOT/'art/raw/art-90'
BAKE=ROOT/'art/bakeoff'
RAW.mkdir(parents=True,exist_ok=True)
def js(p,x): Path(p).write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def load(p):return Image.open(p).convert('RGBA')
def module(name,p):
 s=importlib.util.spec_from_file_location(name,ROOT/p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
n=module('normalizer','tools/sprite_pipeline/normalize.py')
def copy(p):
 p=Path(p);p=p if p.is_absolute() else ROOT/p
 dst=RAW/'inputs'/p.relative_to(ROOT);dst.parent.mkdir(parents=True,exist_ok=True)
 if not dst.exists():shutil.copy2(p,dst)
 return dst
def frames(p,count=None,cell=None):
 im=load(p);cell=cell or im.height
 return [im.crop((i*cell,0,(i+1)*cell,cell)) for i in range(count or im.width//cell)]
def strip(fs,cell=96):
 im=Image.new('RGBA',(6*cell,cell))
 for i,f in enumerate(fs):im.paste(f,(i*cell,0))
 return im
def board(p,groups,title,scale=4):
 # Each group is one line: label + up to three frames. Exact nearest 1x/4x.
 cw=max(f.width for _,fs in groups for f in fs);ch=max(f.height for _,fs in groups for f in fs)
 w=max(len(fs) for _,fs in groups)*(cw*scale+16)+24;h=len(groups)*(ch*scale+38)+32
 im=Image.new('RGB',(w,h),(29,33,43));d=ImageDraw.Draw(im)
 d.text((12,6),title,fill='white')
 for row,(label,fs) in enumerate(groups):
  y=32+row*(ch*scale+38);d.text((12,y),label,fill='white')
  for i,f in enumerate(fs):
   x=12+i*(cw*scale+16);bg=n.checker((cw*scale,ch*scale),8*scale).convert('RGB')
   z=f.resize((f.width*scale,f.height*scale),Image.Resampling.NEAREST);bg.paste(z,(0,0),z);im.paste(bg,(x,y+20))
 im.save(p)
def baseline():
 paths=list((BAKE/'monsters').glob('yggdrasil_root_guardian*'))+list((BAKE/'monsters').glob('vanaheim_vine_hound*'))+list((BAKE/'monsters/legacy').glob('alfheim_moon_stag_sheet-fix1.*'))
 paths += list((BAKE/'luna').glob('luna-fall-v3.*'))+list((BAKE/'luna').glob('luna-idle-v3.*'))+list((BAKE/'nova').glob('*meteor_kick*'))+list((BAKE/'nova').glob('*idle*'))
 for p in paths:copy(p)
 for row in ['attack','defeat','idle']:copy(f'art/raw/monsters-76/yggdrasil_root_guardian-{row}.png')
 copy('smash-nine-prototype/assets/art/monsters/alfheim_moon_stag_source.png')
 protected={}
 for base in ['art/bakeoff','qa23','tools','smash-nine-prototype']:
  for p in (ROOT/base).rglob('*'):
   if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.import']:
    protected[str(p.relative_to(ROOT)).replace('\\','/')]=sha(p)
 js(REPORT/'baseline.json',protected)
def guardian_trials():
 for row,grid,factor in [('attack',(3,2),.1785),('defeat',(2,2),.1425)]:
  src=n.split_sheet(copy(f'art/raw/monsters-76/yggdrasil_root_guardian-{row}.png'),grid)[0][0]
  clean,_=n.clean_background(src,'#00ff00');b=clean.getbbox()
  old=frames(copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-'+('v1' if row=='attack' else 'v2')+'.png'),1)[0]
  trials=[]
  for pad in [0,4,8,12,20,30,40]:
   z=clean.crop((b[0]-pad,b[1]-pad,b[2]+pad,b[3]+pad));z=z.resize((round(z.width*factor),round(z.height*factor)),Image.Resampling.LANCZOS)
   z=n.apply_unsharp(z,60);z.putalpha(z.getchannel('A').point(lambda v:255 if v>=128 else 0));z=n.despill_green_edge(z,'auto');z=z.crop(z.getbbox())
   out=Image.new('RGBA',(96,96));out.paste(z,((96-z.width)//2,73-z.height));out.save(RAW/f'guardian-{row}-pad{pad}.png')
   trials.append(dict(pad=pad,bbox=out.getbbox(),detail=n.interior_detail(out)))
  js(RAW/f'guardian-{row}-trials.json',trials)
  board(RAW/f'guardian-{row}-trials.png',[(f'old / pad0 / pad4',[old,load(RAW/f'guardian-{row}-pad0.png'),load(RAW/f'guardian-{row}-pad4.png')]),('pad8 / pad12 / pad20',[load(RAW/f'guardian-{row}-pad{k}.png') for k in [8,12,20]]),('pad30 / pad40',[load(RAW/f'guardian-{row}-pad{k}.png') for k in [30,40]])],row)
  print(row,trials)
def guardian():
 for row,ver in [('attack','v1'),('defeat','v2')]:
  p=copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-{ver}.png');old=load(p);f=old.crop((0,0,96,96))
  z=load(RAW/f'guardian-{row}-pad4.png');b=z.getbbox();ob=f.getbbox();cut=z.crop(b)
  new=Image.new('RGBA',(96,96));x=round((ob[0]+ob[2]-cut.width)/2);new.paste(cut,(x,73-cut.height))
  out=old.copy();out.paste(new,(0,0));out.save(RAW/f'guardian-{row}-final.png')
  for sc in [1,4]:board(REPORT/f'guardian-{row}-{sc}x.png',[('BEFORE / AFTER / IDLE',[f,new,frames(copy('art/bakeoff/monsters/yggdrasil_root_guardian-idle-v1.png'),1)[0]])],f'{row} F1 | exact {sc}x',sc)
  print(row,'before',ob,'after',new.getbbox())
def hound_trials():
 p=copy('art/bakeoff/monsters/vanaheim_vine_hound-idle-v2.png');fs=frames(p,6)
 for i in range(2):
  board(RAW/f'hound-before-{i}.png',[(f'idle F{i*3+1}-{i*3+3}',fs[i*3:i*3+3])],'Hound before')
def speckle(im,strength=1):
 a=np.array(im);rgb=a[:,:,:3].astype(float);vis=a[:,:,3]>0
 # Restricted to foliage greens, excluding amber eyes and brown wood.
 leaf=(rgb[:,:,1]>rgb[:,:,0]*1.08)&(rgb[:,:,1]>rgb[:,:,2]*1.08)&vis
 nei=np.stack([np.roll(np.roll(rgb,dy,0),dx,1) for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]])
 valid=np.stack([np.roll(np.roll(leaf,dy,0),dx,1) for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]])
 med=np.median(nei,axis=0);delta=rgb.mean(2)-med.mean(2)
 # Protect bright eye cores and their 3px neighbourhood, including coloured iris edges.
 eye=(rgb[:,:,0]>150)&(rgb[:,:,1]>180)&(rgb[:,:,2]>100)&vis
 protected=np.asarray(Image.fromarray((eye*255).astype('uint8')).filter(ImageFilter.MaxFilter(7)))>0
 mask=leaf&(valid.sum(0)>=6)&(np.abs(delta)>25)&~protected
 b=a.copy();b[mask,:3]=np.clip(np.rint(rgb[mask]*(1-strength)+med[mask]*strength),0,255).astype('uint8')
 return Image.fromarray(b),int(mask.sum())
def hound():
 result=[]
 for row,count in zip(['idle','walk','windup','attack','hurt','defeat'],[6,6,4,6,2,4]):
  p=copy(f'art/bakeoff/monsters/vanaheim_vine_hound-{row}-v2.png');old=frames(p,count);new=[];counts=[]
  for f in old:
   z,c=speckle(f,.8);new.append(z);counts.append(c)
  strip(new).save(RAW/f'hound-{row}-final.png')
  for sc in [1,4]:
   for part in range((count+2)//3):
    idx=slice(part*3,part*3+3)
    board(REPORT/f'hound-{row}-{sc}x-{part+1}.png',[(f'BEFORE F{part*3+1}-{min(count,part*3+3)}',old[idx]),('AFTER',new[idx])],f'hound {row} | exact {sc}x',sc)
  result.append(dict(row=row,changed_pixels=counts,detail_before=[n.interior_detail(f) for f in old],detail_after=[n.interior_detail(f) for f in new]))
 js(RAW/'hound-trial-metrics.json',result);print(result)
def stag_prepare():
 # Use a byte-identical copy of ART-87's background-separated source, already reviewed there.
 transparent=copy('art/raw/monsters-87/alfheim_moon_stag_transparent.png');src=load(transparent)
 rects=[[20,574,311,756],[315,570,623,756],[634,574,1000,756]]
 for i,rect in enumerate(rects):src.crop(rect).save(RAW/f'stag-attack-source-F{i+1}.png')
 src.crop((20,20,257,260)).save(RAW/'stag-idle-source.png')
 for name in ['alfheim_moon_stag_sheet.png']:copy('smash-nine-prototype/assets/art/monsters/'+name)
 board(RAW/'stag-source-reference.png',[('SOURCE IDLE / ATTACK F1 / ATTACK F2',[load(RAW/'stag-idle-source.png'),load(RAW/'stag-attack-source-F1.png'),load(RAW/'stag-attack-source-F2.png')])],'Legacy stag source reference',2)
def heads_prepare():
 for char,anchor,target,cnt in [('luna','luna-idle-v3','luna-fall-v3',2),('nova','nova_female-idle-v2','nova_female-meteor_kick-v1',6),('nova','nova_male-idle-v2','nova_male-meteor_kick-v1',6)]:
  a=frames(copy(f'art/bakeoff/{char}/{anchor}.png'),1)[0];fs=frames(copy(f'art/bakeoff/{char}/{target}.png'),cnt)
  for part in range((cnt+1)//2):
   board(REPORT/f'{target}-heads-4x-{part+1}.png',[('ANCHOR / F'+str(part*2+1)+' / F'+str(min(cnt,part*2+2)),[a]+fs[part*2:part*2+2])],target+' | whole frames / 4x',4)
def head_crops():
 h=module('headscale','tools/sprite_pipeline/head_scale.py');data=[]
 for char,anchor,target,cnt in [('luna','luna-idle-v3','luna-fall-v3',2),('nova','nova_female-idle-v2','nova_female-meteor_kick-v1',6),('nova','nova_male-idle-v2','nova_male-meteor_kick-v1',6)]:
  a=frames(copy(f'art/bakeoff/{char}/{anchor}.png'),1)[0];fs=[a]+frames(copy(f'art/bakeoff/{char}/{target}.png'),cnt)
  crops=[];recs=[]
  for i,f in enumerate(fs):
   cy,cx=h.face_centre(np.asarray(f));box=(round(cx)-26,round(cy)-25,round(cx)+26,round(cy)+27);c=f.crop(box);crops.append(c)
   recs.append(dict(frame='anchor' if i==0 else i,box=box,centre=[cx,cy]))
   z=c.resize((624,624),Image.Resampling.NEAREST);bg=n.checker(z.size,24).convert('RGB');bg.paste(z,(0,0),z);d=ImageDraw.Draw(bg)
   for x in range(0,52,2):d.text((x*12,0),str(box[0]+x),fill='yellow')
   for y in range(0,52,2):d.text((0,y*12),str(box[1]+y),fill='yellow')
   bg.save(RAW/f'{target}-face-{i}-grid12x.png')
  board(REPORT/f'{target}-faces-4x.png',[(f'ANCHOR, THEN F1-F{cnt}',crops)],target+' | exact 4x face crops',4)
  data.append(dict(target=target,crops=recs))
 js(RAW/'head-crops.json',data)
def stag_trial():
 src=load(copy('art/raw/monsters-87/alfheim_moon_stag_transparent.png'));old=load(copy('art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.png'))
 out=old.copy();fs=[];records=[]
 for i,(p,rect,fac) in enumerate([(src,[20,574,311,756],.294),(src,[315,570,623,756],.294),(load(RAW/'stag-F3-generated.png'),None,.065),(load(RAW/'stag-F4-generated.png'),None,.075)]):
  z=p.crop(rect) if rect else p
  arr=np.array(z);arr[arr[:,:,3]<41]=0;z=Image.fromarray(arr)
  # All small alpha components are generation/background fragments, not copied anatomy.
  z,_=n.drop_small_components(z,20);b=z.getbbox();z=z.crop(b)
  z=z.resize((round(z.width*fac),round(z.height*fac)),Image.Resampling.LANCZOS)
  rgb=z.convert('RGB').filter(ImageFilter.UnsharpMask(radius=1,percent=60,threshold=3));rgb.putalpha(z.getchannel('A'));z=rgb
  arr=np.array(z);arr[arr[:,:,3]<32]=0;z=Image.fromarray(arr);z=z.crop(z.getbbox())
  f=Image.new('RGBA',(96,96));at=((96-z.width)//2,72-z.height);f.paste(z,at);fs.append(f);out.paste(f,(96*i,192))
  records.append(dict(frame=i+1,source_region=rect,source_alpha_bbox=b,scale=fac,placement=at,bbox=f.getbbox()))
 out.save(RAW/'stag-trial.png');js(RAW/'stag-trial.json',records)
 for sc in [1,4]:
  for part in range(2):
   board(REPORT/f'stag-attack-{sc}x-{part+1}.png',[(f'BEFORE F{part*2+1}-{part*2+2}',[old.crop((i*96,192,(i+1)*96,288)) for i in range(part*2,part*2+2)]),('AFTER',fs[part*2:part*2+2]),('IDLE / WALK',[old.crop((0,0,96,96)),old.crop((0,96,96,192))])],f'legacy stag | exact {sc}x',sc)
 print(records)
def face_grids():
 cfg=json.loads((RAW/'head-crops.json').read_text('utf-8'))
 for entry in cfg:
  target=entry['target'];char='luna' if target.startswith('luna') else 'nova'
  anchor='luna-idle-v3' if char=='luna' else target.split('-')[0]+'-idle-v2'
  fs=frames(BAKE/char/(anchor+'.png'),1)+frames(BAKE/char/(target+'.png'),len(entry['crops'])-1)
  for i,(f,rec) in enumerate(zip(fs,entry['crops'])):
   cx,cy=rec['centre'];x0=round(cx)-16;y0=round(cy)-11;w=32;hh=25;s=20
   z=f.crop((x0,y0,x0+w,y0+hh)).resize((w*s,hh*s),Image.Resampling.NEAREST)
   bg=Image.new('RGB',(w*s+40,hh*s+40),(29,33,43));bg.paste(z,(40,40),z);d=ImageDraw.Draw(bg)
   for x in range(w):d.text((40+x*s,18),str(x0+x),fill='yellow');d.line((40+x*s,40,40+x*s,40+hh*s),fill=(64,64,64))
   for y in range(hh):d.text((5,40+y*s),str(y0+y),fill='yellow');d.line((40,40+y*s,40+w*s,40+y*s),fill=(64,64,64))
   bg.save(RAW/f'{target}-face-{i}-coordinates.png')
def nova_landmarks():
 # Manually located eye pairs and exposed cheek edges, inspected on 4x crops.
 # Pixel-centre coordinates; far eye is partly hidden by the frontal hair.
 marks={
 'male':[
 [[72,58],[80,58.5],[66,59.5],[82,59.5]],
 [[102,60],[110.5,60.5],[95,61],[112,61]],
 [[101,72],[109.5,72.5],[94,73],[111,73]],
 [[100.5,74.5],[108.5,74.5],[94,75],[110.5,75]],
 [[101.5,81],[110,81.5],[95,82],[112,82]],
 [[104.5,111],[113.5,111.5],[98,112],[115,112]],
 [[106,109.5],[114.5,109.5],[100,111],[117,111]],
 ],
 'female':[
 [[72,59.5],[80,59.5],[66.5,61],[81.5,61]],
 [[99,72.5],[107,73],[93,74],[108,74]],
 [[102.5,77],[110,77.5],[96,78],[111.5,78]],
 [[101,84.5],[109,85],[94.5,86],[110.5,86]],
 [[101,80],[109,80.5],[94.5,81.5],[110,81.5]],
 [[102.5,96],[110.5,96.5],[96,97],[111.5,97]],
 [[104,83.5],[112,84],[97.5,85],[113,85]],
 ]}
 result=[]
 for sex,allmarks in marks.items():
  fs=frames(BAKE/f'nova/nova_{sex}-idle-v2.png',1)+frames(BAKE/f'nova/nova_{sex}-meteor_kick-v1.png',6)
  refeye=float(np.linalg.norm(np.array(allmarks[0][0])-allmarks[0][1]));refwidth=allmarks[0][3][0]-allmarks[0][2][0];recs=[];panels=[]
  for i,(f,mm) in enumerate(zip(fs,allmarks)):
   eye=float(np.linalg.norm(np.array(mm[0])-mm[1]));width=mm[3][0]-mm[2][0]
   recs.append(dict(frame='anchor' if i==0 else i,landmarks=mm,eye_distance=eye,face_width=width,eye_ratio=eye/refeye,face_width_ratio=width/refwidth))
   x0=round(mm[0][0])-16;y0=round(mm[0][1])-17
   z=f.crop((x0,y0,x0+40,y0+36)).resize((160,144),Image.Resampling.NEAREST)
   bg=Image.new('RGB',(180,210),(29,33,43));bg.paste(z,(10,30),z);d=ImageDraw.Draw(bg)
   d.text((4,5),'ANCHOR' if i==0 else f'F{i} E{eye/refeye:.3f} W{width/refwidth:.3f}',fill='white')
   for j,(x,y) in enumerate(mm):
    xx=10+(x-x0+.5)*4;yy=30+(y-y0+.5)*4;c='cyan' if j<2 else 'yellow';d.line((xx-3,yy,xx+3,yy),fill=c);d.line((xx,yy-3,xx,yy+3),fill=c)
   panels.append(bg)
  out=Image.new('RGB',(180*7,210));
  for i,z in enumerate(panels):out.paste(z,(i*180,0))
  out.save(REPORT/f'nova_{sex}-manual-landmarks-4x.png');result.append(dict(sex=sex,method='수동 4배 표식; 좌표는 셀 픽셀 중심, 눈/폭 끝점 ±0.5px 이상. 가림/시점 영향은 별도 판정.',frames=recs))
 js(REPORT/'nova-manual-first.json',result);print([(r['sex'],[(round(f['eye_ratio'],3),round(f['face_width_ratio'],3)) for f in r['frames']]) for r in result])
def nova_refine():
 data=json.loads((REPORT/'nova-manual-first.json').read_text('utf-8'));result=[]
 for item in data:
  sex=item['sex'];fs=frames(BAKE/f'nova/nova_{sex}-idle-v2.png',1)+frames(BAKE/f'nova/nova_{sex}-meteor_kick-v1.png',6)
  ar=np.asarray(fs[0].resize((512,512),Image.Resampling.NEAREST)).astype(float)[:,:,:3];marks=item['frames'][0]['landmarks'];rs=[]
  for i,f in enumerate(fs):
   fa=np.asarray(f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST)).astype(float)[:,:,:3];mm=[];scores=[]
   for j,(ax,ay) in enumerate(marks):
    ww,hh=(12,16);xx=round((ax+.5)*4);yy=round((ay+.5)*4);t=ar[yy-hh//2:yy+hh//2,xx-ww//2:xx+ww//2];t=t-t.mean();tn=np.sqrt((t*t).sum())
    ex,ey=item['frames'][i]['landmarks'][j];best=(-2,None)
    for y in range(round((ey+.5)*4)-6,round((ey+.5)*4)+7):
     for x in range(round((ex+.5)*4)-6,round((ex+.5)*4)+7):
      p=fa[y-hh//2:y+hh//2,x-ww//2:x+ww//2];p=p-p.mean();score=float((p*t).sum()/(tn*np.sqrt((p*p).sum())+1e-9))
      if score>best[0]:best=(score,[x/4-.5,y/4-.5])
    mm.append(best[1]);scores.append(best[0])
   ed=float(np.linalg.norm(np.array(mm[0])-mm[1]));width=mm[3][0]-mm[2][0]
   if i==0:refe=ed;refw=width
   rs.append(dict(frame=i,points=mm,scores=scores,eye=ed,width=width,eye_ratio=ed/refe,width_ratio=width/refw))
  result.append(dict(sex=sex,frames=rs));print(sex,[(r['frame'],round(r['eye_ratio'],3),round(r['width_ratio'],3),[round(x,2) for x in r['scores']]) for r in rs])
 js(RAW/'nova-refined-proposals.json',result)
def monster_grids():
 gs=[('guardian-idle',frames(BAKE/'monsters/yggdrasil_root_guardian-idle-v1.png',1)[0]),('guardian-attack',frames(RAW/'guardian-attack-final.png',1)[0]),('guardian-defeat',frames(RAW/'guardian-defeat-final.png',1)[0])]
 stag=load(RAW/'stag-trial.png');gs += [('stag-idle',stag.crop((0,0,96,96))),('stag-walk',stag.crop((0,96,96,192)))]+[(f'stag-F{i+1}',stag.crop((i*96,192,(i+1)*96,288))) for i in range(4)]
 for name,f in gs:
  s=8;bg=Image.new('RGB',(96*s+30,96*s+30),(29,33,43));z=f.resize((96*s,96*s),Image.Resampling.NEAREST);bg.paste(z,(30,30),z);d=ImageDraw.Draw(bg)
  for x in range(0,96,4):d.text((30+x*s,10),str(x),fill='yellow');d.line((30+x*s,30,30+x*s,96*s+30),fill=(64,64,64))
  for y in range(0,96,4):d.text((0,30+y*s),str(y),fill='yellow');d.line((30,30+y*s,96*s+30,30+y*s),fill=(64,64,64))
  bg.save(RAW/(name+'-grid.png'))
def small_summary():
 groups=[]
 for row,count in zip(['idle','walk','windup','attack','hurt','defeat'],[6,6,4,6,2,4]):
  groups.append((row+' BEFORE',frames(copy(f'art/bakeoff/monsters/vanaheim_vine_hound-{row}-v2.png'),count)))
  groups.append((row+' AFTER',frames(RAW/f'hound-{row}-final.png',count)))
 board(REPORT/'hound-all-1x.png',groups,'All 28 hound frames, exact 1x',1)
if __name__=='__main__':globals()[sys.argv[1]]()
