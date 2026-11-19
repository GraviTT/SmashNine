from pathlib import Path
import json,subprocess,re
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
R=ROOT/'reports/codex-art-95a'
metrics=json.loads((R/'metrics.json').read_text(encoding='utf-8'))
checks=[]
def check(name,ok):
 checks.append({'check':name,'pass':bool(ok)})
 if not ok: raise AssertionError(name)
for c in 'cd':
 base=ROOT/f'art/bakeoff/xion/{c}'
 im=Image.open(base/f'xion_illustration-{c}.png');a=np.array(im)
 check(c+' illustration format',im.size==(1024,1536) and im.mode=='RGBA')
 check(c+' alpha range',a[:,:,3].min()==0 and a[:,:,3].max()==255)
 check(c+' transparent RGB',not np.any(a[:,:,:3][a[:,:,3]==0]))
 check(c+' border clear',not np.any(a[0,:,3]) and not np.any(a[-1,:,3]) and not np.any(a[:,0,3]) and not np.any(a[:,-1,3]))
 check(c+' hologram alpha sample',int(a[440,330,3])==140)
 check(c+' main face/coat alpha samples',int(a[280,630,3])==255 and int(a[650,600,3])==255)
 sp=Image.open(base/f'xion-idle-{c}.png');sa=np.array(sp)
 ref=np.array(Image.open(R/f'normalize-{c}/xion-idle-{c}.png').crop((0,0,128,128)))
 check(c+' sprite format',sp.size==(128,128) and sp.mode=='RGBA')
 check(c+' unmodified first normalized cell',np.array_equal(sa,ref))
 m=metrics['concepts'][c]['sprite']
 check(c+' height/feet/margin',95<=m['height']<=100 and m['feet_y']==120 and m['margin']['minimum']>=4)
 check(c+' spill/border/alpha',m['green_spill']==0 and m['border_clear'] and m['alpha_binary'])
 check(c+' detail >=90% of Rio F1',m['detail_ratio_vs_rio_f1']>=0.9)
 note=json.loads((base/f'xion-idle-{c}.json').read_text(encoding='utf-8'))
 check(c+' one-frame JSON',note['frames']==1 and any('\uac00'<=ch<='\ud7a3' for ch in note['note']))
check('lineup',Image.open(R/'lineup.png').size==(2360,1280))
commit=(R/'commit.ps1').read_text(encoding='utf-8')
paths=re.findall(r"^    '([^']+)'",commit,re.M)
check('commit literal path array',len(paths)==55 and '$paths = @(' in commit)
check('commit paths exist',all((ROOT/p).is_file() for p in paths))
check('commit scope',all(p=='design/tasks/CODEX-ART-95.md' or p.startswith(('art/bakeoff/xion/c/','art/bakeoff/xion/d/','reports/codex-art-95a/')) for p in paths))
check('commit no forced add or raw','add -f' not in commit and all(not p.startswith('art/raw/') for p in paths))
check('commit co-author','Co-Authored-By: Codex <noreply@openai.com>\n\'@' in commit)
for folder in [R,ROOT/'art/bakeoff/xion/c',ROOT/'art/bakeoff/xion/d']:
 for p in folder.rglob('*'):
  if p.suffix in ['.py','.ps1','.txt','.json','.md']:
   t=p.read_text(encoding='utf-8');check('UTF-8 '+str(p.relative_to(ROOT)),'\ufffd' not in t)
tracked=subprocess.run(['git','diff','--name-only'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.splitlines()
staged=subprocess.run(['git','diff','--cached','--name-only'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.splitlines()
check('no tracked changes',not tracked)
check('no staged changes',not staged)
sizes={}
for rel in ['art/bakeoff/xion/c','art/bakeoff/xion/d','art/raw/xion-95a','reports/codex-art-95a']:
 sizes[rel]=sum(p.stat().st_size for p in (ROOT/rel).rglob('*') if p.is_file())
result={'passed':len(checks),'checks':checks,'folder_bytes':sizes,'total_bytes':sum(sizes.values()),'commit_script_executed':False,'game_executed':False}
(R/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':len(checks),'task_MiB':round(sum(sizes.values())/1024**2,2),'tracked_changes':tracked,'staged_changes':staged},ensure_ascii=False))
