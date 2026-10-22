"""ART-74 review pass: raw rebuild, one factor per row, reference-derived colour LUT.

No product/tool writes, generation, git staging or Godot calls.
"""
import sys, os, json, hashlib, shutil, colorsys, statistics
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import process as p
from rebuild import CONFIG, NOTES
from refine import translate

FIX=p.REPORT/'fix-1'
BEFORE=FIX/'before'
FACTORS={
 'midgard_rooftop_slinger':[.2,.1875,.169,.233,.105,.167],
 'svartalfheim_gear_beetle':[.2,.2,.15,.198,.12,.153],
 'svartalfheim_cog_drone':[.2,.23257,.19044,.23545,.13726,.17412],
 'vanaheim_vine_hound':[.19,.19,.15,.205,.12,.164],
 'vanaheim_seed_sprite':[.19,.19,.16,.1935,.115,.145],
 'jotunheim_rune_golem':[.18,.188,.163,.186,.1275,.16],
}

def save_row(mid,row,ims,m):
 out=p.REPORT/mid/row
 for i,im in enumerate(ims):im.save(out/'frames'/f'{mid}-{row}-v1-{i:02d}.png')
 p.n.save_sheet(ims,p.BAKE/f'{mid}-{row}-v1.png',96)
 p.n.save_sheet(ims,out/f'{mid}-{row}-v1.png',96)
 p.n.write_visuals(ims,out,None,f'{mid} {row}',72,4)
 (out/'metrics.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
 p.audit(mid,row)

def rebuild(mid,row,factor,setting):
 oldfactor,offset,ground,feet=setting
 # A padded working canvas lets us translate an entire frame back inside the
 # 96px margins without any per-frame resizing or cutting of subject pixels.
 out=p.REPORT/mid/row
 count=p.COUNTS[row];grid='3x2' if count==6 else '2x2' if count==4 else '2x1'
 work=FIX/'work'/mid/row
 args=p.n.parser().parse_args(['--sheet',str(p.ROOT/f'art/raw/monsters-74/{mid}-{row}.png'),'--grid',grid,'--bg','#00ff00','--cell','128','--feet-y',str(feet+24),'--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--compare-scale','4','--out-dir',str(work),'--name',f'{mid}-{row}-v1','--offset-x',str(offset)]+(['--ground-all'] if ground else []))
 args.palette=None
 m=p.n.normalize(args);ims=[];moves=[]
 for i in range(count):
  src=Image.open(work/'frames'/f'{mid}-{row}-v1-{i:02d}.png').convert('RGBA');box=src.getbbox()
  w,h=box[2]-box[0],box[3]-box[1]
  assert w<=90 and h<=90,(mid,row,i,w,h)
  x=box[0]-16;y=box[1]-24
  dx=max(3-x,min(0,93-w-x));dy=max(3-y,min(0,93-h-y))
  dst=Image.new('RGBA',(96,96));dst.alpha_composite(src.crop(box),(x+dx,y+dy));ims.append(dst)
  moves.append(dict(frame=i+1,translation_from_128=[-16+dx,-24+dy],margin_translation=[dx,dy]))
 m['normalization'].update(cell=96,feet_y=72,working_canvas=128)
 m['review_rebuild']=dict(source_raw_sha256=hashlib.sha256((p.ROOT/f'art/raw/monsters-74/{mid}-{row}.png').read_bytes()).hexdigest(),old_factor=oldfactor,new_factor=factor,one_factor_per_row=True,whole_frame_placement=moves)
 save_row(mid,row,ims,m)
 meta=json.loads((BEFORE/f'{mid}-{row}-v1.json').read_text('utf-8'));meta['factor']=factor
 if row in NOTES[mid]:meta['note']=NOTES[mid][row]
 meta['note']+=' 행별 크기 재검수: 원본에서 공통 배율 하나로 재구축.'
 (p.BAKE/f'{mid}-{row}-v1.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n','utf-8')

def reference_ramp(mid,kind):
 path=p.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png'
 im=Image.open(path).convert('RGBA');a=np.array(im);rgb=a[:,:,:3][a[:,:,3]>0]
 hsv=np.array([colorsys.rgb_to_hsv(*(c/255)) for c in rgb])
 h,s,v=hsv.T
 if kind=='leaf':sel=(h>(.22 if 'hound' in mid else .18))&(h<.34)&(s>.35)&(v>.16)
 elif kind=='bark':sel=(h>.035)&(h<.115)&(s>.25)&(v>.13)
 else:sel=(h>.28)&(h<.42)&(v>.60)&(s>.08)
 rgb=rgb[sel];v=v[sel]
 # Five colour anchors sampled from the existing game palette. The median of
 # a narrow luminance band avoids colour spikes; interpolation keeps shading.
 anchors=[]
 for q in [.03,.25,.5,.75,.98]:
  value=float(np.quantile(v,q));order=np.argsort(abs(v-value))[:max(8,len(v)//40)]
  anchors.append(np.median(rgb[order],axis=0).round().astype(int).tolist())
 return anchors

def palette(mid):
 ramps={k:reference_ramp(mid,k) for k in ['leaf','bark','glow']}
 source=Image.open(BEFORE/f'{mid}-idle-v1.png').convert('RGBA');a=np.array(source);rgb=a[:,:,:3][a[:,:,3]>0]
 hsv=np.array([colorsys.rgb_to_hsv(*(c/255)) for c in rgb]);hh,ss,vv=hsv.T
 cuts={}
 for kind,sel in [('leaf',(hh>=.115)&(hh<.30)&(ss>.22)),('bark',(hh>=.015)&(hh<.115)&(ss>.22)),('glow',(hh>.38)&(hh<.65)&(vv>.60)&(ss>.15))]:
  cuts[kind]=np.quantile(vv[sel],[.03,.25,.5,.75,.98]).tolist()
 cache={}
 def remap(c):
  if c in cache:return cache[c]
  h,s,v=colorsys.rgb_to_hsv(*(np.array(c)/255))
  kind=None
  if v>.82 and s<.60:
   # White flower petals and the white-hot eye core stay white. This same
   # material-colour exception applies to every frame and every row.
   original=c
   if .38<h<.65:
    # Remove the cyan cast from near-white light without tinting the flower
    # petals dark green. The brighter eye core is white inside its green rim.
    neutral=round(v*255);c=tuple([neutral]*3)
   cache[original]=c;return c
  if .115<=h<.30 and s>.22:kind='leaf'
  elif .015<=h<.115 and s>.22:kind='bark' if 'hound' in mid else 'leaf'
  elif .38<h<.65 and v>.45 and s>.15:kind='glow'
  if kind:
   ramp=np.array(ramps[kind],float);knots=cuts[kind]
   # Do not quantize to a small palette: interpolate the sampled reference
   # anchors, preserving continuous luminance differences in the source.
   result=tuple(int(np.clip(round(np.interp(v,knots,ramp[:,k])),0,255)) for k in range(3))
   if kind in ['leaf','bark'] and 'hound' in mid:
    # Preserve the raw's fine light/dark separation while taking hue and
    # saturation from the existing sheet. Pure percentile compression made
    # the bark too flat at 1x. This is still one RGB-only LUT for all rows.
    mapped_value=max(result)/255
    target_value=.65*v+.35*mapped_value
    result=tuple(int(np.clip(round(c*target_value/max(mapped_value,1e-6)),0,255)) for c in result)
  else:result=c
  cache[c]=result;return result
 for row in p.ROWS:
  ims=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row]);fixed=[]
  cleanpath=FIX/'colour-input'/f'{mid}-{row}.png';cleanpath.parent.mkdir(exist_ok=True)
  p.n.save_sheet(ims,cleanpath,96)
  for im in ims:
   a=np.array(im);flat=a.reshape(-1,4)
   for pix in flat:
    if pix[3]:pix[:3]=remap(tuple(pix[:3]))
   fixed.append(Image.fromarray(a))
  mp=p.REPORT/mid/row/'metrics.json';m=json.loads(mp.read_text('utf-8'))
  m['palette_review']=dict(method='same RGB->RGB reference-derived interpolated LUT in all six rows',reference=str(p.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png'),alpha_unchanged=True,colour_input=cleanpath.relative_to(p.ROOT).as_posix(),input_spill=[p.n.spill_pixel_count(im) for im in ims],ramps=ramps,source_value_knots=cuts)
  save_row(mid,row,fixed,m)
  path=p.BAKE/f'{mid}-{row}-v1.json';meta=json.loads(path.read_text('utf-8'));meta['note']+=' 현재 시트에서 추출한 공통 팔레트 매핑 적용(녹색 잎·녹색 눈'+('·갈색 몸통).' if 'hound' in mid else '·흰 꽃 보존).');path.write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n','utf-8')
 (FIX/f'{mid}-palette.json').write_text(json.dumps(dict(ramps=ramps,source_value_knots=cuts,lut=[dict(source=[int(c) for c in k],target=[int(c) for c in v]) for k,v in cache.items()]),ensure_ascii=False,indent=2),'utf-8')

def main():
 for mid,settings in CONFIG.items():
  for ri,(row,setting) in enumerate(zip(p.ROWS,settings)):
   if FACTORS[mid][ri]!=setting[0]:rebuild(mid,row,FACTORS[mid][ri],setting)
   else:
    # Restore untouched baseline for an idempotent pass, including palette rows.
    shutil.copy2(BEFORE/f'{mid}-{row}-v1.png',p.BAKE/f'{mid}-{row}-v1.png')
    shutil.copy2(BEFORE/f'{mid}-{row}-v1.json',p.BAKE/f'{mid}-{row}-v1.json')
 # Preserve flight choreography, align the rebuilt hull to the reference eye.
 import subprocess
 for row in ['walk','windup','attack','hurt']:
  subprocess.run([sys.executable,str(p.REPORT/'drone_align.py'),row],check=True)
 p.contacts('svartalfheim_cog_drone','defeat','2,3')
 p.contacts('vanaheim_vine_hound','attack','0,1,4,5')
 # Prescribed flight arc as the original candidate, whole-frame translation.
 ims=p.frames(p.BAKE/'vanaheim_vine_hound-attack-v1.png',6)
 deltas=[[0,0] for _ in ims]
 for i,bottom in [(2,53),(3,60)]:deltas[i][1]=bottom-(ims[i].getbbox()[3]-1)
 translate('vanaheim_vine_hound','attack',deltas,'keep original leap arc after row-factor correction')
 # The seed root foot remains two pixels above the opened leaf tip.
 translate('vanaheim_seed_sprite','attack',[[0,0],[0,2],[0,2],[0,0],[0,0],[0,0]],'root-foot contact restored; opened leaf tips separately disclosed')
 for mid in ['vanaheim_vine_hound','vanaheim_seed_sprite']:palette(mid)
 for mid in CONFIG:p.board(mid)

if __name__=='__main__':main()
