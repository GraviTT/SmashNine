"""Publish reviewed candidates and an explicit, unexecuted commit script. New assets only."""
import os,json,shutil,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
os.environ['PYTHONDONTWRITEBYTECODE']='1'
root=Path('reports/codex-skm-03')
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
stage=['design/tasks/CODEX-SKM-03.md']
lines=['# SKM-03 Frey 신규 기술 몸 동작 후보','',
 '내장 image_gen으로 행마다 6자세를 한 줄로 생성했다. 게임 폴더는 수정하지 않았으며, 후보 채택과 게임 연결은 별도다.',
 '', '## 행별 결과','',
 '| 행 | 상태 | 프레임/fps | 공통 배율 | 눈 거리 / 얼굴 폭 | 최소 여백 | 디테일 |',
 '|---|---|---|---:|---|---:|---|']
details=[]
for r in rows:
 row=r['row'];base=root/'frey'/row/f'attempt-{r["attempt"]}'
 metrics=json.loads((base/'metrics.json').read_text(encoding='utf-8'))
 face=json.loads((base/'face-proposed.json').read_text(encoding='utf-8'))
 head=json.loads((base/'head-scale.json').read_text(encoding='utf-8'))
 measured=[f for f in face['frames'] if f['frame'] in r['face_frames']]
 eye=[f['eye_ratio'] for f in measured];width=[f['face_width_ratio'] for f in measured]
 margin=min(f['margin']['minimum'] for f in metrics['frames'])
 detail=metrics['summary']['interior_detail_range']
 if r['accepted']:
  assert r['face_verified'] and r['costume_ok'] and r['pose_ok']
  assert all(.95<=v<=1.06 for v in eye+width),(row,eye,width)
  assert margin>=4 and min(detail)>=79 and not any(metrics['summary']['remaining_spill_pixels'])
  assert r['factor']==metrics['summary']['common_scale'] and 0<r['factor']<=1
  p=Path(f'art/bakeoff/frey/frey-{row}-v1.png');source=base/f'frey-{row}.png'
  if p.exists():assert p.read_bytes()==source.read_bytes(),'Never overwrite an existing candidate'
  else:shutil.copyfile(source,p)
  meta={'note':r['note'],'for':r['for'],'frames':6,'fps':r['fps'],'cell':192,'feet':[96,152],'loop':False,'factor':r['factor']}
  mp=p.with_suffix('.json');encoded=json.dumps(meta,ensure_ascii=False,indent=2)+'\n'
  if mp.exists():assert mp.read_text(encoding='utf-8')==encoded,'Never overwrite existing metadata'
  else:mp.write_text(encoded,encoding='utf-8')
  stage.extend([p.as_posix(),mp.as_posix()])
 checks={'selection':r,'metrics':metrics,'face':face,'head':head,'extraction':json.loads((base/'extraction.json').read_text(encoding='utf-8')),'sheet_sha256':hashlib.sha256((base/f'frey-{row}.png').read_bytes()).hexdigest()}
 cp=root/f'{row}-checks.json';cp.write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 shutil.copyfile(base/'face-landmarks-proposed.png',root/f'{row}-faces4x.png')
 if r['excluded_faces']:
  fb=Image.open(root/f'{row}-faces4x.png').convert('RGB');fd=ImageDraw.Draw(fb)
  for idx in r['excluded_faces']:
   x=int(idx)*256;fd.rectangle((x,0,x+255,319),fill=(31,38,55));fd.text((x+12,22),f'F{idx}: REAR VIEW / EXCLUDED',fill='white');fd.text((x+12,80),'No visible face to measure.',fill='white')
  fb.save(root/f'{row}-faces4x.png')
 stage.extend([(root/f'frey-{row}.png').as_posix(),cp.as_posix(),(root/f'{row}-faces4x.png').as_posix()])
 state='후보 전달' if r['accepted'] else '보류'
 lines.append(f'| [{row}](frey-{row}.png) | {state} | 6 / {r["fps"]} | {r["factor"]} | {min(eye):.3f}–{max(eye):.3f} / {min(width):.3f}–{max(width):.3f} | {margin}px | {detail[0]}–{detail[1]} |')
 details += [f'### {row}', '',r['note'],'',f'- 선정 원본: {r["attempt"]}차. 머리 자동 중앙값 {head["median"]} (신뢰 프레임 {head["used"]}개). 얼굴은 F'+', F'.join(map(str,r['face_frames']))+' 측정.', '- 사람 판단: '+r['human_review']]
 if r['excluded_faces']:details += ['- 얼굴 측정 제외: '+json.dumps(r['excluded_faces'],ensure_ascii=False)]
 if row=='wing_hover':
  bottoms=[f['bottom'] for f in metrics['frames']]
  details += [f'- 발끝 y: {bottoms}. F3은 F4보다 {bottoms[3]-bottoms[2]}px, F5는 F6보다 {bottoms[5]-bottoms[4]}px 높다. 공중 높이 변동 전체에 같은 lift_scale=0.25, lift_all=44를 적용했다(기본 상승 11px).', '- 4배 보드 마지막 단은 F6과 현재 dash_strike F3의 연결 비교다.']
 details += ['']
lines+=['']+details
if len(rows)<2:lines+=['## 현재 상태','','whirl_spin은 3차 원본의 얼굴·여백 검수 중이며 아직 전달하지 않았다.','']
lines+=['## 시도별 판단','',
 '- wing_hover: 1차는 공통 배율 조정 뒤에도 눈 비율 편차, 2차는 F1 얼굴 폭 0.829·F4 눈 거리 0.920이 남았다. 3차는 최종 공통 배율 0.382에서 전달 기준을 만족했다.',
 '- whirl_spin: 1차는 F1의 얼굴 각도·폭 비교가 불안정했다. 2차는 F3보다 F4에서 검이 더 뻗어 방출 자세가 늦었다. 3차는 동작을 개선했지만 얼굴 폭이 남았다. 배율 0.415에서는 최소 여백도 부족했으므로, 여백을 확보한 0.404의 검토 자료를 보존했다.',
 '', '## 검사 방법 및 제한','',
 '- ART-72 Python 도구를 art72_source/에 그대로 복사하고, process.py·face_check.py에 이 카드 경로와 행을 적용했다. process.py는 SKM-01의 연결 실루엣 추출을 재사용한다. art72_source/는 출처 보관용이며 직접 실행하지 않는다.',
 '- 원본의 큰 연결 실루엣 6개를 추출하고 작은 분리 픽셀은 가까운 몸에 배속했다. 원본 공통 y를 보존하며 고정 폭으로 자르지 않았다.',
 '- 행마다 배율 하나, 축소만 사용했다. LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. 머리·몸·무기를 따로 붙이거나 프레임별 배율을 바꾸지 않았다.',
 '- 최종 4배 보드와 얼굴 표식을 직접 확인했다. 얼굴 수치는 ART-72 국소 표식 매칭 값으로 계산 정밀도가 측정 정확도를 뜻하지 않는다. 원본/세부 시도는 로컬에 보존하고 커밋에서 제외한다.',
 '- 후보 전달 범위는 얼굴 두 지표 0.95–1.06이며 목표 0.96–1.04를 벗어난 값은 후보 note에 기록했다. 테두리 비움, 여백 4px, 번짐 0, 디테일 79 이상을 검사했다.',
 '- 게임 실행·모션 뷰어 채택·게임 연결은 하지 않았다. commit.ps1은 작성만 하며 실행하지 않는다.',
 '', '## 재현','',
 '지정 Python으로 PYTHONDONTWRITEBYTECODE=1을 설정하고 저장소 루트에서 실행한다. 패키지는 기존 후보와 바이트가 다르면 덮어쓰지 않고 중단한다.',
 '', '```text',
 'reports/codex-skm-03/process.py wing_hover 3 0.382 0 0.25 44',
 'reports/codex-skm-03/process.py whirl_spin 3 0.404',
 'reports/codex-skm-03/face_check.py frey wing_hover 3',
 'reports/codex-skm-03/face_check.py frey whirl_spin 3',
 'reports/codex-skm-03/board.py wing_hover 3',
 'reports/codex-skm-03/board.py whirl_spin 3',
 'reports/codex-skm-03/package.py',
 'reports/codex-skm-03/verify.py',
 '```', '', '## 원본과 프롬프트','',
 '두 행 각각 3회, 총 6회 생성. 원본은 art/raw/skm-03/, 전체 프롬프트는 [prompts.txt](prompts.txt). 모든 호출에 idle와 현재 move sheet를 참조로 전달했고, 2차 spin 및 3차 두 행은 이전 원본도 자세 참조로 전달했다.',
 '']
if (root/'audit.json').exists():
 audit=json.loads((root/'audit.json').read_text(encoding='utf-8'))
 if audit.get('passed'):
  lines+=['## 최종 파일 검증','',
   '[audit.json](audit.json): 후보 규격·메타데이터·정규화 결과 바이트 일치·알파·여백·번짐·디테일·얼굴 허용 범위·공중 보브·원본 보존·커밋 대상 범위를 검사했다. 보류 행의 얼굴 실패도 그대로 확인했다. commit.ps1은 PowerShell 파서 구문 검사만 했고 실행하지 않았다.',
   '', '검증 성공은 wing_hover 후보 파일의 전달 조건을 뜻하며 whirl_spin의 얼굴 실패를 통과로 바꾸지 않는다. 추적 중인 게임 파일 변경 없음. 원래 있던 미추적 Godot UID 파일들은 수정·추가 대상에서 제외했다.', '']
lines+=['## 남은 작업 / 다음 권장 단계','','사용자가 wing_hover를 모션 뷰어에서 판단한 뒤 리드가 채택·연결한다. whirl_spin은 얼굴 폭을 맞춘 후속 재작업이 필요하며 이번 생성 한도에서는 종료했다.','', '## 시각적 확인','']
for r in rows:
 lines += [f'![{r["row"]} 4배 검수](frey-{r["row"]}.png)', '', '각 단 왼쪽은 기준 idle, 오른쪽은 후보 두 프레임이다. 빨간 선은 발 기준 y=152다.', '']
(root/'README.md').write_text('\n'.join(lines),encoding='utf-8')
stage.extend(p.as_posix() for p in sorted(root.glob('*.py')))
stage.extend(p.as_posix() for p in sorted((root/'art72_source').glob('*.py')))
stage.extend((root/f).as_posix() for f in ['README.md','prompts.txt','selection.json','commit.ps1'])
for extra in ['generation-ledger.json','audit.json']:
 if (root/extra).exists():stage.append((root/extra).as_posix())
stage.append((root/'files-to-stage.json').as_posix())
stage=sorted(set(stage))
(root/'files-to-stage.json').write_text(json.dumps(stage,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
quoted='\n'.join("    '"+p.replace("'","''")+"'" for p in stage)
ps="""# Review only. Generated by package.py; never executed by Codex.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$files = @(
"""+quoted+"""
)
git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$message = @'
art: add reviewed Frey SKM-03 body motion candidates

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
"""
(root/'commit.ps1').write_text(ps,encoding='utf-8')
print('Published:',[r['row'] for r in rows if r['accepted']])
