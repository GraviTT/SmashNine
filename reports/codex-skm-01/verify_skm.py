"""Validate artifacts, actual pixels, extraction records, candidate gate, staging scope."""
from pathlib import Path
import json,sys,re,subprocess,hashlib
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
root=Path('reports/codex-skm-01');state=json.loads((root/'state.json').read_text(encoding='utf-8'))
checks=[]
def check(label,ok):
 checks.append({'check':label,'pass':bool(ok)})
 if not ok:print('FAIL:',label)
for row,s in state.items():
 raws=list(Path('art/raw/skm-01').glob(f'frey-{row}-[12].png'));check(row+' max two generations',len(raws)==2)
 out=root/'frey'/row/f'attempt-{s["attempt"]}';m=json.loads((out/'metrics.json').read_text());x=json.loads((out/'extraction.json').read_text())
 im=Image.open(out/f'frey-{row}.png').convert('RGBA')
 check(row+' output 1152x192',im.size==(1152,192));factor=m['summary']['common_scale'];check(row+' downscale only',0<factor<=1)
 check(row+' one common factor',m['summary']['scale_by']==f'fixed:{factor}')
 check(row+' exact pipeline settings',all(m['summary'][k]==v for k,v in {'resample':'lanczos','sharpen_percent':60,'despill':'auto','palette':'none'}.items()))
 check(row+' blob extraction not fixed width','no fixed-width' in x['method'] and len(x['boxes'])==6)
 check(row+' source pixels accounted',len(x['component_sizes'])>=6)
 for i in range(6):
  f=im.crop((i*192,0,(i+1)*192,192));a=np.array(f);box=f.getbbox();label=f'{row} F{i+1}'
  check(label+' binary alpha',set(np.unique(a[...,3])).issubset({0,255}))
  check(label+' 4px margin',min(box[0],box[1],192-box[2],192-box[3])>=4)
  check(label+' border clear',not any([a[0,:,3].any(),a[-1,:,3].any(),a[:,0,3].any(),a[:,-1,3].any()]))
  check(label+' spill zero',n.spill_pixel_count(f)==0);check(label+' detail >=79',n.interior_detail(f)>=79)
  check(label+' metrics detail agrees',n.interior_detail(f)==m['frames'][i]['interior_detail'])
  if row in ['shield_bash','sword_plant']:check(label+' grounded y152',box[3]-1==152)
 for j in range(1,4):check(row+f' 4x review page {j}',Image.open(out/f'review4x-{j}.png').size==(2048,768))
 check(row+' root board exists',(root/f'frey-{row}.png').exists())
 p=Path(f'art/bakeoff/frey/frey-{row}-v1.png');q=p.with_suffix('.json')
 check(row+' delivery matches status',p.exists()==s['pass'] and q.exists()==s['pass'])
 if s['pass']:
  check(row+' copied pixels exact',p.read_bytes()==(out/f'frey-{row}.png').read_bytes())
  meta=json.loads(q.read_text(encoding='utf-8'));check(row+' metadata',meta['frames']==6 and meta['cell']==192 and meta['feet']==[96,152] and meta['factor']==factor and meta['loop'] is False and bool(meta['for']))
  fs=json.loads((out/'face-proposed.json').read_text())['frames'];check(row+' strict face gate',all(.96<=f['eye_ratio']<=1.04 and .96<=f['face_width_ratio']<=1.04 for f in fs))
  check(row+' both board and manual review',s.get('visual_review_complete',False))
ps=(root/'commit.ps1').read_text(encoding='utf-8-sig');paths=re.findall(r"^    '([^']+)'$",ps,re.M)
for p in paths:
 check('stage scope '+p,p=='design/tasks/CODEX-SKM-01.md' or p.startswith('reports/codex-skm-01/') or re.fullmatch(r'art/bakeoff/frey/frey-(hover_dash|launch_chase|shield_bash|sword_plant|air_hover_swing)-v1\.(png|json)',p))
 check('stage exists '+p,Path(p).is_file());check('stage exclusions '+p,'art/raw/' not in p and '__pycache__' not in p and not p.endswith('run.log'))
check('commit no force add','git add -f' not in ps);check('commit coauthor','Co-Authored-By: Codex <noreply@openai.com>' in ps)
changes=subprocess.check_output(['git','diff','--name-only'],text=True).splitlines();check('no tracked files changed',not changes)
result={'scope':'artifact validation, not a game execution test; pass counts do not imply artistic acceptance','checks':checks,'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'delivered':[r for r,s in state.items() if s['pass']]}
(root/'audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in result.items() if k!='checks'},ensure_ascii=False));sys.exit(1 if result['failed'] else 0)
