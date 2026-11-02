"""Exclusive row packaging after visual review; append progress immediately."""
import os,sys,json,datetime,hashlib,io
from pathlib import Path
from PIL import Image
import numpy as np
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
R=Path('reports/codex-art-92');stem,row,label=sys.argv[1:4]
source=Path('art/raw/motions-92')/f'{stem}-{row}'/label
variant=json.loads((source/'variant.json').read_text());metrics=json.loads((source/'metrics.json').read_text());face=json.loads((source/'face-proposed.json').read_text())
review=json.loads(Path(sys.argv[4]).read_text(encoding='utf-8'))
assert review['costume_pass'] and review['motion_pass'] and review['contact_pass']
folder=Path(variant['anchor']).parent.name
cell=192 if row=='taunt' else 128;feet=cell//2+56
im=Image.open(source/f'{stem}-{row}.png').convert('RGBA');assert im.size==(6*cell,cell)
hashes=[];checks=[]
for j in range(6):
 f=im.crop((j*cell,0,(j+1)*cell,cell));ar=np.asarray(f);ys,xs=np.where(ar[...,3]>0)
 margin=int(min(xs.min(),ys.min(),cell-1-xs.max(),cell-1-ys.max()));detail=n.interior_detail(f);spill=n.spill_pixel_count(f)
 assert margin>=4 and detail>=79 and spill==0 and int(ys.max())==feet
 hashes.append(hashlib.sha256(f.tobytes()).hexdigest());checks.append({'frame':j+1,'margin':margin,'detail':detail,'spill':spill,'bottom':int(ys.max())})
assert len(set(hashes))==6
measured=[]
for f in face['frames']:
 f=dict(f)
 if str(f['frame']) in review.get('exclude',{}):
  f['eye_ratio']=None;f['face_width_ratio']=None;f['reason']=review['exclude'][str(f['frame'])]
 if review.get('hidden_far_eye') and f['eye_ratio'] is not None:
  f['raw_proposed_eye_ratio']=f['eye_ratio'];f['eye_ratio']=None;f['reason']='기준부터 먼 눈이 머리카락에 가려 E 측정 불가; W만 검토'
 assert all(v is None or .96<=v<=1.04 for v in [f['eye_ratio'],f['face_width_ratio']])
 measured.append(f)
assert any(f['face_width_ratio'] is not None for f in measured)
now=datetime.datetime.now().astimezone().isoformat(timespec='seconds')
target=Path(f'art/bakeoff/{folder}/{stem}-{row}-v1.png')
paths=[target,target.with_suffix('.json'),R/f'{stem}-{row}.png',R/f'{stem}-{row}-checks.json',R/f'{stem}-{row}-result.json']
assert not any(p.exists() for p in paths)
def write(p,b):
 with p.open('xb') as f:f.write(b if isinstance(b,bytes) else b.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
ratios='; '.join(f"F{f['frame']} E={f['eye_ratio']} W={f['face_width_ratio']}" for f in measured)
note=review['note']+' 얼굴 idle 대비: '+ratios+'. None은 회전/가림/감은 눈으로 측정 제외이며 통과 수치가 아님. 전체 행 공통 배율 '+str(variant['factor'])+'. 후보이며 실제 재생과 게임 적용은 미검증.'
meta={'note':note,'frames':6,'fps':{'dodge_roll':14,'taunt':8,'stun':8,'crouch':12,'run_start':14}[row],'cell':cell,'feet':feet,'loop':row=='stun','new_row':True,'status':'candidate','factor':variant['factor'],'source_task':'CODEX-ART-92','face_ratios':measured}
write(target,(source/f'{stem}-{row}.png').read_bytes());dump(target.with_suffix('.json'),meta);write(paths[2],(source/'board.png').read_bytes())
evidence={'time':now,'variant':variant,'normalization':metrics['summary'],'checks':checks,'distinct_frame_sha256':hashes,'face':{**face,'frames':measured},'visual_review':review,'anchor_sha256':hashlib.sha256(Path(variant['anchor']).read_bytes()).hexdigest()}
dump(paths[3],evidence)
result={'time':now,'stem':stem,'row':row,'status':'pass','frames':6,'candidate':target.as_posix(),'board':paths[2].as_posix(),'checks':checks,'face_ratios':measured,'note':review['note']}
dump(paths[4],result)
with (R/'progress.md').open('a',encoding='utf-8') as f:f.write(f"{now} | {stem} | {row} | {target.as_posix()} | 6 | PASS: margin {min(x['margin'] for x in checks)}, detail {min(x['detail'] for x in checks):.2f}, spill 0, distinct 6/6; {ratios} | {review['note']}\n")
with (R/'commit-paths.txt').open('a',encoding='utf-8') as f:f.write(''.join(p.as_posix()+'\n' for p in paths))
print(json.dumps({'delivered':target.as_posix(),'checks':checks},ensure_ascii=False))
