"""ART-81 read-only image audit. Writes ONLY beside this script; numpy/Pillow only.
Run from any directory with the supplied Python, -B and PYTHONDONTWRITEBYTECODE=1.
No Godot, network, package installation, source mutation, or git mutation.
"""
from __future__ import annotations
import os
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
import sys
sys.dont_write_bytecode = True
import argparse, collections, hashlib, json, math, re, time
from pathlib import Path
from datetime import datetime, timezone
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
BAKE = ROOT / 'art/bakeoff'
GAME = ROOT / 'smash-nine-prototype/assets/art'
ROWS = ['idle','walk','windup','attack','hurt','defeat']
FOLDERS = ['frey','luna','yuki','nova','rio']
FLYERS = {'asgard_runic_raven','alfheim_moon_moth','svartalfheim_cog_drone',
          'niflheim_frost_owl','jotunheim_storm_wisp','yggdrasil_root_oracle'}
LEAPS = {'alfheim_moon_stag': {0,4,5}, 'vanaheim_vine_hound': {0,1,4,5},
         'niflheim_glacier_wolf': {0,4,5}}
THRESHOLDS = {
 'coordinates':'zero-based pixels; bbox right/bottom exclusive; feet inclusive; floor exclusive',
 'fighter_cell_exceptions':'ART-69 defeat:192/feet152; ART-68 rio_female low_sweep and dimension_slash:192/feet152, as well as victory. Others128/feet120. Six padded columns required by ART-81; legacy 1-cell Nova hurt is explicitly flagged.',
 'foreground':'alpha > 0; solid alpha >= 128',
 'margin_px':{'fighter':4,'monster':3,'projectile':3},
 'ground_tolerance_px':1,
 'binary_alpha':'fighter/monster/sheet: semi-transparent count must equal zero; faces/projectiles allow antialias',
 'key_green':'alpha>=24, R<=40, G>=215, B<=40; any => review, not automatic proof of spill',
 'halo':'4-connected outer edge; light min(RGB)>=220 and max-min<=30; dark max(RGB)<=20. Review if >=20 pixels, >20% edge AND fraction exceeds identity idle/neutral by >.15. Black outlines already in anchor are not halos. Shadow darkening intentional.',
 'checker':'8x8 fully opaque neutral tile; RGB range<=8; parity blocks 1/2/4 px contrast>=20; residual std<=5; >=4 tiles => review',
 'repeated':'premultiplied RGBA; exact changed-visible pixels=0 => fail; near if union-mask MAE<=2/255 AND changed>8-channel fraction<=0.03 => review; loop seam listed separately',
 'fighter_head':'original head_scale.py: scale 0.60..1.60 step .02, score>=.60; desired .96..1.04, accepted .95..1.06; template-only deviations => review',
 'head_skin_locator':'original unmodified mask: A>0, R>200, G>150, B>120, R>G>B, 40<R-B<110; largest 4-connected skin region. Template offsets (-18,-22,+12,+8); translation window +/-8 pixels. Wrong/occluded skin components are not reliable anatomy.',
 'fresh_face_proposals':'ART-72/75/77 fixed feature boxes; nearest-neighbour 4x; patch search +/-6 enlarged pixels (.25 native pixel step). No automated pass threshold: proposals require landmark validation. Nova/Rio eye distances omitted because the anchor far eye is occluded.',
 'monster_stable_part':'idle F1 crop, masked RGB NCC; scale .60..1.60 step .02, score>=.75, accepted .95..1.05; uncertain matches => review, no anatomy claim',
 'stable_colour_masks':'A>0: moth R>190,G>170,B>210; ram/raven R>110,G>65,R>1.6B,G>1.4B; slinger R>70,R>1.35G,R>1.8B,y<48. Largest 4-connected component; ram restrict bbox y0<55,x1>50; raven choose component centre nearest (49,50), defeat (60,48). Moth/slinger sqrt(area), ram height, raven width; ratio .95..1.05.',
 'stable_colour_validity':'Selected component area must be >=8 pixels; slinger component touching imposed y=48 cut is truncated and unusable. Raw sizes/ratios retained, but invalid selections are not scored as anatomical size defects.',
 'semantic_feet_roi':'Only SHA-256-bound manually identified ROIs in semantic-rois.json may replace lowest-alpha proxy. Measure A>0 bottom, tolerance +/-1px and stated boundary uncertainty +/-1px.',
 'bbox_size':'width/height/area relative to idle F1; ratios outside .75..1.25 are a screening observation, not failure (pose changes)',
 'palette':'alpha>=128, RGB max>=40, HSV saturation>=.20; twelve 30-degree hue bins; TV > .25 AND dominant circular hue shift>=30deg => review; full luminance/channel stats also reported',
 'face_preservation':'expressions: exact RGBA outside actual saved mask must have 0 changed pixels; all faces alpha difference=0',
 'shadow_offset':'integer gradient NCC on ART-80 ROI, search +/-4; residual abs(dx)>1 or abs(dy)>1 or NCC<.60 => review; copied alpha cannot establish internal alignment',
 'metadata':'frames/fps required for strips; frames positive integer and matches occupied prefix, fps finite >0, loop bool when present; missing cell/feet/loop => review (viewer may infer); sheet/portrait animation metadata NA',
 'all_checks_pass':'all applicable check statuses pass or na; review/unmeasured excluded. Sheet content checks are propagated from per-row checks; direct pixel-assembly pass is separate.',
}
INPUTS = {}
def rel(p): return Path(p).resolve().relative_to(ROOT).as_posix()
def digest(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def record(p):
 p=Path(p); INPUTS[rel(p)]=digest(p); return p
def readj(p): return json.loads(record(p).read_text(encoding='utf-8-sig'))
def imread(p): return Image.open(record(p)).convert('RGBA')
def savej(p,d): p.write_text(json.dumps(d,ensure_ascii=False,indent=2,allow_nan=False)+'\n',encoding='utf-8')
def bbox(mask):
 y,x=np.nonzero(mask)
 return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)] if len(x) else None
def rounded(x): return round(float(x),6)
def check(status, measurement=None, threshold=None, reason=None):
 d={'status':status,'measurement':measurement}
 if threshold is not None:d['threshold']=threshold
 if reason:d['reason']=reason
 return d
def worst_status(ss):
 return next((s for s in ['fail','unmeasured','review','pass'] if s in ss),'na')
def erode(m):
 p=np.pad(m,1);return m & p[:-2,1:-1]&p[2:,1:-1]&p[1:-1,:-2]&p[1:-1,2:]
def components(m):
 seen=np.zeros(m.shape,bool);results=[]; h,w=m.shape
 for y,x in zip(*np.nonzero(m)):
  if seen[y,x]:continue
  stack=[(int(y),int(x))];seen[y,x]=True;pts=[]
  while stack:
   cy,cx=stack.pop();pts.append((cy,cx))
   for ny,nx in [(cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)]:
    if 0<=ny<h and 0<=nx<w and m[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;stack.append((ny,nx))
  a=np.array(pts);results.append({'area':len(pts),'bbox':[int(a[:,1].min()),int(a[:,0].min()),int(a[:,1].max()+1),int(a[:,0].max()+1)]})
 return sorted(results,key=lambda r:-r['area'])
def frame_stats(a):
 m=a[...,3]>0;b=bbox(m);h,w=m.shape
 edge=m&~erode(m);rgb=a[...,:3].astype(int)
 green=(a[...,3]>=24)&(rgb[...,0]<=40)&(rgb[...,1]>=215)&(rgb[...,2]<=40)
 light=edge&(rgb.min(2)>=220)&(np.ptp(rgb,axis=2)<=30)
 dark=edge&(rgb.max(2)<=20)
 neutral=(np.ptp(rgb,axis=2)<=8)&(a[...,3]==255)
 tiles=[]
 for y in range(0,h-7,8):
  for x in range(0,w-7,8):
   if not neutral[y:y+8,x:x+8].all():continue
   lum=rgb[y:y+8,x:x+8].mean(2);yy,xx=np.indices((8,8))
   for s in [1,2,4]:
    p=(xx//s+yy//s)%2==0;u,v=lum[p],lum[~p]
    if abs(u.mean()-v.mean())>=20 and max(u.std(),v.std())<=5:tiles.append([x,y,s]);break
 comps=components(m)
 return {'bbox':b,'margins_ltrb':[b[0],b[1],w-b[2],h-b[3]] if b else None,
  'alpha_pixels':int(m.sum()),'solid_bbox':bbox(a[...,3]>=128),'bottom_y':b[3]-1 if b else None,
  'semi_transparent_pixels':int(((a[...,3]>0)&(a[...,3]<255)).sum()),
  'transparent_rgb_pixels':int(((a[...,3]==0)&(rgb.max(2)>0)).sum()),
  'edge_pixels':int(edge.sum()),'light_edge_pixels':int(light.sum()),'dark_edge_pixels':int(dark.sum()),
  'key_green_pixels':int(green.sum()),'checker_tiles':tiles,'components_4connected':comps}
def premul(a):
 a=a.astype(float);a[...,:3]*=a[...,3,None]/255;return a
def pair_metrics(a,b):
 u=(a[...,3]>0)|(b[...,3]>0);d=np.abs(premul(a)-premul(b));mx=d.max(2)
 return {'union_pixels':int(u.sum()),'mae_union_0_255':rounded(d[u].mean()) if u.any() else 0,
  'mae_canvas_0_255':rounded(d.mean()),'changed_visible_pixels':int((mx[u]>0).sum()),
  'fraction_changed_gt8':rounded((mx[u]>8).mean()) if u.any() else 0,
  'silhouette_iou':rounded(((a[...,3]>0)&(b[...,3]>0)).sum()/max(1,u.sum()))}
def palette(a):
 rgb=a[...,:3][a[...,3]>=128]; f=rgb.astype(float)/255
 if not len(rgb):return {'pixels':0,'hue_fraction':[0.]*12,'dominant_hue_bin':None}
 v=f.max(1);mn=f.min(1);delta=v-mn;s=delta/np.maximum(v,1e-12);h=np.zeros(len(v));nz=delta>0
 r,g,b=f.T; k=nz&(v==r);h[k]=((g[k]-b[k])/delta[k])%6
 k=nz&(v==g)&(v!=r);h[k]=(b[k]-r[k])/delta[k]+2
 k=nz&(v==b)&(v!=g)&(v!=r);h[k]=(r[k]-g[k])/delta[k]+4
 h*=60;use=(s>=.2)&(v>=40/255);hist=np.bincount((h[use]//30).astype(int),minlength=12);hist=hist/max(1,hist.sum())
 quant=rgb//32;codes=quant[:,0].astype(int)*64+quant[:,1]*8+quant[:,2];ids,counts=np.unique(codes,return_counts=True);ix=np.argsort(-counts)[:8]
 return {'pixels':len(rgb),'chromatic_pixels':int(use.sum()),'hue_fraction':[rounded(x) for x in hist],
  'yellow_hue_30_60_fraction':rounded(hist[1]),'green_hue_60_180_fraction':rounded(hist[2:6].sum()),
  'dominant_hue_bin':int(np.argmax(hist)),'rgb_mean':[rounded(x) for x in rgb.mean(0)],
  'luma_mean':rounded((f@np.array([.2126,.7152,.0722])*255).mean()),
  'top_rgb32_bins':[{'rgb_bin_center':[int(ids[i]//64*32+16),int(ids[i]//8%8*32+16),int(ids[i]%8*32+16)],'fraction':rounded(counts[i]/len(rgb))} for i in ix]}
def palette_check(a, reference, intentional=False):
 pa=palette(a)
 if reference is None:return check('na',{'candidate':pa},reason='No character identity for shared shockwave')
 ref=np.asarray(imread(reference));pr=palette(ref);tv=sum(abs(x-y) for x,y in zip(pa['hue_fraction'],pr['hue_fraction']))/2
 d=abs(pa['dominant_hue_bin']-pr['dominant_hue_bin']);shift=min(d,12-d)*30
 flag=tv>.25 and shift>=30
 return check('pass' if intentional or not flag else 'review',{'reference':rel(reference),'candidate':pa,'reference_palette':pr,'hue_tv':rounded(tv),'dominant_hue_shift_degrees':shift,'intentional_shadow_palette':intentional},'palette')

def discover():
 found=[];excluded=[]
 for folder in FOLDERS+['monsters']:
  for p in sorted((BAKE/folder).glob('*.png')):
   jp=p.with_suffix('.json');meta=readj(jp) if jp.exists() else {}
   if 'adopted' in meta:excluded.append(rel(p));continue
   stem=p.stem
   if folder=='monsters':
    if '_sheet-v' in stem:kind='monster_sheet';who=stem.split('_sheet-v')[0];row='sheet'
    elif '-projectile-v' in stem or stem.startswith('slam_shockwave-'):kind='projectile';who=stem.split('-')[0];row='projectile'
    else:
     m=re.fullmatch(r'(.+)-(idle|walk|windup|attack|hurt|defeat)-v\d+',stem)
     if not m:continue
     who,row=m.groups();kind='monster'
   elif '_face-' in stem:kind='face';who,row=stem.split('_face-');row=re.sub(r'-v\d+$','',row)
   else:
    m=re.fullmatch(r'(.+)-(.+)-v\d+',stem)
    if not m:continue
    who,row=m.groups();kind='fighter'
   found.append({'path':rel(p),'kind':kind,'identity':who,'row':row,'metadata_path':rel(jp) if jp.exists() else None,'metadata':meta})
 return found,excluded

def basic(item):
 p=ROOT/item['path'];im=imread(p);a=np.asarray(im);w,h=im.size;kind=item['kind'];meta=item['metadata'];who=item['identity'];row=item['row']
 item['sha256']=digest(p);item['dimensions']=[w,h];item['mode']=Image.open(p).mode;item['checks']={};c=item['checks']
 if kind=='face': cw=ch=256;cols=1;n=1
 elif kind=='monster_sheet':cw=ch=96;cols=6;n=36
 elif kind=='monster':cw=ch=96;cols=6;n=meta.get('frames',6)
 elif kind=='projectile':cw,ch=(64,48) if who=='slam_shockwave' else (48,48);cols=4;n=meta.get('frames',4)
 else:cw=ch=192 if row in ['victory','defeat'] or (who=='rio_female' and row in ['low_sweep','dimension_slash']) else 128;cols=6;n=meta.get('frames',6)
 item['cell']=[cw,ch];item['used_frames']=n
 geometry_ok=(w==cw*cols and h==ch*(6 if kind=='monster_sheet' else 1) and item['mode']=='RGBA')
 cells=[a[y:y+ch,x:x+cw] for y in range(0,h,ch) for x in range(0,w,cw)]
 stats=[frame_stats(f) for f in cells];item['frames']=[{'frame':i+1,**s} for i,s in enumerate(stats)]
 occupied=[i+1 for i,s in enumerate(stats) if s['alpha_pixels']]
 item['stored_cells']=len(cells);item['occupied_cell_count']=len(occupied)
 if kind=='monster_sheet':item['used_frames']=len(occupied)
 missing=[];errors=[]
 if kind not in ['face','monster_sheet']:
  for key in ['frames','fps','cell','loop']+(['feet'] if kind in ['fighter','monster'] else []):
   if key not in meta:missing.append(key)
  if not isinstance(n,int) or not 1<=n<=cols or occupied!=list(range(1,n+1)):errors.append('frame_count_or_padding')
  if not isinstance(meta.get('fps'),(int,float)) or not math.isfinite(meta.get('fps',0)) or meta.get('fps',0)<=0:errors.append('fps')
  if 'loop' in meta and not isinstance(meta['loop'],bool):errors.append('loop_type')
  if 'cell' in meta and (meta['cell'] if isinstance(meta['cell'],list) else [meta['cell']]*2)!=[cw,ch]:errors.append('cell_metadata')
  expected_feet=152 if kind=='fighter' and ch==192 else 120 if kind=='fighter' else 72
  if 'feet' in meta and meta['feet']!=expected_feet:errors.append('feet_metadata')
 c['format']=check('fail' if not geometry_ok or errors else 'review' if missing else 'pass',{'actual_dimensions':[w,h],'expected_dimensions':[cw*cols,ch*(6 if kind=='monster_sheet' else 1)],'geometry_and_mode_ok':geometry_ok,'occupied_cells':occupied,'missing_fields':missing,'errors':errors},'metadata')
 if kind=='face':c['slicing']=check('na',reason='portrait intentionally touches canvas');c['feet']=check('na');c['repeated']=check('na')
 else:
  margin=4 if kind=='fighter' else 3;bad=[i+1 for i,s in enumerate(stats) if s['margins_ltrb'] and min(s['margins_ltrb'])<margin]
  cross=[]
  for x in range(cw,w,cw):
   left=a[:,x-1,3]>0;right=a[:,x,3]>0
   # Eight-connected adjacency catches diagonal bridging too.
   near=right|np.r_[False,right[:-1]]|np.r_[right[1:],False];ys=np.flatnonzero(left&near)
   if len(ys):cross.append({'x':x,'adjacent_rows':ys.tolist()})
  c['slicing']=check('fail' if bad or cross else 'pass',{'margin_px':margin,'violating_cells':bad,'cross_border_8connected_links':cross},'margin_px')
  pairs=[]
  if kind!='monster_sheet':
   for i in range(min(n,len(cells))-1):
    v=pair_metrics(cells[i],cells[i+1]);v.update(frames=[i+1,i+2],exact=v['changed_visible_pixels']==0,near=v['mae_union_0_255']<=2 and v['fraction_changed_gt8']<=.03);pairs.append(v)
   seam=pair_metrics(cells[min(n,len(cells))-1],cells[0]) if n>1 and meta.get('loop') else None
   c['repeated']=check('fail' if any(x['exact'] for x in pairs) else 'review' if any(x['near'] for x in pairs) else 'pass',{'adjacent_pairs':pairs,'loop_seam':seam},'repeated')
  else:c['repeated']=check('na',reason='propagated later from source rows')
  foot=[]
  for i,s in enumerate(stats[:n]):
   target=152 if kind=='fighter' and ch==192 else 120 if kind=='fighter' else 72
   exempt=kind=='monster_sheet' or (kind=='fighter' and (row in ['jump','fall','tumble'] or row.startswith('air_'))) or (kind=='monster' and (who in FLYERS or row=='attack' and who in LEAPS and i not in LEAPS[who])) or kind=='projectile'
   if who=='slam_shockwave':exempt=False;target=meta.get('floor',44)-1
   foot.append({'frame':i+1,'bottom_y':s['bottom_y'],'target_pixel_y':target,'delta':s['bottom_y']-target if s['bottom_y'] is not None else None,'airborne_or_na':exempt})
  bad=[f for f in foot if not f['airborne_or_na'] and (f['delta'] is None or abs(f['delta'])>1)]
  c['feet']=check('review' if bad else 'na' if all(f['airborne_or_na'] for f in foot) else 'pass',{'frames':foot,'off_line_frames':[f['frame'] for f in bad],'method':'lowest alpha pixel proxy; weapon/cape/weight-bearing semantics require inspection'},'ground_tolerance_px')
 binary=kind in ['fighter','monster','monster_sheet'];semi=sum(s['semi_transparent_pixels'] for s in stats);edge=sum(s['edge_pixels'] for s in stats)
 light=sum(s['light_edge_pixels'] for s in stats);dark=sum(s['dark_edge_pixels'] for s in stats);green=sum(s['key_green_pixels'] for s in stats);tiles=sum(len(s['checker_tiles']) for s in stats)
 halo=(light>=20 and light/max(1,edge)>.2) or (dark>=20 and dark/max(1,edge)>.2)
 if kind=='face':halo=False # neutral-relative comparison in face_checks
 c['alpha']=check('fail' if binary and semi else 'review' if green or tiles>=4 or halo else 'pass',{'semi_transparent_pixels':semi,'binary_required':binary,'edge_pixels':edge,'light_edge_pixels':light,'dark_edge_pixels':dark,'key_green_pixels':green,'checker_tile_count':tiles,'halo_screen_flag':halo,'limitation':'Colour screens do not prove semantic absence of opaque halos or baked backgrounds.'},'binary_alpha / key_green / halo / checker')
 ref=GAME/('monsters' if kind in ['monster','monster_sheet','projectile'] else who.split('_')[0])/f'{who}_sheet.png'
 if kind=='face':ref=ROOT/meta['edited_from']
 if not ref.exists() and who in ['frey','luna','yuki']:ref=GAME/who/f'{who}_female_sheet.png'
 c['palette']=palette_check(a,ref if ref.exists() else None,row=='shadow')
 c['assembly']=check('na');c['faces']=check('na');c['size']=check('na' if kind in ['face','projectile'] else 'unmeasured')
 return cells

def fftcorr(a,b):
 shape=(a.shape[0]+b.shape[0]-1,a.shape[1]+b.shape[1]-1)
 full=np.fft.irfft2(np.fft.rfft2(a,s=shape)*np.fft.rfft2(b[::-1,::-1],s=shape),s=shape)
 return full[b.shape[0]-1:a.shape[0],b.shape[1]-1:a.shape[1]]
def match_template(frame,template,scales,centre=None):
 """Masked Pearson RGB NCC, all translations; optional original head search window."""
 f=np.asarray(frame).astype(float);f[...,:3]*=(f[...,3,None]>0)
 max_scale=max(scales);shape=tuple(2**math.ceil(math.log2(dim+max(4,round(td*max_scale))-1)) for dim,td in [(frame.height,template.height),(frame.width,template.width)])
 ffts=[np.fft.rfft2(f[...,k],s=shape) for k in range(3)];sum_fft=sum(ffts);sq_fft=np.fft.rfft2((f[...,:3]**2).sum(2),s=shape)
 best={'scale':None,'score':-2,'box':None};curves=[]
 for scale in scales:
  tw,th=max(4,round(template.width*scale)),max(4,round(template.height*scale))
  if tw>frame.width or th>frame.height:continue
  t=np.asarray(template.resize((tw,th),Image.Resampling.LANCZOS)).astype(float)[...,:3]
  mask=np.asarray(template.getchannel('A').resize((tw,th),Image.Resampling.NEAREST))>0
  count=int(mask.sum())*3
  if count<12:continue
  mean=t[mask].mean();tv=(t-mean)*mask[...,None];tn=float((tv*tv).sum())
  mask_fft=np.fft.rfft2(mask[::-1,::-1],s=shape)
  def valid(freq):return np.fft.irfft2(freq,s=shape)[th-1:frame.height,tw-1:frame.width]
  su=valid(sum_fft*mask_fft);sq=valid(sq_fft*mask_fft)
  num=valid(sum(ffts[k]*np.fft.rfft2(tv[::-1,::-1,k],s=shape) for k in range(3)));den=np.sqrt(np.maximum(0,sq-su*su/count)*tn)+1e-6;score=num/den
  if centre is not None:
   cy,cx=centre;ey=cy-22*scale;ex=cx-18*scale;ys,xs=np.indices(score.shape)
   score[(abs(xs-ex)>8.5)|(abs(ys-ey)>8.5)]=-2
  y,x=np.unravel_index(np.argmax(score),score.shape);v=float(score[y,x]);curves.append([rounded(scale),rounded(v)])
  if v>best['score']:best={'scale':rounded(scale),'score':rounded(v),'box':[int(x),int(y),int(x+tw),int(y+th)]}
 best['scale_scores']=curves
 return best

def monster_config():
 config={};prior={}
 for n in [71,74,76]:
  p=ROOT/f'reports/codex-art-{n}/fix-1/sizes.json';d=readj(p);ls=sum(d.values(),[]) if isinstance(d,dict) else d
  for r in ls:
   prior[(r['monster'],r['row'])]={'source':rel(p),'reported_measurement':r}
   if r['row']!='idle':continue
   a=r.get('after',{});box=a.get('box',r.get('after_box'));pts=a.get('points',r.get('after_points'))
   if not box:
    arr=np.array(pts);mi=arr.min(0);ma=arr.max(0);box=[math.floor(mi[0]),math.floor(mi[1])-5,math.ceil(ma[0]),math.ceil(ma[1])+5]
   config[r['monster']]={'box':box,'part':r['part'],'source':rel(p)}
 return config,prior

def historical_face(item):
 """Reuse labelled evidence ONLY if its nearby PNG pixels equal this current candidate."""
 p=ROOT/item['path'];target=np.asarray(imread(p));who=item['identity'];row=item['row'];matches=[]
 for n in [78,77,75,72]:
  dirs=[ROOT/f'reports/codex-art-{n}/best/{who}/{row}']
  if n==75 and who=='yuki' and row=='fall':dirs.insert(0,ROOT/'reports/codex-art-75/fix-1/final')
  for dr in dirs:
   fp=dr/'face-measured.json'
   if not fp.exists():continue
   for name in ['best-attempt.png',f'{who}-{row}.png']:
    ip=dr/name
    if not ip.exists():continue
    ia=np.asarray(imread(ip))
    if ia.shape==target.shape and np.array_equal(ia,target):matches.append((fp,ip));break
 if not matches:return {'status':'unmeasured','reason':'No byte/pixel-bound landmark evidence found; automatic head measure is separate.'}
 fp,ip=matches[0];d=readj(fp);out=[];excluded_ids={x if isinstance(x,int) else x['frame'] for x in d.get('excluded_frames',[])}
 for fr in d.get('frames',[]):
  if fr['frame'] in excluded_ids:continue
  lm=fr.get('landmarks');pts=fr.get('points');fw=fr.get('face_width',fr.get('width'));eye=fr.get('eye_distance');refw=d.get('reference_face_width');refe=d.get('reference_eye_distance')
  if lm:
   fw=lm[3]['x']-lm[2]['x']
   if fr.get('eye_ratio') is not None and refe:eye=math.hypot(lm[1]['x']-lm[0]['x'],lm[1]['y']-lm[0]['y'])
  elif pts:fw=pts[1]-pts[0]
  out.append({'frame':fr['frame'],'face_width_px':fw,'face_width_ratio':rounded(fw/refw) if fw is not None and refw else None,'eye_distance_px':eye,'eye_ratio':rounded(eye/refe) if eye is not None and refe and fr.get('eye_ratio') is not None else None,'landmarks':lm or pts})
 ratios=[v for f in out for v in [f['face_width_ratio'],f['eye_ratio']] if v is not None]
 bad=any(x<.95 or x>1.06 for x in ratios);full=len(out)==item['used_frames'] and all(f['eye_ratio'] is not None for f in out)
 return {'status':'review' if bad or not full else 'pass','source':rel(fp),'pixel_identical_reference':rel(ip),'method':'Recomputed distances at previous reviewer coordinates on pixel-identical PNG; not new manual landmark annotation.', 'reference_landmarks':d.get('anchor_landmarks',d.get('anchor')),'frames':out,'excluded_frames':d.get('excluded_frames',[]),'excluded_source_proposals_not_used':[fr for fr in d.get('frames',[]) if fr['frame'] in excluded_ids],'full_eyes_and_width_coverage':full,'outside_accepted_range':bad,'eye_limitation':d.get('eye_limitation'),'threshold':[.95,1.06]}

LANDMARKS = {
 'frey':[(79,51,3,4),(85,51,3,4),(68,53,4,4),(85.5,53,4,4)],
 'luna':[(82.5,67,4,5),(90,67,3,4),(77,67,3,4),(91,67,3,4)],
 'luna_brave':[(79,64.5,4,5),(86,64.5,3,4),(73,65.5,3,4),(87,65.5,3,4)],
 'yuki':[(83.5,63,3,4),(90.5,62.5,3,4),(79.5,66,3,4),(91.5,66,3,4)],
 'nova_male':[(72.5,57,3,4),(79.5,56,2,3),(65.5,60,3,4),(80,60,3,4)],
 'nova_female':[(72.5,59,3,4),(79.5,58.5,2,3),(65.5,62,3,4),(80,62,3,4)],
 'rio_male':[(76.5,49,3,4),(82,47,2,3),(68,51,3,3),(83,51,3,3)],
 'rio_female':[(83.5,51,3,4),(88.5,49,2,3),(78,53,3,3),(90,53,3,3)],
}
def fresh_landmarks(who,anchor,frames,matches,anchor_centre):
 """ART-72 4x patch proposals. No automatically accepted anatomy/eye claims."""
 points=LANDMARKS[who];an=np.asarray(anchor.resize((512,512),Image.Resampling.NEAREST))[...,:3].astype(float);out=[]
 acy,acx=anchor_centre;refw=points[3][0]-points[2][0];refe=math.dist(points[0][:2],points[1][:2]);occluded=who.startswith(('nova_','rio_'))
 for i,(frame,m) in enumerate(zip(frames,matches)):
  if m['box'] is None:out.append({'frame':i+1,'status':'unmeasured','reason':'head not localized'});continue
  fx=np.asarray(frame.resize((frame.width*4,frame.height*4),Image.Resampling.NEAREST))[...,:3].astype(float);marks=[]
  for px,py,pw,ph in points:
   x0=round((px-pw/2)*4);y0=round((py-ph/2)*4);ww=round(pw*4);hh=round(ph*4);t=an[y0:y0+hh,x0:x0+ww].copy();t-=t.mean();tn=np.sqrt((t*t).sum())+1e-9
   ex=m['box'][0]+(px-(round(acx)-18))*m['scale'];ey=m['box'][1]+(py-(round(acy)-22))*m['scale'];best=(-2,None,None)
   for yy in range(round(ey*4)-6,round(ey*4)+7):
    for xx in range(round(ex*4)-6,round(ex*4)+7):
     sy=yy-hh//2;sx=xx-ww//2
     if sy<0 or sx<0:continue
     patch=fx[sy:sy+hh,sx:sx+ww].copy()
     if patch.shape!=t.shape:continue
     patch-=patch.mean();score=float((patch*t).sum()/(tn*(np.sqrt((patch*patch).sum())+1e-9)))
     if score>best[0]:best=(score,xx/4,yy/4)
   marks.append({'x':best[1],'y':best[2],'score':rounded(best[0])})
  valid=all(v['x'] is not None for v in marks)
  width=marks[3]['x']-marks[2]['x'] if valid else None;eye=math.dist([marks[0]['x'],marks[0]['y']],[marks[1]['x'],marks[1]['y']]) if valid and not occluded else None
  out.append({'frame':i+1,'status':'proposal_only','landmarks':marks,'face_width_px':width,'face_width_ratio':rounded(width/refw) if width is not None else None,'eye_distance_px':eye,'eye_ratio':rounded(eye/refe) if eye is not None else None,'known_anchor_eye_occlusion':occluded,'min_patch_score':min(v['score'] for v in marks)})
 return {'method':'ART-72/75/77 fixed anchor feature patches on nearest 4x; +/-1.5 native-pixel search at .25px steps; head NCC only initializes position. No iris refinement; proposals not anatomical measurements until human validates.', 'reference_points':points,'reference_face_width':refw,'reference_eye_distance':None if occluded else refe,'frames':out,'status':'unmeasured','reason':'Fresh proposals supplied for every frame; automatic landmarks are not silently accepted as eyes/skin boundaries.'}

def stable_colour(who,frame,row='idle'):
 a=np.asarray(frame).astype(float);r,g,b,al=[a[...,i] for i in range(4)]
 if who=='alfheim_moon_moth':mask=(r>190)&(g>170)&(b>210)&(al>0);metric='sqrt_area'
 elif who in ['asgard_aegis_ram','asgard_runic_raven']:
  mask=(r>110)&(g>65)&(r>1.6*b)&(g>1.4*b)&(al>0);metric='height' if who=='asgard_aegis_ram' else 'width'
 elif who=='midgard_rooftop_slinger':mask=(r>70)&(r>g*1.35)&(r>b*1.8)&(al>0);mask[48:]=False;metric='sqrt_area'
 else:return None
 cs=components(mask)
 if not cs:return {'metric':metric,'size':None,'component':None}
 if who=='asgard_aegis_ram':
  cs=[c for c in cs if c['bbox'][1]<55 and c['bbox'][2]>50]
  if not cs:return {'metric':metric,'size':None,'component':None}
 if who=='asgard_runic_raven':
  centre=(60,48) if row=='defeat' else (49,50)
  cs.sort(key=lambda c:math.dist(((c['bbox'][0]+c['bbox'][2])/2,(c['bbox'][1]+c['bbox'][3])/2),centre))
 c=cs[0];box=c['bbox'];size=math.sqrt(c['area']) if metric=='sqrt_area' else box[3]-box[1] if metric=='height' else box[2]-box[0]
 valid=c['area']>=8 and not (who=='midgard_rooftop_slinger' and box[3]>=48)
 return {'metric':metric,'size':rounded(size),'component':c,'measurement_valid':valid,'invalid_reason':None if valid else 'Component too small (<8px) or slinger clipped by y<48 search mask; not a stable anatomical part.','threshold':'ART-71/74 RGB masks; 4-connected largest (ram y0<55,x1>50; raven nearest (49,50), defeat (60,48); slinger y<48). Colour is a proxy, not anatomy'}

def halo_references(items):
 cache={}
 for item in items:
  who=item['identity'];kind=item['kind'];ch=item['checks']['alpha'];d=ch['measurement'];rp=None;cell=None
  if kind=='face':rp=ROOT/item['metadata']['edited_from']
  elif kind=='fighter':
   ps=[p for p in (BAKE/who.split('_')[0]).glob(f'{who}-idle-v*.json') if 'adopted' in readj(p)]
   if ps:rp=ps[-1].with_suffix('.png');cell=128
  elif who!='slam_shockwave':rp=GAME/'monsters'/f'{who}_sheet.png'
  if rp and rp.exists():
   if rel(rp) not in cache:
    im=imread(rp)
    if kind!='face':sz=cell or im.width//6;im=im.crop((0,0,sz,sz))
    cache[rel(rp)]=frame_stats(np.asarray(im))
   base=cache[rel(rp)];be=max(1,base['edge_pixels']);ce=max(1,d['edge_pixels']);excess={name:rounded(d[name]/ce-base[name]/be) for name in ['light_edge_pixels','dark_edge_pixels']}
   flag=any(d[name]>=20 and d[name]/ce>.2 and excess[name]>.15 for name in excess)
   if item['row']=='shadow':flag=False
   d.update(reference=rel(rp),reference_edge_pixels=base['edge_pixels'],reference_light_edge_pixels=base['light_edge_pixels'],reference_dark_edge_pixels=base['dark_edge_pixels'],edge_fraction_excess=excess,halo_screen_flag=flag)
   ch['status']='fail' if d['binary_required'] and d['semi_transparent_pixels'] else 'review' if d['key_green_pixels'] or d['checker_tile_count']>=4 or flag else 'pass'

def semantic_feet(items):
 config=readj(OUT/'semantic-rois.json');by={i['path']:i for i in items}
 for r in config['records']:
  item=by.get(r['path'])
  if not item:continue
  ch=item['checks']['feet'];d=ch['measurement']
  if item['sha256']!=r['sha256']:
   d['semantic_roi_skipped']='Image hash changed; prior manual ROI is not valid.';continue
  image=np.asarray(imread(ROOT/item['path']));cw,height=item['cell'];ms=[]
  for f in r['frames']:
   frame=image[:,(f['frame']-1)*cw:f['frame']*cw];x0,y0,x1,y1=f['roi'];box=bbox(frame[y0:y1,x0:x1,3]>0);bottom=y0+box[3]-1 if box else None
   ms.append({**f,'measured_bottom_y':bottom,'delta':bottom-r['target_y'] if bottom is not None else None,'pass':bottom is not None and abs(bottom-r['target_y'])<=r['tolerance_px']})
  d['semantic_support_measurement']={'source':rel(OUT/'semantic-rois.json'),'source_sha256':r['sha256'],'frames':ms,'uncertainty_px':r['uncertainty_px'],'evidence':r['evidence'],'method':config['method']}
  unresolved=[f for f in d['off_line_frames'] if f not in [m['frame'] for m in ms if m['pass']]]
  d['unresolved_off_line_frames']=unresolved
  if not unresolved and all(m['pass'] for m in ms):ch['status']='pass'

def size_checks(items, cache):
 sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
 import head_scale as hs
 record(ROOT/'tools/sprite_pipeline/head_scale.py')
 mc,prior=monster_config(); scales=np.round(np.arange(.6,1.601,.02),2); processed=0
 for item in items:
  kind=item['kind']
  if kind not in ['fighter','monster']:continue
  who=item['identity'];row=item['row'];p=ROOT/item['path'];im=imread(p);cw,ch=item['cell'];fs=[im.crop((i*cw,0,(i+1)*cw,ch)) for i in range(item['used_frames'])]
  if kind=='fighter':
   anchors=[x for x in (BAKE/who.split('_')[0]).glob(f'{who}-idle-v*.json') if 'adopted' in readj(x)]
   if not anchors:item['checks']['size']=check('unmeasured',reason='No adopted idle anchor');continue
   ap=anchors[-1].with_suffix('.png');anchor=imread(ap).crop((0,0,128,128))
   try:template=hs.head_template(anchor)
   except ValueError:item['checks']['size']=check('unmeasured',reason='No anchor skin component');continue
   box=None;hist=historical_face(item)
  else:
   ap=BAKE/'monsters'/f'{who}-idle-v1.png';anchor=imread(ap).crop((0,0,96,96));box=mc[who]['box'];template=anchor.crop(box);hist=None
  key=hashlib.sha256((digest(p)+digest(ap)+str(box)+'fft-v2').encode()).hexdigest()
  if key in cache:measure=cache[key]
  else:
   measure=[]
   for i,f in enumerate(fs):
    centre=hs.face_centre(np.asarray(f)) if kind=='fighter' else None
    m=match_template(f,template,scales,centre) if kind!='fighter' or centre is not None else {'scale':None,'score':0,'box':None,'scale_scores':[]}
    m['frame']=i+1;m['skin_centre_yx']=list(centre) if centre else None
    # Teleport collapse is documented in ART-71, not a scale failure.
    m['intentional_scale_exception']=who=='alfheim_moon_moth' and row=='attack' and 1<=i<=4
    measure.append(m)
   cache[key]=measure;savej(OUT/'measurement-cache.json',cache)
  amin=np.asarray(anchor);ab=bbox(amin[...,3]>0);ratios=[]
  for f in fs:
   fb=bbox(np.asarray(f)[...,3]>0)
   ratios.append({'width':rounded((fb[2]-fb[0])/(ab[2]-ab[0])),'height':rounded((fb[3]-fb[1])/(ab[3]-ab[1])),'alpha_area':rounded((np.asarray(f)[...,3]>0).sum()/(amin[...,3]>0).sum())})
  score_min=.6 if kind=='fighter' else .75;low=.95;hi=1.06 if kind=='fighter' else 1.05
  usable=[m for m in measure if m['score']>=score_min and not m['intentional_scale_exception']]
  bad=[m['frame'] for m in usable if not low<=m['scale']<=hi];unmatched=[m['frame'] for m in measure if m['score']<score_min and not m['intentional_scale_exception']]
  status='review' if bad or unmatched else 'pass'
  if kind=='fighter':status=worst_status([status,hist['status']])
  data={'anchor':rel(ap),'anchor_frame':1,'template_box':box,'template_method':'masked RGB Pearson NCC; original head_scale scales/skin-centre window for fighters; stable part crop full cell translation for monsters','frames':measure,'bbox_ratios_vs_idle':ratios,'out_of_range_frames':bad,'low_confidence_frames':unmatched,'median_scale':rounded(np.median([m['scale'] for m in usable])) if usable else None,'interpretation':'screening only; rotated/occluded anatomy may change projection'}
  if kind=='fighter':
   data['face_landmarks']=hist
   ac=hs.face_centre(np.asarray(anchor));data['fresh_face_proposals']=fresh_landmarks(who,anchor,fs,measure,ac)
  else:
   data.update(stable_part=mc[who],previous_report=prior.get((who,row)))
   color_ref=stable_colour(who,anchor)
   if color_ref:
    cm=[]
    for j,f in enumerate(fs):
     v=stable_colour(who,f,row);v['frame']=j+1;v['raw_ratio']=rounded(v['size']/color_ref['size']) if v['size'] and color_ref['size'] else None;v['ratio']=v['raw_ratio'] if v.get('measurement_valid',False) and color_ref.get('measurement_valid',False) else None;v['intentional_exception']=who=='alfheim_moon_moth' and row=='attack' and 1<=j<=4;cm.append(v)
    data['colour_component_size']={'anchor':color_ref,'frames':cm,'threshold':[.95,1.05]}
    if any(not v['intentional_exception'] and (v['ratio'] is None or not .95<=v['ratio']<=1.05) for v in cm):status='review'
  item['checks']['size']=check(status,data,'fighter_head' if kind=='fighter' else 'monster_stable_part');processed+=1
  if processed%10==0:print(f'size {processed}/161',flush=True)

def face_checks(item):
 if item['kind']!='face':return
 meta=item['metadata'];who=item['identity'];row=item['row'];a=np.asarray(imread(ROOT/item['path']));neutral=imread(ROOT/meta['edited_from']);b=np.asarray(neutral);delta=np.any(a!=b,2)
 d={'neutral':meta['edited_from'],'changed_pixels':int(delta.sum()),'alpha_changed_pixels':int((a[...,3]!=b[...,3]).sum())};status='pass'
 if d['alpha_changed_pixels']:status='fail'
 if row!='shadow':
  mp=ROOT/f'reports/codex-art-73/{who}-{row}-mask.png'
  if not mp.exists():status='unmeasured';d['mask_missing']=rel(mp)
  else:
   mask=np.asarray(Image.open(record(mp)).convert('L'));outside=int((delta&(mask==0)).sum());band=(mask>0)&(mask<255)
   d.update(mask=rel(mp),mask_bbox=bbox(mask>0),mask_pixels=int((mask>0).sum()),outside_mask_changed_pixels=outside,seam_composite_neutral_rgb_mae=rounded(np.abs(a[...,:3].astype(float)-b[...,:3])[band].mean()),seam_pixels=int(band.sum()))
   if outside:status='fail'
 else:
  rp=ROOT/f'reports/codex-art-80/{who}-alignment-roi.png'
  if rp.exists():
   ri=Image.open(record(rp));roi=np.asarray(ri.convert('L'))>0
   # ROI files are masks in ART-80; verify mode/support rather than trust colour board.
   if roi.sum()>a.shape[0]*a.shape[1]//2:roi=np.zeros(a.shape[:2],bool);roi[32:200,32:224]=True;d['roi_fallback']='central crop because saved image is a board'
  else:roi=np.zeros(a.shape[:2],bool);roi[32:200,32:224]=True;d['roi_fallback']='central crop; saved ROI unavailable'
  def grad(x):
   lum=x[...,:3].astype(float)@np.array([.2126,.7152,.0722]);gy,gx=np.gradient(lum);return np.stack([gx,gy],2)
  ga,gb=grad(a),grad(b);scores=[]
  for dy in range(-4,5):
   for dx in range(-4,5):
    mask=roi.copy();mask[:4]=False;mask[-4:]=False;mask[:,:4]=False;mask[:,-4:]=False;mask&=b[...,3]>=128
    v=np.roll(ga,(dy,dx),(0,1))[mask].reshape(-1);t=gb[mask].reshape(-1);v-=v.mean();t-=t.mean();score=float(v@t/(np.linalg.norm(v)*np.linalg.norm(t)+1e-9));scores.append({'offset':[dx,dy],'score':rounded(score)})
  best=max(scores,key=lambda x:x['score']);d.update(applied_offset=meta.get('offset'),residual_best_offset=best['offset'],residual_ncc=best['score'],offset_scores=scores,roi_pixels=int(roi.sum()))
  if max(abs(v) for v in best['offset'])>1 or best['score']<.6:status='review' if status!='fail' else status
 item['checks']['faces']=check(status,d,'face_preservation / shadow_offset')

def sheets(items):
 by={(i['identity'],i['row']):i for i in items if i['kind']=='monster'}
 for item in items:
  if item['kind']!='monster_sheet':continue
  a=np.asarray(imread(ROOT/item['path']));rs=[]
  for j,row in enumerate(ROWS):
   source=by.get((item['identity'],row))
   if not source:rs.append({'row':row,'missing':True});continue
   b=np.asarray(imread(ROOT/source['path']));part=a[j*96:(j+1)*96];same=part.shape==b.shape
   n=int(np.any(part!=b,2).sum()) if same else None
   rs.append({'row':row,'source':source['path'],'changed_rgba_pixels':n,'equal':same and n==0})
  item['checks']['assembly']=check('pass' if all(r.get('equal') for r in rs) else 'fail',{'rows':rs},'exact RGBA pixel equality, 0 changed pixels')
  for name in ['feet','repeated','size']:
   source_checks=[{'row':row,'status':by[(item['identity'],row)]['checks'][name]['status'],'reference':by[(item['identity'],row)]['path']} for row in ROWS]
   item['checks'][name]=check(worst_status([s['status'] for s in source_checks]),{'inherited_checks':source_checks},reason='6-row sheet must satisfy the same source-row checks')

def finish(items,excluded,started):
 for i in items:
  i['overall']=worst_status([c['status'] for c in i['checks'].values()]);i['all_checks_pass']=i['overall']=='pass';i['no_measured_failure']=all(c['status']!='fail' for c in i['checks'].values())
 summary={}
 for kind in ['fighter','monster','monster_sheet','projectile','face']:
  subset=[i for i in items if i['kind']==kind];summary[kind]={'files':len(subset),'all_checks_pass':sum(i['all_checks_pass'] for i in subset),'no_measured_failure':sum(i['no_measured_failure'] for i in subset),'statuses':dict(collections.Counter(i['overall'] for i in subset)),'checks':{name:dict(collections.Counter(i['checks'][name]['status'] for i in subset)) for name in subset[0]['checks']}}
 result={'schema_version':1,'created_utc':datetime.now(timezone.utc).isoformat(),'elapsed_seconds':rounded(time.monotonic()-started),'scope':'direct candidate folders only, no adopted field; retired excluded; sheets included without sidecar','thresholds':THRESHOLDS,'summary':summary,'excluded_adopted':excluded,'files':items,'input_sha256':INPUTS,'source_integrity':{'checked':len(INPUTS),'changed':[p for p,h in INPUTS.items() if digest(ROOT/p)!=h]},'limitations':['No Godot or temporal/perceptual animation validation.','Lowest alpha pixel is not a semantic foot detector.','NCC is appearance/scale screening; rotation/occlusion can invalidate it.','Previous manual face coordinates are reused only on pixel-identical source images, not independent new anatomy measurements.','Colour/halo/checker screens cannot prove absence of every possible baked-background artifact.','fps/loop syntax and metadata can be checked; a PNG has no timing to measure.']}
 savej(OUT/'audit.json',result);print(json.dumps(summary,ensure_ascii=True),flush=True)
 return result

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--basic-only',action='store_true');parser.add_argument('--refresh-derived',action='store_true',help='Reuse pixel measurements only when every saved input hash still matches; recompute derived/semantic checks.');args=parser.parse_args();started=time.monotonic()
 items,excluded=discover();print('files',len(items),dict(collections.Counter(i['kind'] for i in items)),flush=True)
 if args.refresh_derived:
  saved=json.loads((OUT/'audit.json').read_text(encoding='utf-8'))
  assert {i['path'] for i in saved['files']}=={i['path'] for i in items},'Candidate inventory changed; run a full audit.'
  assert all((ROOT/p).exists() and digest(ROOT/p)==h for p,h in saved['input_sha256'].items()),'An input changed; run a full audit.'
  INPUTS.update(saved['input_sha256']);items=saved['files']
 else:
  for j,item in enumerate(items):
   basic(item);face_checks(item)
   if (j+1)%25==0:print(f'basic {j+1}/{len(items)}',flush=True)
 if not args.basic_only:
  cp=OUT/'measurement-cache.json';cache=json.loads(cp.read_text(encoding='utf-8')) if cp.exists() else {};size_checks(items,cache)
 halo_references(items);semantic_feet(items);sheets(items);finish(items,excluded,started)
if __name__=='__main__':main()
