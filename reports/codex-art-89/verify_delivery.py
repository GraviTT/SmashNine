"""Read-only checks of packaged ART-89 images, metadata and commit scope.
Only audit.json is written, exclusively. Godot and git mutations are never run.
"""
import os,sys,json,hashlib,subprocess,math
from pathlib import Path
import numpy as np
from PIL import Image
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
R=Path('reports/codex-art-89')
results=json.loads((R/'results.json').read_text(encoding='utf-8'))
ledger=json.loads((R/'generation-ledger.json').read_text(encoding='utf-8'))
checks=[]
def check(name,passed,detail=None):checks.append({'check':name,'pass':bool(passed),'detail':detail})
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
check('branch',subprocess.check_output(['git','branch','--show-current'],text=True).strip()=='codex/art-89')
diff=subprocess.check_output(['git','diff','--name-only'],text=True).splitlines()
staged=subprocess.check_output(['git','diff','--cached','--name-only'],text=True).splitlines()
check('tracked_files_unchanged',not diff,diff);check('nothing_staged',not staged,staged)
check('24 whole-row generations',len(ledger)==24)
for row in results:
 key=f"{row['stem']}-{row['row']}";p=Path(row['best']);im=Image.open(p).convert('RGBA');cell=row['cell'];count=row['frames']
 metrics=json.loads((p.parent/'metrics.json').read_text(encoding='utf-8'))
 proposed=json.loads((p.parent/'face-proposed.json').read_text(encoding='utf-8'))
 measured=json.loads((p.parent/'face-measured.json').read_text(encoding='utf-8'))
 check(key+' dimensions',im.size==(metrics['summary']['output_columns']*cell,cell))
 check(key+' anchor preserved',sha(row['anchor'])==row['anchor_sha256'])
 check(key+' current preserved',sha(row['source_original'])==row['source_sha256'])
 check(key+' no pixel assembly or extra edit',sha(p)==sha(R/row['attempt']/p.name))
 check(key+' same row factor',metrics['summary']['common_scale']==row['factor'])
 check(key+' normaliser settings',metrics['summary']['resample']=='lanczos' and metrics['summary']['sharpen_percent']==60 and metrics['summary']['despill']=='auto' and metrics['summary']['palette']=='none')
 gens=[g for g in ledger if g['stem']==row['stem'] and g['row']==row['row']]
 check(key+' generation cap',1<=len(gens)<=3 and len(gens)==row['gen'])
 for i in range(count):
  f=im.crop((i*cell,0,(i+1)*cell,cell));a=np.asarray(f);ys,xs=np.where(a[...,3]>0)
  margin=min(xs.min(),ys.min(),cell-1-xs.max(),cell-1-ys.max())
  detail=n.interior_detail(f);spill=n.spill_pixel_count(f)
  check(f'{key} F{i+1} alpha/border/margin/spill/detail',set(np.unique(a[...,3])).issubset({0,255}) and margin>=4 and spill==0 and detail>=79,{'margin':int(margin),'spill':spill,'detail':round(detail,2)})
  grounded=row['row'] in ['victory','hurt','walk']
  check(f'{key} F{i+1} vertical placement',int(ys.max())==row['feet_y'] if grounded else int(ys.max())<row['feet_y'],{'lowest_visible_pixel':int(ys.max()),'expected_ground':row['feet_y'],'grounded':grounded,'limitation':'최저 알파 픽셀의 위치 검사. 부츠 접지는 4배 육안 검토로 구분함.'})
  m=measured['frames'][i];pr=proposed['frames'][i]
  if m['eye_ratio'] is not None:
   marks=pr['landmarks'];e=round(math.dist((marks[0]['x'],marks[0]['y']),(marks[1]['x'],marks[1]['y']))/proposed['reference_eye_distance'],3)
   check(f'{key} F{i+1} E evidence',abs(e-m['eye_ratio'])<=.001,{'recomputed':e,'recorded':m['eye_ratio']})
  if m['face_width_ratio'] is not None:
   w=round(abs(pr['landmarks'][3]['x']-pr['landmarks'][2]['x'])/proposed['reference_face_width'],3)
   check(f'{key} F{i+1} W evidence',abs(w-m['face_width_ratio'])<=.001,{'recomputed':w,'recorded':m['face_width_ratio']})
  if row['deliver']:check(f'{key} F{i+1} measurable face threshold',all(v is None or .96<=v<=1.04 for v in [m['eye_ratio'],m['face_width_ratio']]))
 if im.width>count*cell:check(key+' unused columns transparent',not np.asarray(im)[:,count*cell:,3].any())
 check(key+' comparison board exists',(R/f'{key}.png').is_file())
 if row['deliver']:
  candidate=Path(row['candidate']);meta=json.loads(candidate.with_suffix('.json').read_text(encoding='utf-8'))
  check(key+' delivered copy',sha(candidate)==sha(p)==row['candidate_sha256'])
  check(key+' candidate metadata',meta['replaces']==Path(row['source_original']).name and meta['frames']==count and meta['cell']==cell and meta['feet']==row['feet_y'] and meta['status']=='candidate')
  check(key+' delivery gate',row['face_pass'] and row['motion'])
 else:check(key+' withheld candidate',row['candidate'] is None)
for g in ledger:
 check(f"raw {g['stem']}-{g['row']}-{g['generation']}",Path(g['raw']).is_file() and all(Path(p).is_file() for p in g['references']) and bool(g['prompt']))
paths=(R/'commit-paths.txt').read_text(encoding='utf-8').splitlines()
allowed_prefixes=['reports/codex-art-89/','art/bakeoff/frey/','art/bakeoff/luna/','art/bakeoff/yuki/','art/bakeoff/nova/','art/bakeoff/rio/']
cards=['design/tasks/CODEX-ART-89.md','design/tasks/CODEX-ART-89.prompt.md']
for p in paths:
 allowed=(p in cards or any(p.startswith(s) for s in allowed_prefixes))
 forbidden=any(s in p for s in ['art/raw/','ref82/','__pycache__','run.log','/attempts/','/review/','/attempt-'])
 check('manifest '+p,allowed and not forbidden and (Path(p).is_file() or p==str(R/'audit.json').replace('\\','/')))
check('manifest includes both task inputs',all(p in paths for p in cards))
check('manifest includes all candidate pairs',all(p in paths for r in results if r['deliver'] for p in [r['candidate'],str(Path(r['candidate']).with_suffix('.json')).replace('\\','/')]))
check('manifest has no duplicates',len(paths)==len(set(paths)))
ignored=subprocess.run(['git','check-ignore','--stdin'],input='\n'.join(paths)+'\n',text=True,capture_output=True)
check('manifest paths not ignored',ignored.returncode==1 and not ignored.stdout,ignored.stdout)
audit={'status':'pass' if all(c['pass'] for c in checks) else 'fail','checks':checks,'counts':{'checks':len(checks),'rows':len(results),'reviewed_frames':49,'delivered_rows':5,'delivered_frames':24},'limitations':['얼굴 대응점과 동작/복장 판정은 별도 4배 육안 검토. 자동 검사가 미학적 품질이나 정확한 얼굴 동일성을 증명하지 않음.','Godot, 실제 모션 뷰어 재생, 배포, git add/commit을 실행하지 않음.','중간 출력 덮어쓰기 1건은 processing-incident.txt에 기록. 최종 패키지는 해당 혼합 디렉터리를 사용하지 않음.']}
with (R/'audit.json').open('x',encoding='utf-8',newline='\n') as f:json.dump(audit,f,ensure_ascii=False,indent=2)
print(json.dumps({'status':audit['status'],'checks':len(checks),'failures':[c for c in checks if not c['pass']]},ensure_ascii=False))
raise SystemExit(0 if audit['status']=='pass' else 1)
