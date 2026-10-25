"""ART-74 reference-ramp remapping, softened material boundaries; no spatial paint."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import sys,json,ast,colorsys,shutil
from pathlib import Path
import numpy as np
from PIL import Image
import repair as r
# Reuse the actual ART-74 reference sampler from the copied script without its writes/imports.
tree=ast.parse((r.REPORT/'fix74.py').read_text('utf-8'))
node=next(x for x in tree.body if isinstance(x,ast.FunctionDef) and x.name=='reference_ramp')
ns=dict(p=r.p,Image=Image,np=np,colorsys=colorsys)
exec(compile(ast.Module(body=[node],type_ignores=[]),'copied fix74 reference_ramp','exec'),ns)
def smooth(a,b,x):
 t=float(np.clip((x-a)/(b-a),0,1));return t*t*(3-2*t)
def mapper(mid):
 old=json.loads((r.ROOT/f'reports/codex-art-74/fix-1/{mid}-palette.json').read_text('utf-8'))
 ramps={k:np.array(ns['reference_ramp'](mid,k),float) for k in ['leaf','bark','glow']};cuts=old['source_value_knots'];cache={}
 def ramp(kind,v):
  v1=np.array([np.interp(v,cuts[kind],ramps[kind][:,k]) for k in range(3)])
  if 'hound' in mid:
   mv=max(v1)/255;amount=.35 if kind=='leaf' else .65
   tv=amount*v+(1-amount)*mv;v1*=tv/max(mv,1e-6)
  return v1
 def remap(c):
  if c in cache:return cache[c]
  h,s,v=colorsys.rgb_to_hsv(*(np.array(c)/255));orig=np.array(c,float)
  white=smooth(.68,.88,v)*(1-smooth(.28,.60,s))
  if 'hound' in mid:
   wl=smooth(.075,.15,h)*(1-smooth(.29,.37,h));wb=smooth(.005,.04,h)*(1-smooth(.075,.15,h))
  else:
   wl=smooth(.005,.06,h)*(1-smooth(.29,.37,h));wb=0
  sat=smooth(.10,.28,s);wl*=sat*(1-white);wb*=sat*(1-white)
  base=orig*(1-wl-wb)+ramp('leaf',v)*wl+ramp('bark',v)*wb
  glow=smooth(.33,.42,h)*(1-smooth(.60,.69,h))*smooth(.35,.55,v)*sat*(1-white)
  base=base*(1-glow)+ramp('glow',v)*glow
  target=tuple(np.clip(np.rint(base),0,255).astype(int));cache[c]=target;return target
 return remap,cache,ramps
def apply(im,fn):
 a=np.array(im);b=a.copy()
 for pix in b.reshape(-1,4):
  if pix[3]:pix[:3]=fn(tuple(int(c) for c in pix[:3]))
 assert np.array_equal(a[:,:,3],b[:,:,3]);return Image.fromarray(b)
def outliers(im,source):
 a=np.array(im);s=np.array(source);rgb=s[:,:,:3]/255;hsv=np.array([colorsys.rgb_to_hsv(*c) for c in rgb.reshape(-1,3)]).reshape(96,96,3)
 mask=(hsv[:,:,0]>.105)&(hsv[:,:,0]<.35)&(hsv[:,:,1]>.2)&(s[:,:,3]>0)
 lum=a[:,:,:3].mean(axis=2);vis=a[:,:,3]>0;vals=[];neigh=[]
 for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
  vals.append(np.roll(np.roll(lum,dy,0),dx,1));neigh.append(np.roll(np.roll(vis,dy,0),dx,1))
 delta=np.abs(lum-np.median(vals,axis=0));mask&=(np.sum(neigh,axis=0)>=6)
 return dict(count=int(np.sum(mask&(delta>35))),evaluated=int(mask.sum()),mean_local_deviation=float(np.mean(delta[mask])) if mask.any() else 0)
def run(mid,row,inputpath,label,base_metrics=None):
 fn,cache,ramps=mapper(mid);before=r.frames(r.BAKE/f'{mid}-{row}-v1.png',r.p.COUNTS[row]);src=r.frames(inputpath,r.p.COUNTS[row]);after=[apply(f,fn) for f in src]
 dst=r.REPORT/'trials'/f'{mid}-{row}-{label}';assert not dst.exists();dst.mkdir(parents=True)
 r.save(dst/'strip.png',r.strip(after));r.save(dst/'review-1x.png',r.panel(after,f'{mid} {row} {label} /1x',1));r.save(dst/'review-4x.png',r.panel(after,f'{mid} {row} {label} /4x'));r.save(dst/'before-4x.png',r.panel(before,f'{mid} {row} v1 /4x'))
 meta=json.loads((r.BAKE/f'{mid}-{row}-v1.json').read_text('utf-8'))
 data=json.loads(Path(base_metrics).read_text('utf-8')) if base_metrics else dict(monster=mid,row=row,factor=meta['factor'])
 data.update(before=r.audit(before),after=r.audit(after),colour=dict(method='ART-74 RGB-only reference ramp; smooth hue material boundaries and reduced leaf highlight expansion',alpha_unchanged=True,input=str(Path(inputpath).relative_to(r.ROOT)),source_spill=[r.n.spill_pixel_count(f) for f in src],before_leaf_outliers=[outliers(f,s) for f,s in zip(before,src)],after_leaf_outliers=[outliers(f,s) for f,s in zip(after,src)],ramps={k:v.tolist() for k,v in ramps.items()}))
 r.jsave(dst/'metrics.json',data);r.jsave(dst/'lut.json',[dict(source=list(k),target=[int(c) for c in v]) for k,v in cache.items()]);print(mid,row,'outliers',sum(x['count'] for x in data['colour']['before_leaf_outliers']),'->',sum(x['count'] for x in data['colour']['after_leaf_outliers']),'detail',min(x['detail'] for x in data['after']))
if __name__=='__main__':run(*sys.argv[1:])
