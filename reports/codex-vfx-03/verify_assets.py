"""Read saved files independently; do not import or run the asset builder."""
from pathlib import Path
import json,hashlib,subprocess
import numpy as np
from PIL import Image,ImageFilter
ROOT=Path(__file__).resolve().parents[2];R=Path(__file__).resolve().parent
SPECS=[('art/bakeoff/effects/frey','frey_wings',256,6,20,[128,240],'effects/skill/frey_wings.png'),('art/bakeoff/effects/frey','frey_wave',128,4,16,[64,64],'effects/frey_wave.png'),('art/bakeoff/effects/frey','frey_ult_light',336,6,13.3,[168,168],'vfx/frey_ult_light.png'),('art/bakeoff/ui/status','slow',24,1,0,[12,12],'ui/status/slow.png'),('art/bakeoff/skill_icons/frey','frey_k',40,1,0,[20,20],'skill_icons/frey_k.png')]
checks=[];measurements=[]
def check(name,value,detail=None):checks.append({'check':name,'pass':bool(value),'detail':detail})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for folder,name,size,n,fps,anchor,replaces in SPECS:
 for v in 'ab':
  p=ROOT/folder/f'{name}-{v}-v1.png';im=Image.open(p);a=np.array(im);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'));key=f'{name}-{v}'
  check(key+'/size',im.size==(size*n,size));check(key+'/RGBA',im.mode=='RGBA');check(key+'/hard_alpha',set(np.unique(a[:,:,3]))=={0,255})
  check(key+'/metadata',meta['frames']==n and meta['fps']==fps and meta['anchor']==anchor and meta['replaces']=='smash-nine-prototype/assets/art/'+replaces)
  check(key+'/transparent_RGB_clean',bool((a[a[:,:,3]==0]==0).all()))
  ms=[];masks=[]
  for i in range(n):
   f=a[:,i*size:(i+1)*size];mask=f[:,:,3]>0;masks.append(mask);ys,xs=np.where(mask)
   check(key+f'/frame{i+1}/nonempty',len(xs)>0);edge=np.concatenate([mask[0],mask[-1],mask[:,0],mask[:,-1]])
   check(key+f'/frame{i+1}/border',not edge.any())
   bb=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
   m={'frame':i+1,'bbox':bb,'bbox_size':[bb[2]-bb[0],bb[3]-bb[1]],'min_clear_border':min(bb[0],bb[1],size-bb[2],size-bb[3]),'visible_pixels':int(mask.sum()),'visible_colours':len(np.unique(f[mask,:3],axis=0))}
   if name=='frey_ult_light':
    yy,xx=np.indices(mask.shape);dist=np.hypot(xx+.5-168,yy+.5-168);m['max_radius_screen']=float(round(dist[mask].max()*2,2))
    # Use the clear interior of the current ring, not a fixed circle that
    # incorrectly includes the expanding rim and attached feathers in frame 3.
    inner_radius=min(80,dist[mask].max()*.45);inner=dist<inner_radius
    m['inner_radius_art_px']=float(round(inner_radius,2));m['inner_alpha_coverage']=float(round(mask[inner].mean(),4))
    outer=mask&(dist>dist[mask].max()*.85);m['rim_mean_RGB']=float(round(f[outer,:3].mean(),2))
   if name=='frey_wave':check(key+f'/frame{i+1}/envelope',m['bbox_size'][0]<=60 and 98<=m['bbox_size'][1]<=100)
   ms.append(m)
  if name=='frey_wings':
   check(key+'/hold_alpha_4_6',np.array_equal(masks[3],masks[4]) and np.array_equal(masks[4],masks[5]))
   check(key+'/opening_span',all(ms[i]['bbox_size'][0]<=ms[i+1]['bbox_size'][0] for i in range(3)))
  if name=='frey_ult_light':
   check(key+'/radius_increases',all(ms[i]['max_radius_screen']<ms[i+1]['max_radius_screen'] for i in range(5)))
   check(key+'/last_rim_brightest',ms[5]['rim_mean_RGB']==max(m['rim_mean_RGB'] for m in ms))
   check(key+'/clear_inner_region',all(m['inner_alpha_coverage']<.12 for m in ms[2:]))
  if name=='frey_k':
   rgb=a[:,:,:3];navy=np.array([16,21,34]);fill=(a[:,:,3]>0)&np.any(rgb!=navy,axis=2)
   dilated=np.array(Image.fromarray(fill.astype(np.uint8)*255).filter(ImageFilter.MaxFilter(3)))>0
   outline=dilated&~fill;check(key+'/navy_1px_outline',np.array_equal(outline,(a[:,:,3]>0)&~fill))
   clustered=np.zeros(fill.shape,bool)
   for y in range(size-1):
    for x in range(size-1):
     block=a[y:y+2,x:x+2]
     if fill[y:y+2,x:x+2].all() and np.all(block==block[0,0]):clustered[y:y+2,x:x+2]=True
   check(key+'/2px_colour_clusters',np.all(clustered[fill]))
  measurements.append({'name':key,'file':p.relative_to(ROOT).as_posix(),'size':im.size,'frames':n,'fps':fps,'anchor':anchor,'sha256':sha(p),'frame_metrics':ms})
# All recorded processing scales are <=1. UI fills were placed directly at final pixels.
proc=json.loads((R/'processing.json').read_text())
check('generated_art/no_upscale',all(x.get('scale',1)<=1 and all(s<=1 for s in x.get('scale_xy',[1])) for x in proc))
check('wings/root_55px_above_feet',all(x['target_root']==[128,130] for x in proc if x['asset'].startswith('wings')))
for v in 'ab':
 inward=[x['floating_feather_radius'] for x in proc if x['asset']==f'light-{v}' and x['floating_feather_radius'] is not None]
 check(f'light-{v}/feather_inward',inward==[80,64,48,32])
# Every enlarged context board must be exact nearest, not a differently composed scene.
pairs=[]
for v in 'ab':
 pairs.extend([(f'wings_{v}_1x.png',f'wings_{v}_{z}x.png',z) for z in (2,4)])
 pairs.extend([(f'wave_{v}_1x.png',f'wave_{v}_4x.png',4),(f'icons_{v}_1x.png',f'icons_{v}_4x.png',4)])
pairs.append(('slow_1x.png','slow_4x.png',4))
for src,dst,z in pairs:
 im=Image.open(R/src);actual=Image.open(R/dst);expected=im.resize((im.width*z,im.height*z),Image.Resampling.NEAREST)
 check('board/'+dst,np.array_equal(np.array(actual),np.array(expected)))
for v in 'ab':
 im=Image.open(R/f'light_{v}_display_2x.png');check(f'light-{v}/display_board_size',im.size==(2160,1500))
 for i in range(6):
  x=(i%3)*720;y=(i//3)*750;pan=im.crop((x,y,x+720,y+750));actual=Image.open(R/f'light_{v}_f{i+1}_4x.png')
  check(f'light-{v}/frame{i+1}/4x_board',np.array_equal(np.array(actual),np.array(pan.resize((2880,3000),Image.Resampling.NEAREST))))
# Check the complete 6x4 icon boards against all 48 file crops.
manifest=json.loads((R/'board_manifest.json').read_text())
for row in manifest:
 if row['board'].startswith('icons'):
  x,y,w,h=row['rect'];board=Image.open(R/row['board']).convert('RGBA');asset=Image.open(ROOT/row['source']).convert('RGBA');expected=Image.new('RGBA',(w,h),'#141824');expected.alpha_composite(asset)
  check('icon-slot/'+row['board']+'/'+row['source'].split('/')[-1],np.array_equal(np.array(board.crop((x,y,x+w,y+h))),np.array(expected)))
baseline=json.loads((R/'product-baseline.json').read_text())
current={p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'smash-nine-prototype').rglob('*') if p.is_file() and '.godot' not in p.parts}
changed=sorted(k for k in set(baseline)|set(current) if baseline.get(k)!=current.get(k))
check('product_tree/unchanged',not changed,{'checked_files':len(baseline),'changed':changed})
def git(*args):return subprocess.run(['git',*args],cwd=ROOT,text=True,capture_output=True,check=True).stdout
old=set((R/'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines());now=set(git('status','--porcelain=v1','--untracked-files=all').splitlines());new=sorted(now-old)
allowed=('art/bakeoff/effects/frey/','art/bakeoff/ui/status/slow-','art/bakeoff/skill_icons/frey/','reports/codex-vfx-03/','art/raw/vfx-03/')
unexpected=[s for s in new if not s[3:].startswith(allowed)]
check('workspace/only_allowed_new_changes',not unexpected,unexpected)
ignored=subprocess.run(['git','check-ignore','art/raw/vfx-03/wings-a.png'],cwd=ROOT,capture_output=True,text=True)
check('raw/git_ignored',ignored.returncode==0,ignored.stdout.strip())
summary={'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'checks':checks,'known_contract_conflict':'256px wings @0.5 with 1px margins max 127 screen px, cannot be 170px','game_runtime_tested':False}
(R/'measurements.json').write_text(json.dumps(measurements,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(R/'verification.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('checks',summary['passed'],'PASS /',summary['failed'],'FAIL')
for c in checks:
 if not c['pass']:print('FAIL',c)
for m in measurements:print(m['name'],m['size'],[f['bbox_size'] for f in m['frame_metrics']])
for folder in [R,ROOT/'art/raw/vfx-03']:
 print('folder MiB',folder.relative_to(ROOT),round(sum(p.stat().st_size for p in folder.rglob('*') if p.is_file())/1048576,2))
raise SystemExit(1 if summary['failed'] else 0)
