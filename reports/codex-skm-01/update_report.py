"""Checkpoint each reviewed row. Explicitly enumerate commit paths; never run git."""
import json,shutil
from pathlib import Path
root=Path('reports/codex-skm-01');state=json.loads((root/'state.json').read_text(encoding='utf-8'))
rows={'hover_dash':(14,'K: 공중 정지 후 돌진'),'launch_chase':(15,'L: 띄운 뒤 추격 추가타'),'shield_bash':(14,'J 세 번째 타격: 방패 밀치기'),'sword_plant':(13,'아래 J: 검 꽂기, 전방 충격파 준비'),'air_hover_swing':(16,'공중 J: 공중 정지 후 크게 베기')}
lines=['# SKM-01 Frey 기술 확장 동작 후보','', '내장 image_gen으로 행당 최대 2회 생성. 후보만 제작하며 게임 폴더는 변경하지 않았다.','', '| 행 | 상태 | 배율 | 얼굴 눈/폭 비율 | 최소 여백 | 디테일 |', '|---|---|---:|---|---:|---:|']
details=[];delivered=[]
for row,(fps,purpose) in rows.items():
 s=state.get(row)
 if not s:lines.append(f'| {row} | 미도달 | — | — | — | — |');continue
 out=root/'frey'/row/f'attempt-{s["attempt"]}'
 metrics=json.loads((out/'metrics.json').read_text(encoding='utf-8')) if (out/'metrics.json').exists() else None
 face=json.loads((out/'face-proposed.json').read_text(encoding='utf-8')) if (out/'face-proposed.json').exists() else None
 factor=metrics['summary']['common_scale'] if metrics else '—'
 fr=[f for f in face['frames'] if f['frame'] not in s.get('excluded_face_frames',[])] if face else []
 ratios=' / '.join(f'{min(f[k] for f in fr):.3f}–{max(f[k] for f in fr):.3f}' for k in ['eye_ratio','face_width_ratio']) if fr else '미측정'
 if metrics:
  fs=metrics['frames'];margin=min(f['margin']['minimum'] for f in fs);detail=f"{min(f['interior_detail'] for f in fs):.2f}–{max(f['interior_detail'] for f in fs):.2f}"
 else:margin=detail='—'
 status='후보 전달' if s['pass'] else '미전달'
 lines.append(f'| [{row}](frey-{row}.png) | {status} | {factor} | {ratios} | {margin}px | {detail} |')
 if (out/'review4x.png').exists():shutil.copyfile(out/'review4x.png',root/f'frey-{row}.png')
 details.append(f"- **{row} ({status}, {s['attempt']}차):** {s['reason']}")
 if s['pass']:
  assert fr and all(.96<=f['eye_ratio']<=1.04 and .96<=f['face_width_ratio']<=1.04 for f in fr),'face gate'
  assert margin>=4 and all(f['remaining_spill_pixels']==0 and f['interior_detail']>=79 for f in fs)
  path=Path(f'art/bakeoff/frey/frey-{row}-v1.png')
  src=out/f'frey-{row}.png'
  if path.exists():assert path.read_bytes()==src.read_bytes(),'never overwrite candidate'
  else:shutil.copyfile(src,path)
  meta={'note':s['reason'],'for':purpose,'frames':6,'fps':fps,'cell':192,'feet':[96,152],'loop':False,'factor':factor,'hold_last':row in ['hover_dash','launch_chase','air_hover_swing']}
  jp=path.with_suffix('.json')
  if not jp.exists():jp.write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
  delivered.extend([path,jp])
lines+=['','## 검수 결과',*details,'','## 측정 방법과 제한','- 각 자세의 연결된 그림 덩어리를 따로 추출했다. 고정 너비 칸으로 자르지 않았으며 원본의 공통 세로 좌표를 보존했다.','- 행당 배율 하나, 축소만 사용. LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. 몸·머리·무기를 따로 붙이거나 프레임별 크기를 변경하지 않았다.','- head_scale.py와 ART-72 얼굴 표식 검사, 기준과 나란한 4배 판으로 확인. 얼굴 자동 표식은 제안값이며 육안과 일치하지 않으면 통과 근거로 쓰지 않는다.','- 후보 전달 기준은 이 카드의 엄격한 얼굴 0.96–1.04를 적용했다. ART-77의 완화 구간을 자동으로 적용하지 않았다.','- 게임 실행이나 모션 뷰어 채택은 수행하지 않았다.','', '## 사람이 판단할 것','동작의 정지감·가속감, 추가타 구분, 방패의 무게감, 의상 일치와 얼굴 크기를 검토해야 한다. 미전달 행은 실패 근거를 보존한 검토 자료이며 채택 후보가 아니다.','','## 남은 작업', ' / '.join(r for r in rows if r not in state) or '미도달 행 없음. 미전달 행의 재작업은 별도 후속 작업이다.','','commit.ps1은 작성만 하며 실행하지 않는다. 원본은 art/raw/skm-01/에 보존하고 커밋 대상에서 제외한다.']
lines+=['','## 파일 검증','verify_skm.py로 최종 PNG 규격·알파·여백·번짐·디테일·배율·추출 기록·전달 상태·커밋 대상 범위를 확인했다. 세부 결과는 [audit.json](audit.json). 이 파일 검사의 통과는 그림의 채택이나 얼굴 기준 통과를 뜻하지 않는다.','PowerShell 파서로 commit.ps1의 구문을 확인했으며 실행하지 않았다. 생성은 총 10회(행당 2회)다.']
(root/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
# Include review artifacts, relevant adapted helpers, and required card only.
helpers={'process_row.py','face_check.py','update_report.py','verify_skm.py','qa_pages.py','state.json','README.md','prompts.txt','audit.json'}
paths=[Path('design/tasks/CODEX-SKM-01.md'),*delivered]
for p in root.rglob('*'):
 if not p.is_file() or p.name in {'run.log','commit.ps1'} or '__pycache__' in p.parts:continue
 if 'source-frames' in p.parts:continue
 if p.parent==root and p.suffix=='.py' and p.name not in helpers:continue
 paths.append(p)
paths.append(root/'commit.ps1');paths=sorted(set(p.as_posix() for p in paths))
ps=["$ErrorActionPreference = 'Stop'", "$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))",'Set-Location -LiteralPath $repo', '$paths = @(']+["    '"+p+"'" for p in paths]+[')', 'git add -- $paths', "if ($LASTEXITCODE -ne 0) { throw 'git add failed' }", "git commit --only -m 'Add reviewed Frey skill-motion candidate results (SKM-01)' -m 'Co-Authored-By: Codex <noreply@openai.com>' -- $paths", "if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
(root/'commit.ps1').write_text('\n'.join(ps)+'\n',encoding='utf-8-sig')
print('Checkpoint:',len(delivered)//2,'delivered;',len(state),'reviewed')
