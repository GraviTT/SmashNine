"""ART-93 raw resampling, pixel-exact baseline reproduction, finite-event fit.

Writes new review candidates under ignored art/raw/monsters-93 only.
Input paths, alpha rules, and layout are pinned in the result manifest.
"""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, math, importlib.util
from pathlib import Path
import numpy as np
from PIL import Image
from inspect_inputs import ROOT, OUT, CONFIG, fresh, dump, sha, frames, board

RAWOUT=ROOT/'art/raw/monsters-93/final-review'
spec=importlib.util.spec_from_file_location('art93_normalizer',ROOT/'tools/sprite_pipeline/normalize.py')
n=importlib.util.module_from_spec(spec);spec.loader.exec_module(n)

def stats(im):
 b=im.getchannel('A').getbbox()
 return dict(bbox=list(b),height=b[3]-b[1],width=b[2]-b[0],bottom=b[3]-1,
  margin=min(b[0],b[1],96-b[2],96-b[3]),opaque=int(np.count_nonzero(np.array(im)[:,:,3])))

def subject(src,factor):
 z=src.resize((round(src.width*factor),round(src.height*factor)),Image.Resampling.LANCZOS)
 z=n.apply_unsharp(z,60)
 z.putalpha(z.getchannel('A').point(lambda a:255 if a>=128 else 0))
 z=n.despill_green_edge(z,'auto')
 return z.crop(z.getbbox())

def build(sources,old,factor,k,oracle=False):
 output=[];data=[]
 for i,(src,prev) in enumerate(zip(sources,old)):
  sub=subject(src,factor*k);b=prev.getbbox()
  cx=48+((b[0]+b[2]-1)/2-48)*k
  bottom=round(72+(b[3]-1-72)*k)
  x=round(cx-(sub.width-1)/2);y=bottom-sub.height+1
  # Large working surface avoids silently clipping an invalid candidate.
  big=Image.new('RGBA',(288,288));big.alpha_composite(sub,(x+96,y+96))
  big=n.despill_green_edge(big,'auto')
  rec=dict(frame=i+1,placement=[x,y],pre_fix_bbox=[x,y,x+sub.width,y+sub.height],resize_size=[round(src.width*factor*k),round(src.height*factor*k)])
  if oracle:
   # The head/body ends above y58 on the reviewed windup. Preserve every
   # pixel above this seam. Only the dangling lower tentacles are shortened.
   split=58
   sb=big.getbbox();last=sb[3]-97
   if last>72:
    tail=big.crop((0,96+split,288,96+last+1))
    tail=tail.resize((288,73-split),Image.Resampling.LANCZOS)
    tail.putalpha(tail.getchannel('A').point(lambda a:255 if a>=128 else 0))
    # No extra sharpener or colour operation on this permitted local squash.
    a=np.array(big);a[96+split:,:,:]=0;big=Image.fromarray(a)
    big.alpha_composite(tail,(0,96+split))
    rec['tentacle_squash']=dict(start_y=split,old_bottom=last,new_bottom=72,vertical_factor=(73-split)/(last+1-split))
  bb=big.getbbox();bb=(bb[0]-96,bb[1]-96,bb[2]-96,bb[3]-96)
  rec['final_bbox']=list(bb)
  rec['violations']=[q for q,fail in [('width',bb[0]<4 or bb[2]>92),('height',bb[1]<4 or bb[3]>92)] if fail]
  output.append(big.crop((96,96,192,192)));data.append(rec)
 return output,data

def events(sources,old,factor,k):
 """All dimension and integer-placement transitions, plus endpoints.

 For each interval raw resize dimensions are fixed. Alpha/despill is therefore
 fixed too. Placement changes only at the additional half-integer events.
 Descending evaluation consequently finds the largest fitting interval.
 """
 values={1.,k}
 def crossings(a,step):
  if not a:return
  lo,hi=sorted((a,a*k))
  for j in range(math.floor(lo/step)-2,math.ceil(hi/step)+3):
   t=j*step/a
   if 1<t<k:values.add(t)
 for src,prev in zip(sources,old):
  # Resize rounding only changes at n+0.5 (extra integer events are harmless).
  crossings(src.width*factor,.5);crossings(src.height*factor,.5)
  b=prev.getbbox();crossings((b[0]+b[2]-1)/2-48,.5)
  crossings(b[3]-1-72,.5)
 candidates=set(values)
 for v in values:
  if v>1:candidates.add(max(1.,v-1e-9))
 return sorted(candidates,reverse=True)

def strip(fs):
 im=Image.new('RGBA',(576,96))
 for i,f in enumerate(fs):im.alpha_composite(f,(i*96,0))
 return im

def main():
 result=[]
 for mid,iv,wv,dv in CONFIG:
  sheet=ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png'
  kept=[f for f in frames(sheet,6) if f.getbbox()]
  idle=frames(ROOT/f'art/bakeoff/monsters/{mid}-idle-v{iv}.png',6)
  kh=float(np.mean([stats(f)['height'] for f in kept]));ch=float(np.mean([stats(f)['height'] for f in idle]));k=kh/ch
  groups=[]
  for row,v in [('windup',wv),('defeat',dv)]:
   oldpath=ROOT/f'art/bakeoff/monsters/{mid}-{row}-v{v}.png'
   old=frames(oldpath);meta=json.loads(oldpath.with_suffix('.json').read_text('utf-8'));factor=meta['factor']
   group=71 if mid in ['alfheim_moon_moth','asgard_aegis_ram','asgard_runic_raven','ember_imp'] else 76
   raw=ROOT/f'art/raw/monsters-{group}/{mid}-{row}.png'
   if mid=='alfheim_moon_moth' and row=='windup':raw=ROOT/'art/raw/monsters-83/alfheim_moon_moth-windup-g1.png'
   sources=[];source_boxes=[]
   for i,s in enumerate(n.split_sheet(raw,(2,2))[0]):
    s=n.clean_background(s,'#00ff00')[0];n.validate_source_cell_margin([s],[f'{raw} F{i+1}'])
    b=s.getbbox();pad=4 if mid=='yggdrasil_root_guardian' and row=='defeat' and i==0 else 0
    sources.append(s.crop((b[0]-pad,b[1]-pad,b[2]+pad,b[3]+pad)))
    source_boxes.append(dict(bbox=list(b),transparent_padding=pad))
   baseline,_=build(sources,old,factor,1.)
   matches=[np.array_equal(a,b) for a,b in zip(baseline,old)]
   visible_matches=[np.array_equal(np.array(a)[:,:,3],np.array(b)[:,:,3]) and np.array_equal(np.array(a)[np.array(a)[:,:,3]>0],np.array(b)[np.array(b)[:,:,3]>0]) for a,b in zip(baseline,old)]
   assert all(visible_matches),(mid,row,'raw visible/alpha baseline mismatch',visible_matches)
   oracle=mid=='yggdrasil_root_oracle' and row=='windup'
   tried=[]
   for used in events(sources,old,factor,k):
    new,placement=build(sources,old,factor,used,oracle)
    violations=sorted(set(x for p in placement for x in p['violations']))
    tried.append(dict(k=used,violations=violations))
    if not violations:break
   else:raise ValueError((mid,row,'no fitting non-shrinking factor'))
   assert used>=1 and used<=k
   # Whole-row scale never shrinks. The oracle's explicitly allowed lower-tail
   # compression is the only exception to monotonic drawn height.
   assert all(stats(a)['width']>=stats(b)['width'] for a,b in zip(new,old))
   if not oracle:assert all(stats(a)['height']>=stats(b)['height'] for a,b in zip(new,old))
   after=[stats(f) for f in new];before=[stats(f) for f in old]
   dest=RAWOUT/f'{mid}-{row}-review.png';strip(new).save(fresh(dest))
   newver=max(int(p.stem.rsplit('-v',1)[1]) for p in oldpath.parent.glob(f'{mid}-{row}-v*.png'))+1
   rec=dict(monster=mid,row=row,old=oldpath.relative_to(ROOT).as_posix(),new=f'art/bakeoff/monsters/{mid}-{row}-v{newver}.png',
    review=dest.relative_to(ROOT).as_posix(),raw=raw.relative_to(ROOT).as_posix(),raw_sha256=sha(raw),source_boxes=source_boxes,
    kept_idle_heights=[stats(f)['height'] for f in kept],candidate_idle_heights=[stats(f)['height'] for f in idle],
    kept_idle_mean=kh,candidate_idle_mean=ch,k=k,used=used,old_factor=factor,new_factor=factor*used,
    limited_by=tried[0]['violations'] if used<k else [],last_rejected=tried[-2] if len(tried)>1 else None,
    tested_event_count=len(tried),baseline_rgba_exact=matches,baseline_alpha_and_visible_exact=visible_matches,before=before,after=after,placement=placement,
    height_ratio_before=float(np.mean([x['height'] for x in before]))/kh,height_ratio_after=float(np.mean([x['height'] for x in after]))/kh,
    metadata=meta)
   dump(RAWOUT/f'{mid}-{row}-search.json',tried)
   result.append(rec)
   groups.extend([(f'KEPT IDLE F1 | OLD {row.upper()} F1-F4',kept[:1]+old),
                  (f'KEPT IDLE F1 | NEW {row.upper()} F1-F4 | k={used:.8f}',kept[:1]+new)])
   print(mid,row,'target',round(k,6),'used',round(used,9),'limit',rec['limited_by'],'height ratio',round(rec['height_ratio_after'],4),flush=True)
  board(RAWOUT/f'{mid}-review-4x.png',groups,f'{mid} | EXACT NEAREST 4x | ground y72 / safe margin 4px')
 dump(RAWOUT/'rows.json',result)

if __name__=='__main__':main()
