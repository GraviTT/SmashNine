"""Read-only candidate verification, report output only; no Godot or git mutations."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,subprocess,hashlib,ast
from pathlib import Path
import numpy as np
from PIL import ImageFilter
import work as w
from deliver import metrics,speckle_stats,ROWS,COUNTS
checks=[]
def ck(name,ok,detail=None):checks.append(dict(name=name,pass_=bool(ok),detail=detail))
def array(p):return np.asarray(w.load(p))
def main():
 outputs=json.loads((w.REPORT/'outputs.json').read_text('utf-8'));allowed=set(outputs)
 baseline=json.loads((w.REPORT/'baseline.json').read_text('utf-8'));unexpected=[];kept=0
 for p,h in baseline.items():
  if p not in allowed:
   if not (w.ROOT/p).exists() or w.sha(w.ROOT/p)!=h:unexpected.append(p)
   else:kept+=1
 ck('all pre-existing non-output protected files byte-identical',not unexpected,dict(count=kept,unexpected=unexpected))
 changed_total=0
 for row,ver,count in [('attack','v1',6),('defeat','v2',4)]:
  before=w.frames(w.copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-{ver}.png'),count)
  p=w.BAKE/f'monsters/yggdrasil_root_guardian-{row}-v2.png';after=w.frames(p,count);meta=json.loads(p.with_suffix('.json').read_text('utf-8'))
  oldmeta=json.loads(w.copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-{ver}.json').read_text('utf-8'))
  ck('guardian '+row+' timing/scale unchanged',all(meta[k]==oldmeta[k] for k in ['frames','fps','loop','cell','feet','factor']))
  for i,(a,b) in enumerate(zip(before,after)):
   same=a.tobytes()==b.tobytes();ck(f'guardian {row} F{i+1} expected change',same==(i!=0));changed_total+=not same
   m=metrics(b);ck(f'guardian {row} F{i+1} margin/feet/alpha/spill',m['margin']>=4 and m['bottom']==72 and set(m['alpha_values'])<={0,255} and m['spill_legacy']==0,m)
 houndstats=[]
 for row,count in zip(ROWS,COUNTS):
  p=w.BAKE/f'monsters/vanaheim_vine_hound-{row}-v2.png';old=w.copy(f'art/bakeoff/monsters/vanaheim_vine_hound-{row}-v2.png');fs=w.frames(old,count);ns=w.frames(p,count)
  meta=json.loads(p.with_suffix('.json').read_text('utf-8'));om=json.loads(w.copy(f'art/bakeoff/monsters/vanaheim_vine_hound-{row}-v2.json').read_text('utf-8'))
  ck('hound '+row+' timing/scale unchanged',all(meta[k]==om[k] for k in ['frames','fps','loop','cell','feet','factor']))
  stats=[]
  for i,(a,b) in enumerate(zip(fs,ns)):
   aa=np.asarray(a);bb=np.asarray(b);expected,_=w.speckle(a,.8);rgb=aa[:,:,:3].astype(float)
   eye=(rgb[:,:,0]>150)&(rgb[:,:,1]>180)&(rgb[:,:,2]>100)&(aa[:,:,3]>0);protected=np.asarray(w.Image.fromarray((eye*255).astype('uint8')).filter(ImageFilter.MaxFilter(7)))>0
   ck(f'hound {row} F{i+1} deterministic RGB-only cleaning',expected.tobytes()==b.tobytes() and np.array_equal(aa[:,:,3],bb[:,:,3]) and np.array_equal(aa[protected],bb[protected]))
   m=metrics(b);ck(f'hound {row} F{i+1} margin/binary alpha',m['margin']>=4 and set(m['alpha_values'])<={0,255})
   ck(f'hound {row} F{i+1} no pure chroma',not np.any((bb[:,:,0]==0)&(bb[:,:,1]==255)&(bb[:,:,2]==0)&(bb[:,:,3]>0)))
   stats.append(speckle_stats(a,b));changed_total+=a.tobytes()!=b.tobytes()
  ck('hound '+row+' empty unused cells',not array(p)[:,count*96:,3].any());houndstats.append(dict(row=row,frames=stats))
 for mid in ['yggdrasil_root_guardian','vanaheim_vine_hound']:
  p=w.BAKE/f'monsters/{mid}_sheet-v2.png';a=array(p);ck(mid+' sheet dimensions',a.shape==(576,576,4))
  for ri,row in enumerate(ROWS):
   path=w.BAKE/f'monsters/{mid}-{row}-v2.png'
   if not path.exists():path=w.BAKE/f'monsters/{mid}-{row}-v1.png'
   ck(mid+' sheet row '+row,np.array_equal(a[ri*96:(ri+1)*96],array(path)))
 p=w.BAKE/'monsters/legacy/alfheim_moon_stag_sheet-fix1.png';before=array(w.copy('art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.png'));after=array(p);hashes=[]
 ck('stag dimensions',after.shape==(384,576,4))
 for r in range(4):
  for c in range(6):
   a=before[r*96:(r+1)*96,c*96:(c+1)*96];b=after[r*96:(r+1)*96,c*96:(c+1)*96];changed=r==2 and c<4
   ck(f'stag row{r} cell{c} change scope',np.array_equal(a,b)!=changed)
   if changed:
    changed_total+=1;m=metrics(w.Image.fromarray(b));hashes.append(m['rgba_sha256']);ck(f'stag attack F{c+1} margin/feet',m['margin']>=4 and m['bottom']==71,m)
 ck('stag four distinct RGBA frames',len(set(hashes))==4)
 meta=json.loads(p.with_suffix('.json').read_text('utf-8'));ck('stag candidate SHA matches metadata',meta['candidate_file_sha256']==w.sha(p))
 for sex in ['female','male']:
  game=w.ROOT/f'smash-nine-prototype/assets/art/nova/nova_{sex}_moves_sheet.png';w.copy(str(game.relative_to(w.ROOT)))
  ck('Nova '+sex+' adopted meteor strip equals current game row5',np.array_equal(array(game)[4*192:5*192],array(w.BAKE/f'nova/nova_{sex}-meteor_kick-v1.png')))
 ck('no fighter candidate created',not (w.BAKE/'luna/luna-fall-v4.png').exists() and not (w.BAKE/'nova/nova_male-meteor_kick-v2.png').exists() and not (w.BAKE/'nova/nova_female-meteor_kick-v2.png').exists())
 for p in w.REPORT.glob('*.py'):ast.parse(p.read_text('utf-8'));ck(p.name+' parses',True)
 status=subprocess.check_output(['git','status','--porcelain'],cwd=w.ROOT).decode('utf-8');tracked=[line[3:].replace('\\','/') for line in status.splitlines() if not line.startswith('??')]
 ck('tracked mutations only approved outputs',set(tracked)<=allowed,tracked)
 staged=subprocess.check_output(['git','diff','--cached','--name-only'],cwd=w.ROOT).decode('utf-8').strip();ck('git index untouched and empty',not staged,staged)
 sources={str(p.relative_to(w.ROOT)).replace('\\','/'):w.sha(p) for p in (w.RAW/'inputs').rglob('*') if p.is_file()}
 generated={str(p.relative_to(w.ROOT)).replace('\\','/'):w.sha(p) for p in w.RAW.glob('*generated.png')};w.js(w.REPORT/'source-manifest.json',dict(inputs=sources,generated=generated))
 summary=dict(total=len(checks),passed=sum(x['pass_'] for x in checks),failed=[x for x in checks if not x['pass_']],changed_unique_frames=changed_total,protected_files_unchanged=kept,head_review='Luna manual pass; Nova nominal small outliers remain uncertain, NOT certified within tolerance; no new fighter versions',godot_run=False,checks=checks)
 w.js(w.REPORT/'verification.json',summary);w.js(w.REPORT/'hound-statistics.json',houndstats)
 print(json.dumps({k:v for k,v in summary.items() if k!='checks'},ensure_ascii=False,indent=2))
 if summary['failed']:raise SystemExit(1)
if __name__=='__main__':main()
