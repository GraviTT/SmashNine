"""Package selected whole-row outputs. Every write is exclusive; no overwrites."""
import json,hashlib,io
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path('reports/codex-art-89')
rows=json.loads((ROOT/'selection.json').read_text(encoding='utf-8'))
counts={'victory':6,'jump':3,'hurt':3,'fall':2,'walk':8}
versions={'frey':2,'luna':3,'luna_brave':4,'yuki':2,'nova_female':2,'rio_male':2}
def write(path,data):
 path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(data if isinstance(data,bytes) else data.encode('utf-8'))
def dump(path,data):write(path,json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def copy(src,dst):write(dst,Path(src).read_bytes())
def save(path,im):
 b=io.BytesIO();im.save(b,format='PNG');write(path,b.getvalue())
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def range_of(frames,key):
 v=[f[key] for f in frames if f[key] is not None]
 return [min(v),max(v)] if v else None
assert not (ROOT/'best').exists(), 'Refusing to overwrite an earlier package'
results=[]
for row in rows:
 stem,motion=row['stem'],row['row'];key=f'{stem}-{motion}'
 source=ROOT/row['attempt'];dest=ROOT/'best'/key
 metrics=json.loads((source/'metrics.json').read_text(encoding='utf-8'));summary=metrics['summary']
 proposed=json.loads((source/'face-proposed.json').read_text(encoding='utf-8'))
 head=json.loads((source/'head-scale.json').read_text(encoding='utf-8'))
 measured=[]
 for f in proposed['frames']:
  i=f['frame'];excluded=i in row['exclude'];hidden=stem in ['nova_female','rio_male']
  e=None if excluded or hidden else f['eye_ratio'];w=None if excluded else f['face_width_ratio']
  why='감은 눈과 얼굴 기울기: 프레임 수치 제외' if excluded and motion=='hurt' else '윙크: 프레임 수치 제외' if excluded else '기준부터 먼 눈이 머리카락에 가림: E 측정 불가' if hidden else ''
  measured.append({'frame':i,'eye_ratio':e,'face_width_ratio':w,'exclusion_reason':why,'raw_proposed_eye_ratio':f['eye_ratio'],'raw_proposed_width_ratio':f['face_width_ratio'],'landmarks':f['landmarks'],'within_range':all(v is None or .96<=v<=1.04 for v in [e,w])})
 face_pass=all(f['within_range'] for f in measured) and any(f['face_width_ratio'] is not None for f in measured)
 measure={'method':'ART-72 계열 4배 대응점 제안 + 4배 직접 검토. E는 눈 간격, W는 눈 아래 노출 얼굴 폭. 제외값은 통과값으로 대체하지 않음. 소수점은 정확도 보증이 아님.','anchor_face_width':proposed['reference_face_width'],'frames':measured,'eye_range':range_of(measured,'eye_ratio'),'width_range':range_of(measured,'face_width_ratio'),'face_pass':face_pass,'judgment':row['reason']}
 if stem=='frey' and motion=='victory':measure['width_limitation']='F4–6 폭 대응점은 올린 팔/머리카락 영향으로 신뢰도 낮음. E 초과만으로도 미납품.'
 if stem=='nova_female':measure['width_limitation']='F6 자동 폭 대응점 점수가 낮아 4배 경계를 따로 확인. E는 모든 프레임 측정 불가.'
 if stem=='rio_male':measure['width_limitation']='폭 제안값이며 확정 통과 판정에 사용하지 않음. 승리 F5는 격자에서 anchor 68–83(15px), 새 100–116(16px) 확인. 걷기는 동작도 미달.'
 for filename in [f'{key}.png','metrics.json','head-scale.json','face-proposed.json','face-landmarks-proposed.png','variant.json']:
  copy(source/filename,dest/filename)
 dump(dest/'face-measured.json',measure)
 review=ROOT/'review'/row['review']
 copy(review/'comparison.png',ROOT/f'{key}.png')
 for page in sorted(review.glob('F*.png')):copy(page,ROOT/'qa4x'/key/page.name)
 if key=='rio_male-victory':
  for grid in ['grid-F0.png','grid-F5.png']:copy(source/grid,dest/grid)
 old=Path(f"art/bakeoff/{row['folder']}/{key}-v{row['old']}.png")
 anchor=Path(f"art/bakeoff/{row['folder']}/{stem}-idle-v{versions[stem]}.png")
 assert sha(old)==sha(f'art/raw/motions-89/{key}-current-original.png')
 assert sha(anchor)==sha(f'art/raw/motions-89/{key}-anchor-original.png')
 minimum=min(f['margin']['minimum'] for f in metrics['frames'])
 result={**row,'frames':counts[motion],'cell':metrics['normalization']['cell'],'eye_range':measure['eye_range'],'width_range':measure['width_range'],'face_pass':face_pass,'minimum_margin':minimum,'detail':summary['interior_detail_range'],'height_range':summary['body_height_range'],'feet_y':metrics['normalization']['feet_y'],'bottoms':[f['bottom'] for f in metrics['frames']],'head_median':head['median'],'source_original':str(old).replace('\\','/'),'source_sha256':sha(old),'anchor':str(anchor).replace('\\','/'),'anchor_sha256':sha(anchor),'best':str(dest/f'{key}.png').replace('\\','/'),'candidate':None,'measurement':str(dest/'face-measured.json').replace('\\','/')}
 if row['deliver']:
  assert face_pass and row['motion'] and minimum>=4 and min(summary['interior_detail_range'])>=79
  assert summary['alpha_binary'] and summary['borders_clear'] and not any(summary['remaining_spill_pixels'])
  v=row['old']+1
  while any(Path(f"art/bakeoff/{row['folder']}/{key}-v{v}.{ext}").exists() for ext in ['png','json']):v+=1
  target=Path(f"art/bakeoff/{row['folder']}/{key}-v{v}.png")
  per='; '.join(f"F{f['frame']} E={f['eye_ratio'] if f['eye_ratio'] is not None else '측정 제외'} W={f['face_width_ratio'] if f['face_width_ratio'] is not None else '측정 제외'}" for f in measured)
  note=f"ART-89 전체 행 재생성 {row['gen']}회 중 {row['gen']}차 선택. {row['reason']} 얼굴 idle 대비 비율: {per}. 측정 가능한 값은 0.96–1.04 충족. 행 전체 공통 배율 {row['factor']}, LANCZOS + unsharp 60 + despill auto, 팔레트 제한 없음. 프레임별 크기 보정·머리 붙이기 없음. 후보이며 게임 미연결, 실제 재생·사용자 채택 미확인."
  meta={'note':note,'fps':{'jump':10,'hurt':12,'victory':8}[motion],'frames':counts[motion],'loop':False,'hold_last':True,'factor':row['factor'],'cell':result['cell'],'feet':result['feet_y'],'replaces':old.name,'status':'candidate','source_task':'CODEX-ART-89','generation':row['gen'],'face_ratios':[{k:f[k] for k in ['frame','eye_ratio','face_width_ratio','exclusion_reason']} for f in measured]}
  copy(source/f'{key}.png',target);dump(target.with_suffix('.json'),meta)
  result['candidate']=str(target).replace('\\','/');result['candidate_sha256']=sha(target)
 results.append(result)
 if motion=='walk':
  # Native 1x, not enlarged. Current and final attempt with all eight frames.
  oldim=Image.open(old).convert('RGBA');newim=Image.open(source/f'{key}.png').convert('RGBA')
  board=Image.new('RGB',(1024,304),(31,38,55));d=ImageDraw.Draw(board)
  for j,(name,strip) in enumerate([('CURRENT BEST v2',oldim),('ART-89 generation 3: NOT DELIVERED',newim)]):
   d.text((4,j*152+3),name,fill='white');board.paste(strip,(0,j*152+24),strip)
  save(ROOT/'rio_male-walk-1x.png',board)
dump(ROOT/'results.json',results)
print(json.dumps({'rows':len(results),'reviewed_frames':sum(r['frames'] for r in results),'delivered_rows':sum(r['deliver'] for r in results),'delivered_frames':sum(r['frames'] for r in results if r['deliver']),'candidates':[r['candidate'] for r in results if r['deliver']]},ensure_ascii=False))
