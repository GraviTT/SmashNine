"""Finalize Korean handoff and independently verify delivered files. Exclusive writes only."""
import os,sys,json,datetime,hashlib,subprocess
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
R=Path('reports/codex-art-92');RAW=Path('art/raw/motions-92')
forms=['frey','luna','luna_brave','nova_male','nova_female','rio_male','rio_female','yuki']
motions=['dodge_roll','taunt','stun','crouch','run_start']
rows=[json.loads(p.read_text(encoding='utf-8')) for p in R.glob('*-result.json')]
rows.sort(key=lambda r:(motions.index(r['row']),forms.index(r['stem'])))
passed=[r for r in rows if r['status']=='pass'];failed=[r for r in rows if r['status']=='fail']
def write(p,b):
 with p.open('xb') as f:f.write(b if isinstance(b,bytes) else b.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
ledger=[]
for p in sorted(RAW.glob('*-generation.json')):
 stem,motion,num=p.stem.removesuffix('-generation').rsplit('-',2)
 data=json.loads(p.read_text(encoding='utf-8'));raw=RAW/f'{stem}-{motion}-{num}.png'
 assert any(r['stem']==stem and r['row']==motion for r in rows),f'Unresolved {stem}-{motion}'
 assert raw.exists()
 folder='luna' if stem.startswith('luna') else 'nova' if stem.startswith('nova') else 'rio' if stem.startswith('rio') else stem
 refver=({'frey':3,'yuki':2}.get(stem,1) if motion=='dodge_roll' else {'frey':1,'luna':3,'luna_brave':2}[stem])
 refs=[(RAW/f'{stem}-anchor.png').as_posix(),f'art/bakeoff/{folder}/{stem}-{"tumble" if motion=="dodge_roll" else "victory"}-v{refver}.png']
 ledger.append({'stem':stem,'row':motion,'generation':int(num),'raw':raw.as_posix(),'sha256':sha(raw),'references':refs,'prompt':data['prompt'],'generator':'built-in image_gen'})
dump(R/'generation-ledger.json',ledger)
write(R/'prompts.txt','\n\n'.join(f"{g['stem']} {g['row']} generation {g['generation']}\nReferences: {g['references']}\n{g['prompt']}" for g in ledger)+'\n')
evidence=[]
for r in failed:
 root=RAW/f"{r['stem']}-{r['row']}"
 attempts=[]
 for m in sorted(root.glob('*/metrics.json')):
  d=json.loads(m.read_text(encoding='utf-8'));face=m.parent/'face-proposed.json'
  attempts.append({'path':m.parent.as_posix(),'normalization':d['summary'],'frames':d['frames'],'face':json.loads(face.read_text(encoding='utf-8')) if face.exists() else None})
 evidence.append({'stem':r['stem'],'row':r['row'],'reason':r['reason'],'measurements':attempts})
dump(R/'failed-checks.json',evidence)
checks=[]
def check(name,ok,detail=None):checks.append({'check':name,'pass':bool(ok),'detail':detail})
check('branch',subprocess.check_output(['git','branch','--show-current'],text=True).strip()=='codex/art-92')
check('tracked diff empty',not subprocess.check_output(['git','diff','--name-only'],text=True).strip())
check('staged diff empty',not subprocess.check_output(['git','diff','--cached','--name-only'],text=True).strip())
for r in rows:
 gs=[g for g in ledger if g['stem']==r['stem'] and g['row']==r['row']]
 check(f"{r['stem']} {r['row']} generation limit",1<=len(gs)<=2,len(gs))
 if r['status']!='pass':
  folder='luna' if r['stem'].startswith('luna') else 'nova' if r['stem'].startswith('nova') else 'rio' if r['stem'].startswith('rio') else r['stem']
  check('failed candidate absent '+r['stem']+' '+r['row'],not Path(f"art/bakeoff/{folder}/{r['stem']}-{r['row']}-v1.png").exists());continue
 p=Path(r['candidate']);im=Image.open(p).convert('RGBA');meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'));c=meta['cell']
 check(str(p)+' dimensions',im.size==(6*c,c));check(str(p)+' metadata',meta['frames']==6 and meta['new_row'] and meta['feet']==c//2+56)
 hashes=[]
 for j in range(6):
  f=im.crop((j*c,0,(j+1)*c,c));a=np.array(f);y,x=np.where(a[...,3]>0);margin=int(min(x.min(),y.min(),c-1-x.max(),c-1-y.max()));detail=n.interior_detail(f);spill=n.spill_pixel_count(f)
  check(f'{p} F{j+1} pixels',margin>=4 and detail>=79 and spill==0 and int(y.max())==meta['feet'] and set(np.unique(a[...,3]))<={0,255},{'margin':margin,'detail':detail,'spill':spill,'bottom':int(y.max())})
  hashes.append(hashlib.sha256(f.tobytes()).hexdigest())
  fm=meta['face_ratios'][j];check(f'{p} F{j+1} face gate',all(v is None or .96<=v<=1.04 for v in [fm['eye_ratio'],fm['face_width_ratio']]),{'eye':fm['eye_ratio'],'width':fm['face_width_ratio'],'reason':fm['reason']})
 check(str(p)+' distinct',len(set(hashes))==6)
 e=json.loads((R/f"{r['stem']}-{r['row']}-checks.json").read_text(encoding='utf-8'));check(str(p)+' anchor preserved',sha(e['variant']['anchor'])==e['anchor_sha256'])
check('all automated delivery checks',all(c['pass'] for c in checks))
now=datetime.datetime.now().astimezone().isoformat(timespec='seconds')
lines=['# CODEX-ART-92 결과',f'\n작성: {now}. 브랜치 `codex/art-92`.',f'\n**완료:** {len(rows)}행을 시도하여 **{len(passed)}행 / {len(passed)*6}프레임**을 납품했다. 내장 ImageGen {len(ledger)}회. 통과 즉시 PNG/JSON·4배 비교판·progress.md·commit-paths.txt에 행별 반영했다. 후보이며 게임에는 연결하지 않았다.','\n## 납품한 행','\n폼 | 행 | 파일 | 프레임 | 검사','---|---|---|---|---']
for r in passed:
 es=[f['eye_ratio'] for f in r['face_ratios'] if f['eye_ratio'] is not None];ws=[f['face_width_ratio'] for f in r['face_ratios'] if f['face_width_ratio'] is not None]
 desc=f"W {min(ws):.3f}–{max(ws):.3f}; E "+(f'{min(es):.3f}–{max(es):.3f}' if es else '측정 불가')+f"; 여백≥{min(x['margin'] for x in r['checks'])}; detail≥{min(x['detail'] for x in r['checks']):.2f}; spill 0"
 lines.append(f"{r['stem']} | {r['row']} | [PNG](../../{r['candidate']}) / [4배 판]({r['stem']}-{r['row']}.png) | 6 | {desc}")
lines+=['\n## 미납품한 행','\n폼 | 행 | 이유','---|---|---']
for r in failed:lines.append(f"{r['stem']} | {r['row']} | {r['reason']}")
lines+=['\n## 측정과 육안 판단의 구분','\n측정 사실: 고정 셀 가로 6칸, 이진 알파, 최소 4px 여백, spill 0, detail≥79, 전 프레임 서로 다른 픽셀, 접촉선 y=120(구르기)/152(도발)를 검사했다. 얼굴은 ART-89의 4배 대응점 방식으로 눈 간격 E와 눈 아래 노출 얼굴 폭 W를 idle 대비 측정했다. 보이는 얼굴의 유효 측정값은 0.96–1.04만 통과시켰다.','\n회전·등짐·가림·감은 눈은 사유와 null을 기록했다. Nova/Rio는 idle부터 먼 눈이 머리카락에 가려 E를 판정에서 제외하고 W로 비교했다. 자동 대응점과 머리 템플릿은 제안이며, 팔/다리를 잡는 경우 실제 얼굴 ROI로 재측정했다. 제외값을 정상 수치로 치환하지 않았다. 소수점 표시는 측정 정확도 보증이 아니다.','\n육안 판단: 원래 의상·소품·손 연결·동작 단계와 바닥 접촉을 정적 4배 판에서 검토했다. 픽셀 최저 위치만으로 부츠 접지를 단정하지 않았다. 구르기 중간에는 어깨/등/머리·망토가 바닥에 닿는다. 실제 애니메이션 재생과 게임 내 체감은 검증하지 않았다. 각 후보 JSON note에 약점을 남겼다.','\n## 처리 방법','\n매 생성마다 idle 앵커와 같은 폼의 tumble 또는 victory를 참조하고 전체 6프레임을 한 이미지로 생성했다. LANCZOS + unsharp 60 + despill auto + palette none, 행 전체 공통 배율만 사용했다. 프레임별 크기 변경·부위 그리기·머리 붙이기·프레임 혼합은 하지 않았다. 도발의 일부는 ART-89 victory와 같은 3×2 원본 배치로 생성했고, 출력은 6×1 고정 셀 스트립이다. 원본에서 경계를 넘은 시도는 재생성하거나 탈락시켰다.','\n이전 스크립트를 보고서 경로로 복사한 뒤 어댑터로 호출했다. 기존 product/tools/자산 파일은 수정하지 않았다. 중간 시도와 실패 원본은 git-ignored `art/raw/motions-92/`에 보존했다. 결과·중간 파일은 배타적 생성, progress/manifest는 카드 지시에 따라 append했다. Windows UTF-8 읽기 오류와 CLI JSON 인용 오류는 출력 생성 전 중단됐고, UTF-8 환경과 올바른 인용으로 다시 실행했다.','\n## 시각적 확인']
if passed:lines += [f"\n![납품 후보의 idle과 6프레임 비교]({passed[0]['stem']}-{passed[0]['row']}.png)",'\n왼쪽은 원래 idle, 오른쪽 여섯 칸은 실제 납품 후보의 최근접 4배 픽셀이다. 다른 행 비교판은 위 표에서 열 수 있다.']
lines+=['\n## 현재 상태·남은 작업','\n자동 검증 결과는 [audit.json](audit.json), 원본 프롬프트와 참조 순서는 [generation-ledger.json](generation-ledger.json), 실패 측정은 [failed-checks.json](failed-checks.json)에 있다. `commit.ps1`은 명시된 목록만 `git add --pathspec-from-file`로 스테이징하도록 준비했으며 실행하지 않았다. `git add`, commit, Godot, 설치, 다운로드, 배포를 하지 않았다.','\n미착수 항목:']
for motion in motions:
 remaining=[s for s in forms if not any(r['stem']==s and r['row']==motion for r in rows)]
 if remaining:lines.append(f"- `{motion}`: {', '.join(remaining)}"+(' (앞선 4동작 완료 후의 선택 작업)' if motion=='run_start' else ''))
lines+=['\n다음 권장 단계: 리드가 납품 후보를 모션 뷰어에서 재생해 검/손 연결과 타이밍을 확인하고 사용자 채택을 받는다. 미납품·미착수 행은 별도 후속 카드로 진행한다. 후속 작업은 예약하지 않았다.']
write(R/'README.md','\n'.join(lines)+'\n')
extras=['generation-ledger.json','prompts.txt','failed-checks.json','audit.json','finish92.py','setup92.py','process92.py','process_fast92.py','process_grid92.py','face92.py','face_roi92.py','copy_review92.py','deliver92.py','record92.py','art89_face_check.py','art89_face_check_75.py','art89_face_check_77.py']
with (R/'commit-paths.txt').open('a',encoding='utf-8') as f:f.write(''.join('reports/codex-art-92/'+p+'\n' for p in extras))
paths=(R/'commit-paths.txt').read_text(encoding='utf-8').splitlines()
check('manifest unique',len(paths)==len(set(paths)))
for p in paths:
 allowed=p.startswith('reports/codex-art-92/') or p in ['design/tasks/CODEX-ART-92.md','design/tasks/CODEX-ART-92.prompt.md'] or any(p==r['candidate'] or p==str(Path(r['candidate']).with_suffix('.json')).replace('\\','/') for r in passed)
 check('manifest '+p,allowed and not any(x in p for x in ['art/raw/','__pycache__','run.log','/attempt']) and (Path(p).is_file() or p=='reports/codex-art-92/audit.json'))
ignored=subprocess.run(['git','check-ignore','--stdin'],input='\n'.join(paths)+'\n',capture_output=True,text=True)
check('manifest not ignored',ignored.returncode==1 and not ignored.stdout,ignored.stdout)
audit={'time':now,'status':'pass' if all(c['pass'] for c in checks) else 'fail','delivered_rows':len(passed),'failed_rows':len(failed),'generations':len(ledger),'checks':checks,'limitations':['정적 그림 검토; 실제 재생/Godot 미실행','얼굴 제외 사유는 후보 JSON 및 checks에 명시']}
dump(R/'audit.json',audit)
print(json.dumps({k:audit[k] for k in ['time','status','delivered_rows','failed_rows','generations']},ensure_ascii=False))
print(json.dumps([c for c in checks if not c['pass']],ensure_ascii=False))
