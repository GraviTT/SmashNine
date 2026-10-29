"""Refresh a complete, explicit handoff after each row; never execute git."""
import json
from pathlib import Path
root=Path('reports/codex-skm-02')
rows=[('rio_male','dimension_link'),('rio_male','pogo_bounce'),('nova_male','zero_gravity'),('yuki','seal_link'),('rio_female','dimension_link'),('rio_female','pogo_bounce'),('nova_female','zero_gravity')]
states=json.loads((root/'progress.json').read_text(encoding='utf-8'))
lines=['# SKM-02 새 기술 몸 동작 후보','',f'완료 후보 {sum(s["delivered"] for s in states)}/7행. 내장 ImageGen 사용. 게임 파일 변경 없음. 커밋 스크립트 작성만 하고 실행하지 않음.','', '## 행별 결과','', '| 행 | 상태 | 검사와 판단 |','|---|---|---|']
for stem,row in rows:
 s=next((x for x in states if x['stem']==stem and x['row']==row),None)
 lines.append(f'| {stem} {row} | '+(('후보 전달' if s['delivered'] else '미전달')+f' | {s["checks"]} |' if s else '미착수 | 순서 대기 |'))
lines+=['','## 방법과 확인 범위','','ART-72 스크립트를 복사했으며 process_skm.py는 해당 처리 흐름을 이번 192px·6프레임 작업에 맞게 바꾼 실행 파일이다. extract.py는 실제 8방향 연결 덩어리로 각 포즈를 추출한다. 고정 너비 분할, 확대, 프레임별 배율 변경, 머리 붙이기를 사용하지 않는다. 원본 세로 좌표를 보존하고 행마다 한 축소 배율만 사용한다.','', 'LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. head_scale.py 자동 값과 4배 얼굴·전신 판을 함께 본다. 반대쪽 눈이 기준부터 가려진 경우 눈 사이 거리는 측정 불가로 기록하며 임의로 만들지 않는다.','', '## 사람이 판단할 점','','모션 뷰어에서 공격 연결, 검을 쥔 손의 연속성, 얼굴·의상 일치와 공중 튀어오르는 인상을 판단해야 한다. 실시간 게임 재생은 검사하지 않았다. 후보 채택과 게임 연결은 별도 작업이다.','', '## 시각적 확인','']
for s in states:
 lines+= [f'![{s["stem"]} {s["row"]}]({s["stem"]}-{s["row"]}.png)', '', '왼쪽은 기준 idle, 오른쪽은 같은 픽셀 배율의 6프레임이다. 세부 확인은 행 폴더의 page-1~3.png와 faces4x.png를 사용한다.','']
lines += ['', '## 확인 및 남은 작업', '', '미착수 행 없음. 유키 seal_link는 2회 생성 후 미전달이며, 후보 PNG/JSON은 만들지 않았다. 보고서에 남긴 유키 판은 실패 원인 확인용이다.', '', '전달된 6행의 노출 얼굴 폭은 1.000–1.033이다. 기울이거나 위를 본 얼굴은 비교에서 제외했으며, 리오·노바의 반대쪽 눈은 가려져 두 눈 거리 검사를 통과했다고 주장하지 않는다. 의상과 손·무기는 4배 판을 직접 대조했고, 마지막 채택은 사람이 움직임과 원근 표현까지 보고 판단해야 한다.', '', '행별 page-1.png~page-3.png는 2048px 폭으로 나눠 원본의 정확한 4배를 볼 수 있다. 위의 긴 판은 앱에 따라 축소 표시될 수 있다.', '']
audit_path=root/'audit.json'
if audit_path.exists():
 a=json.loads(audit_path.read_text(encoding='utf-8'))
 lines += [f'파일 검증: {a["passed"]}개 통과, {a["failed"]}개 실패. 실제 PNG의 크기·알파·여백·spill·디테일, 행별 공통 축소 배율, 메타데이터, 원본 추출 기록 및 스테이징 허용 경로를 확인했다. 얼굴·의상 미술 판단을 대신하는 점수는 아니다.', '']
lines += ['게임 실행 및 게임 연결은 수행하지 않았다. commit.ps1은 구문 검사만 하며 실행하지 않는다. 다음 단계는 모션 뷰어에서 6개 후보의 연결감과 검 길이·손 위치를 검수하고, 유키 행을 별도 재작업하는 것이다.', '']
(root/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
prompts=[]
for stem,row in rows:
 for p in sorted(root.glob(f'prompt-{stem}-{row}-*.txt')):
  prompts += [p.stem, f'Reference: art/bakeoff/{stem.split("_")[0]}/{stem}-idle-v2.png', p.read_text(encoding='utf-8'), '']
(root/'prompts.txt').write_text('\n'.join(prompts),encoding='utf-8')
paths=['design/tasks/CODEX-SKM-02.md']
for s in states:
 if s['delivered']:
  base=f'art/bakeoff/{s["stem"].split("_")[0]}/{s["stem"]}-{s["row"]}-v1'
  paths += [base+'.png',base+'.json']
paths += sorted(p.as_posix() for p in root.rglob('*') if p.is_file() and p.name not in ['commit.ps1','run.log'] and '__pycache__' not in p.parts)
paths += ['reports/codex-skm-02/commit.ps1']
script=["$ErrorActionPreference = 'Stop'", 'Set-Location -LiteralPath (Resolve-Path (Join-Path $PSScriptRoot "../.."))', '$files = @(']+["    '"+p+"'" for p in paths]+[')', 'foreach ($file in $files) {', '    git add -- $file', '    if ($LASTEXITCODE -ne 0) { throw "git add failed: $file" }', '}', '$message = @\'','art: add SKM-02 skill motion candidates','', 'Co-Authored-By: Codex <noreply@openai.com>', "'@", 'git commit --only -m $message -- $files', 'if ($LASTEXITCODE -ne 0) { throw "git commit failed" }']
(root/'commit.ps1').write_text('\n'.join(script)+'\n',encoding='utf-8-sig')
