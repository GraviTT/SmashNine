"""Package reviewed SKM-04 rows; new candidates only."""
import json,shutil,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
root=Path('reports/codex-skm-04')
rows=json.loads((root/'selection.json').read_text(encoding='utf-8-sig'))
stage=['design/tasks/CODEX-SKM-04.md']
lines=['# SKM-04 Luna 신규 기술 몸 동작 후보','','내장 image_gen으로 행마다 6자세를 한 줄로 생성했다. 게임 파일 수정·게임 실행·뷰어 채택은 하지 않았다.','','## 행별 결과','','| 행 | 상태 | fps | 배율 | 눈 거리 / 얼굴 폭 | 최소 여백 | 디테일 |','|---|---|---:|---:|---|---:|---|'];details=[]
for r in rows:
 row=r['row'];stem=r['stem'];base=root/stem/row/f'attempt-{r["attempt"]}'
 m=json.loads((base/'metrics.json').read_text());f=json.loads((base/'face-proposed.json').read_text());h=json.loads((base/'head-scale.json').read_text())
 measured=[v for v in f['frames'] if v['frame'] in r['face_frames']]
 eye=[v['eye_ratio'] for v in measured];width=[v['face_width_ratio'] for v in measured]
 margin=min(v['margin']['minimum'] for v in m['frames']);detail=m['summary']['interior_detail_range']
 if r['accepted']:
  assert r['face_verified'] and r['costume_ok'] and r['pose_ok']
  assert all(.95<=v<=1.06 for v in eye+width),(row,eye,width)
  assert margin>=4 and min(detail)>=79 and not any(m['summary']['remaining_spill_pixels'])
  assert 0<r['factor']<=1 and r['factor']==m['summary']['common_scale']
  p=Path(f'art/bakeoff/luna/{stem}-{row}-v1.png');src=base/f'{stem}-{row}.png'
  if p.exists():assert p.read_bytes()==src.read_bytes(),'Never overwrite existing candidate'
  else:shutil.copyfile(src,p)
  meta={k:r[k] for k in ['note','for','fps','loop','factor']};meta.update(frames=6,cell=192,feet=[96,152])
  mp=p.with_suffix('.json');encoded=json.dumps(meta,ensure_ascii=False,indent=2)+'\n'
  if mp.exists():assert mp.read_text(encoding='utf-8')==encoded,'Never overwrite existing metadata'
  else:mp.write_text(encoded,encoding='utf-8')
  stage.extend([p.as_posix(),mp.as_posix()])
 checks={'selection':r,'metrics':m,'face':f,'head':h,'extraction':json.loads((base/'extraction.json').read_text()),'sheet_sha256':hashlib.sha256((base/f'{stem}-{row}.png').read_bytes()).hexdigest()}
 cp=root/f'{row}-checks.json';cp.write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 shutil.copyfile(base/'face-landmarks-proposed.png',root/f'{row}-faces4x.png')
 if r['excluded_faces']:
  fb=Image.open(root/f'{row}-faces4x.png').convert('RGB');fd=ImageDraw.Draw(fb)
  for idx in r['excluded_faces']:
   x=int(idx)*256;fd.rectangle((x,0,x+255,319),fill=(31,38,55));fd.text((x+12,22),f'F{idx}: EXCLUDED',fill='white');fd.text((x+12,70),'Back/profile: no eye pair.',fill='white')
  fb.save(root/f'{row}-faces4x.png')
 stage.extend([(root/f'{stem}-{row}.png').as_posix(),cp.as_posix(),(root/f'{row}-faces4x.png').as_posix()])
 state='후보 전달' if r['accepted'] else '보류'
 lines.append(f'| [{row}]({stem}-{row}.png) | {state} | {r["fps"]} | {r["factor"]} | {min(eye):.3f}–{max(eye):.3f} / {min(width):.3f}–{max(width):.3f} | {margin}px | {detail[0]}–{detail[1]} |')
 details += [f'### {row}','',r['note'],'',f'- 선정 원본 {r["attempt"]}차. 자동 머리 중앙값 {h["median"]} (신뢰 {h["used"]}개). 얼굴 측정 F'+', F'.join(map(str,r['face_frames']))+'.','- 측정 제외: '+json.dumps(r['excluded_faces'],ensure_ascii=False),'- 시도 기록: '+r['attempt_notes'],'- 사람 판단: '+r['human_review'],'']
lines.insert(2,f'**후보 전달 {sum(bool(r["accepted"]) for r in rows)}/3행.** 행별 3회, 총 9회 생성 후 최선 원본을 검수했다. 보류 행은 art/bakeoff에 내보내지 않는다.')
lines+=['']+details
pending=[v for v in ['brave_cyclone','brave_grab','star_warp'] if v not in [r['row'] for r in rows]]
if pending:lines+=['## 현재 진행 중','','미전달·검수 대기: '+', '.join(pending)+'.','']
lines+=['## 검사 방법과 제한','','- SKM-03 Python 스크립트를 복사해 경로·행·앵커를 변경했다. 원본 6개 연결 실루엣과 가까운 분리 픽셀을 추출하며 고정 폭으로 자르지 않는다.','- LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. 행마다 하나의 축소 배율. 192px 셀, 몸 중심 x96, 발끝 y152. 신체 부위 붙이기·프레임별 배율 변경 없음.','- 얼굴 목표 0.96–1.04, 전달 허용 0.95–1.06. 목표 밖은 note에 공개. 여백 4px·spill 0·detail 79 이상을 검사한다.','- 얼굴은 ART-72의 4배 국소 표식 매칭으로 측정하고 직접 검토한다. 상반부 탐색으로 허벅지 오검출을 피한다. 회전 F5/F6은 측정용으로만 반전해 각도를 맞춘다. 보류 행의 숫자는 검증된 실측이 아닌 자동 제안일 수 있다.','- 뒷모습과 한 눈만 보이는 옆모습은 두 눈 거리 측정에서 제외한다. 계산 소수 자릿수는 측정 정확도를 의미하지 않는다.','- 원본 art/raw/skm-04/ 및 시도 폴더는 로컬 보존, 커밋 제외. 전체 생성 프롬프트: [prompts.txt](prompts.txt).','- commit.ps1은 작성만 하고 실행하지 않는다. 후보·검사 보드·기록·스크립트·카드만 명시적으로 추가한다.','','## 다음 권장 단계','','전달 후보를 사용자가 모션 뷰어에서 판단한 뒤 리드가 연결한다. 보류 행은 원인을 해소한 후속 제작이 필요하다.','','## 시각적 확인','']
for r in rows:lines += [f'![{r["row"]} 4배 검수]({r["stem"]}-{r["row"]}.png)','','각 단 왼쪽은 idle 기준, 오른쪽은 두 프레임. 빨간 선은 y152. 회전 보드 마지막 단은 F6→F1이다.','']
if (root/'audit.json').exists():
 audit=json.loads((root/'audit.json').read_text(encoding='utf-8'))
 if audit.get('passed'):
  lines += ['## 확인 및 테스트','',f'[audit.json](audit.json): 파일·규격·원본 보존·쓰기 범위·커밋 스크립트 구문 검사 {len(audit["checks"])}개 통과. 이는 보류 행의 얼굴·자세를 통과로 바꾸지 않는다.','', '모든 최선 원본의 18프레임을 4배로 직접 확인했다. 192px 셀·y152·이진 알파·4px 여백·spill 0·detail 79 이상은 통과했다. 게임 실행은 하지 않았으며 commit.ps1도 실행하지 않았다.','']
(root/'README.md').write_text('\n'.join(v.rstrip() for v in lines)+'\n',encoding='utf-8')
stage.extend(p.as_posix() for p in sorted(root.glob('*.py')))
stage.extend((root/p).as_posix() for p in ['README.md','prompts.txt','selection.json','commit.ps1','files-to-stage.json'])
for p in ['audit.json','generation-ledger.json']:
 if (root/p).exists():stage.append((root/p).as_posix())
stage=sorted(set(stage));(root/'files-to-stage.json').write_text(json.dumps(stage,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
ps=["# Prepared for lead review; never run by Codex.","$ErrorActionPreference = 'Stop'","$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path","Set-Location -LiteralPath $repo","$files = @("]
ps += ["    '"+p.replace("'","''")+"'" for p in stage]
title='art: add Luna SKM-04 body motion candidates and QA' if any(r['accepted'] for r in rows) else 'art: record Luna SKM-04 body motion review and held rows'
ps += [')','git add -- @files',"if ($LASTEXITCODE -ne 0) { throw 'git add failed' }","$message = @'",title,'','Co-Authored-By: Codex <noreply@openai.com>',"'@",'git commit -m $message',"if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
(root/'commit.ps1').write_text('\n'.join(ps)+'\n',encoding='utf-8')
print('Published:',[r['row'] for r in rows if r['accepted']]);print('Held:',[r['row'] for r in rows if not r['accepted']])
