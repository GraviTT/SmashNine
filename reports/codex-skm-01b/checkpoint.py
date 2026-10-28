"""Reuse SKM-01 checkpoints with SKM-01b gate and explicit lean commit paths."""
import json, shutil
from pathlib import Path
root=Path('reports/codex-skm-01b')
state=json.loads((root/'state.json').read_text(encoding='utf-8'))
rows={'hover_dash':(14,'K: 공중 정지 후 돌진'),'launch_chase':(15,'L: 띄운 뒤 추격 추가타')}
lines=['# SKM-01b Frey 재시도','', '내장 image_gen으로 각 행 한 번 생성. 기준 idle을 참조로 전달했다. 게임 미연결 후보 작업이다.','', '| 행 | 상태 | 공통 배율 | 얼굴 눈 / 폭 | 최소 여백 | 디테일 |','|---|---|---:|---|---:|---:|']
paths=['design/tasks/CODEX-SKM-01b.md','reports/codex-skm-01b/README.md']
details=[]
for row,(fps,purpose) in rows.items():
 s=state.get(row)
 if not s:
  lines.append(f'| {row} | 미도달 | — | — | — | — |')
  continue
 out=root/'frey'/row/'attempt-1'
 m=json.loads((out/'metrics.json').read_text())
 f=json.loads((out/'face-proposed.json').read_text())
 fs=m['frames'];face=f['frames'];factor=m['summary']['common_scale']
 ratios=' / '.join(f'{min(v[k] for v in face):.3f}–{max(v[k] for v in face):.3f}' for k in ['eye_ratio','face_width_ratio'])
 margin=min(v['margin']['minimum'] for v in fs)
 detail=f"{min(v['interior_detail'] for v in fs):.2f}–{max(v['interior_detail'] for v in fs):.2f}"
 board=root/f'frey-{row}.png';shutil.copyfile(out/'review4x.png',board);paths.append(board.as_posix())
 status='후보 전달' if s['pass'] else '미전달'
 lines.append(f'| [{row}](frey-{row}.png) | {status} | {factor} | {ratios} | {margin}px | {detail} |')
 details.append(f"- **{row}:** {s['reason']}")
 if s['pass']:
  assert all(.95<=v[k]<=1.06 for v in face for k in ['eye_ratio','face_width_ratio'])
  assert margin>=4 and all(v['remaining_spill_pixels']==0 and v['interior_detail']>=79 and v['border_clear'] and v['alpha_binary'] for v in fs)
  dst=Path(f'art/bakeoff/frey/frey-{row}-v1.png')
  source=out/f'frey-{row}.png'
  if dst.exists():assert dst.read_bytes()==source.read_bytes()
  else:
   with dst.open('xb') as w:w.write(source.read_bytes())
  note=s['reason']+f' 얼굴 눈/폭 비율 {ratios}. 게임 미연결 후보.'
  meta={'note':note,'for':purpose,'frames':6,'fps':fps,'cell':192,'feet':[96,152],'loop':False,'factor':factor,'hold_last':True}
  jp=dst.with_suffix('.json')
  if not jp.exists():jp.write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
  paths.extend([dst.as_posix(),jp.as_posix()])
lines+=['','## 검수 및 남은 문제',*details,'','## 방법과 검증','- 기존 SKM-01 process_row.py·face_check.py를 경로만 바꿔 재사용. 연결된 자세 덩어리별 추출, 원본 공통 y 좌표 보존. 고정 폭 절단 없음.','- 행 공통 배율 하나. LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. 프레임별 크기 조절과 부분 붙이기 없음.','- 얼굴 수치는 4배 최근접 확대의 눈 중심 거리 / 눈높이 얼굴 폭(머리카락 제외). 자동 표식과 4배 판을 육안 확인. head_scale.py는 보조 검사.','- 전달 범위는 두 얼굴 지표 모두 0.95–1.06. 0.96–1.04 밖의 수치는 후보 note에 명시.','- PNG 규격·이진 알파·빈 테두리·4px 여백·spill 0·detail 79 이상을 검사. 실제 게임과 모션 뷰어 실행 검증은 하지 않았다.','- 원본과 프롬프트는 art/raw/skm-01b/ 및 prompts.txt. 측정 상세와 비교판은 frey/<행>/attempt-1/. 자동 소수 자릿수는 실제 측정 정확도를 뜻하지 않는다.','','## 다음 권장 단계','전달 후보가 있으면 모션 뷰어에서 정지감·돌진 연결·추가타를 확인한다. 미전달 행은 아래 실패 원인을 고친 새 생성이 필요하다.','','commit.ps1은 작성만 했고 실행하지 않았다. 지정한 후보 PNG/JSON, 비교판, README, 작업 카드만 포함한다. attempt 폴더·원본·보조 스크립트는 커밋 목록에서 제외한다.']
(root/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
ps=["$ErrorActionPreference = 'Stop'","$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))",'Set-Location -LiteralPath $repo','$paths = @(']+["    '"+p+"'" for p in paths]+[')','git add -- $paths',"if ($LASTEXITCODE -ne 0) { throw 'git add failed' }","git commit --only -m 'Add Frey hover dash and launch chase review (SKM-01b)' -m 'Co-Authored-By: Codex <noreply@openai.com>' -- $paths","if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
(root/'commit.ps1').write_text('\n'.join(ps)+'\n',encoding='utf-8-sig')
print('\n'.join(lines[:10]))

