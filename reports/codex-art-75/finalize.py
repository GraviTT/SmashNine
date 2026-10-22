"""Curate ART-75 measurements and best attempts; publish new candidates only on --publish."""
import sys,json,shutil,hashlib,re,subprocess
from pathlib import Path
from PIL import Image,ImageDraw
root=Path('reports/codex-art-75');selection=json.loads((root/'selection.json').read_text(encoding='utf-8'))
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6};fps={'jump':10,'fall':8,'hurt':12,'land':12,'victory':8}
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
descriptions={
 'jump':'도약 직후→무릎을 접는 상승→다리를 푸는 정점. F2와 F3의 팔다리 자세를 구분했다.',
 'fall':'다리를 아래로 뻗고 머리카락·옷자락이 조금 흔들리는 낙하 반복.',
 'hurt':'머리·어깨가 뒤로 밀리는 타격 순간→무릎을 굽히는 반동→대기 자세로 복귀.',
 'land':'양발 착지 웅크림→대기 자세 쪽으로 일어남.',
 'victory':'어깨를 풀고 열린 반대 손바닥에 주먹을 친 뒤, 주먹을 앞으로 내밀고 웃는 승리 자세.'}
summary=[]
for item in selection:
 stem,row,at=item['stem'],item['row'],item['attempt'];count=counts[row];base=root/stem/row/f'attempt-{at}';best=root/'best'/stem/row;best.mkdir(parents=True,exist_ok=True)
 for name in [f'{stem}-{row}.png','metrics.json','head-scale.json','face-proposed.json','faces4x.png','review4x.png']:
  if (base/name).exists():shutil.copy2(base/name,best/name)
 m=json.loads((base/'metrics.json').read_text());s=m['summary'];proposed=json.loads((base/'face-proposed.json').read_text());head=json.loads((base/'head-scale.json').read_text());face=[];excluded=[]
 for f0 in proposed['frames']:
  f=dict(f0);i=f['frame']
  if i in item['excluded_face_frames']:
   excluded.append({'frame':i,'reason':'피격으로 얼굴이 뒤로 기울고 시선이 위로 향한다. 바로 선 얼굴과의 눈/가로 폭 정합은 유효하지 않아 수치 판정에서 제외. 머리·얼굴·의상은 정확한 4배 판에서 육안 비교.'});continue
  if str(i) in item['manual_width']:
   corr=item['manual_width'][str(i)];f['proposed_face_width_ratio']=f['face_width_ratio'];f['face_width_ratio']=corr['face_width_ratio'];f['face_width']=corr['right'][0]-corr['left'][0];f['landmarks']=[f['landmarks'][0],f['landmarks'][1],{'x':corr['left'][0],'y':corr['left'][1],'score':None},{'x':corr['right'][0],'y':corr['right'][1],'score':None}];f['manual_correction']=corr['reason']
  if stem.startswith('nova'):f['eye_distance']=None;f['eye_ratio']=None
  face.append(f)
 measured={'method':'ART-72의 4배 최근접 얼굴 표식. 제안 표식과 직접 검수한 유효 표식을 분리. 얼굴이 바로 선 프레임만 수치 판정하며 기울어진 피격은 육안 비교.','reference_face_width':proposed['reference_face_width'],'reference_eye_distance':None if stem.startswith('nova') else proposed['reference_eye_distance'],'eye_limitation':'Nova 앵커의 반대쪽 눈은 앞머리에 가려져 눈 사이 거리를 정의할 수 없음.' if stem.startswith('nova') else None,'frames':face,'excluded_frames':excluded}
 write(best/'face-measured.json',measured)
 shutil.copy2(base/'review4x.png',root/f'{stem}-{row}.png')
 sheet=Image.open(base/f'{stem}-{row}.png').convert('RGBA');cell=sheet.height;feet=cell//2+56;folder='yuki' if stem=='yuki' else 'nova';a=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
 # Face-only audit overlay: show only valid face-width points; no fictional far-eye on Nova.
 b=Image.new('RGB',(256*(count+1),280),(31,38,55));d=ImageDraw.Draw(b)
 for i,fr in enumerate([a]+[sheet.crop((j*cell,0,(j+1)*cell,cell)) for j in range(count)]):
  marks=proposed['anchor_landmarks'] if i==0 else next((f['landmarks'] for f in face if f['frame']==i),proposed['frames'][i-1]['landmarks'])
  cx=sum(p['x'] for p in marks)/4;cy=sum(p['y'] for p in marks)/4;ox,oy=round(cx)-24,round(cy)-24;cr=fr.crop((ox,oy,ox+48,oy+48)).resize((192,192),Image.Resampling.NEAREST);x=i*256+32;b.paste(cr,(x,40),cr)
  valid=i==0 or any(f['frame']==i for f in face)
  if valid:
   for j,p in enumerate(marks):
    if stem.startswith('nova') and j<2:continue
    px=x+(p['x']-ox)*4;py=40+(p['y']-oy)*4;col='cyan' if j<2 else 'yellow';d.line((px-4,py,px+4,py),fill=col);d.line((px,py-4,px,py+4),fill=col)
  d.text((i*256+4,6),'ANCHOR' if i==0 else (f'F{i}: measured' if valid else f'F{i}: tilted, visual only'),fill='white')
 b.save(best/'face-measured-4x.png')
 minmargin=min(f['margin']['minimum'] for f in m['frames']);detail=s['interior_detail_range'];values=[v for f in face for v in [f['eye_ratio'],f['face_width_ratio']] if v is not None];valid_range=all(.95<=v<=1.06 for v in values)
 version=3 if stem=='nova_female' and row=='hurt' else (2 if row in ['jump','fall','hurt'] else 1);dest=Path(f'art/bakeoff/{folder}/{stem}-{row}-v{version}.png')
 note=descriptions[row]
 if stem=='yuki' and row=='victory':note='부적 손을 유지하며 손목을 올린 뒤 반대 손의 부채를 한 번 펴서 턱 앞에서 유지한다.'
 if stem=='nova_female' and row=='victory':note='잽 두 번→주먹 올리기→준비 자세와 윙크. 최선 2차에도 두 잽이 같은 팔이라 미전달.'
 if row=='hurt':note+=' F1·2의 기울어진 얼굴은 수치 판정에서 제외하고 머리 크기를 4배 육안 비교했다. 바로 선 F3만 얼굴 수치를 측정했다.'
 if stem.startswith('nova'):note+=' 앵커의 반대 눈이 가려져 눈 간격은 측정 불가이며 얼굴 폭을 비교했다.'
 if item['manual_width']:note+=' F4 얼굴 오른쪽 표식이 코 옆에 잡혀 실제 눈 아래 얼굴 경계로 직접 교정했다(폭 비율 0.966).'
 if item['accepted']:
  assert valid_range and s['borders_clear'] and s['all_have_4px_margin'] and min(detail)>=79 and not any(s['remaining_spill_pixels'])
  if any(not(.96<=v<=1.04) for v in values):note+=' 측정 비율 '+str(values)+'로 목표 0.96–1.04 밖의 값이 있으나 후보 허용 0.95–1.06 이내다.'
  if '--publish' in sys.argv:
   assert not dest.exists() and not dest.with_suffix('.json').exists(),f'Never overwrite {dest}'
   shutil.copy2(base/f'{stem}-{row}.png',dest);write(dest.with_suffix('.json'),{'note':note,'frames':count,'fps':fps[row],'cell':cell,'feet':feet,'factor':s['common_scale']})
 record={'stem':stem,'row':row,'attempt':at,'frames':count,'fps':fps[row],'cell':cell,'feet':feet,'factor':s['common_scale'],'lift':s['lift_range'],'margin':minmargin,'detail':detail,'head':head,'face':measured,'accepted':item['accepted'],'candidate':str(dest).replace('\\','/') if item['accepted'] else None,'sheet_sha256':sha(base/f'{stem}-{row}.png'),'pose_ok':item['pose_ok'],'costume_ok':item['costume_ok'],'note':note,'face_valid_range':valid_range}
 summary.append(record);write(best/'manual-review.json',item)
write(root/'summary.json',summary)
ledger=[];prompts=[]
for p in sorted(root.glob('*.txt')):
 match=re.fullmatch(r'(yuki|nova_male|nova_female)-(jump|fall|hurt|land|victory)-([123])(?:-f(\d+))?',p.stem)
 if not match:continue
 stem,row,at,frame=match.groups();raw=Path('art/raw/motions-75')/(p.stem+'.png');assert raw.exists(),raw
 ledger.append({'key':p.stem,'stem':stem,'row':row,'attempt':int(at),'replacement_frame':int(frame) if frame else None,'prompt':str(p).replace('\\','/'),'prompt_sha256':sha(p),'raw':str(raw).replace('\\','/'),'raw_sha256':sha(raw),'tool':'built-in image_gen','anchor':f'art/raw/motions-75/{stem}-anchor-4x.png'})
 prompts.append(p.stem+'\n'+p.read_text(encoding='utf-8').strip())
write(root/'generation-ledger.json',ledger);(root/'prompts.txt').write_text('ART-75 — 내장 ImageGen 실제 호출 프롬프트\n\n'+'\n\n'.join(prompts)+'\n',encoding='utf-8')
print(json.dumps({'rows':len(summary),'delivered':sum(r['accepted'] for r in summary),'frames':sum(r['frames'] for r in summary if r['accepted']),'generations':len(ledger),'published':'--publish' in sys.argv},ensure_ascii=False))
