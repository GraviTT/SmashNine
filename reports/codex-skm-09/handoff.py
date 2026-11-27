"""Export only inspected candidates and maintain an explicit, unexecuted commit script."""
import hashlib, json, shutil, subprocess, sys
from pathlib import Path
from config import ROOT, ROWS, ORDER

def read(p):
    return json.loads(p.read_text(encoding='utf-8'))

def write(p, text):
    p.write_text('\n'.join(line.rstrip() for line in text.splitlines()).rstrip()+'\n', encoding='utf-8', newline='\n')

def dump(p, data):
    write(p, json.dumps(data,ensure_ascii=False,indent=2))

rows = read(ROOT/'selection.json')
stage = ['design/tasks/CODEX-SKM-09.md']
lines = ['# SKM-09 리오 두 행 재작업', '',
    f'완료: 후보 전달 {sum(r["accepted"] for r in rows)}행 · 보류 {sum(not r["accepted"] for r in rows)}행 · 미도달 {2-len(rows)}행. 내장 image_gen으로 만들었다. 게임 파일·재생 속도 설정·Git 인덱스·커밋은 변경하지 않았다.', '',
    '시작은 보수적으로 2026-11-27 12:03 KST, 마감은 13:03 KST(60분)로 잡았다. 각 생성 전후 시각·실제 참조 이미지 인수·원본 해시는 `generation-ledger.json`, 프롬프트 전문은 `prompts.txt`에 있다.', '',
    '## 실측·계산', '',
    '| 행 | 결과 | 얼굴 폭/기준 | 자동 머리 중앙값 | 공통 배율 | 최소 여백 | 최소 디테일/기준 |',
    '|---|---|---:|---:|---:|---:|---:|']
details=[]
for r in rows:
    stem, row = r['stem'], r['row']
    key=stem+'-'+row
    base=ROOT/stem/row/f'attempt-{r["attempt"]}'
    m=read(base/'metrics.json');h=read(base/'head-scale.json')
    face=read(base/('face-measured.json' if r['face_verified'] else 'face-proposed.json'))
    ratios=[f['face_width_ratio'] for f in face['frames'] if f['frame'] in r['face_frames'] and f['face_width_ratio'] is not None]
    margin=min(f['margin']['minimum'] for f in m['frames'])
    detail=min(f['interior_detail_ratio_to_reference_mean'] for f in m['frames'])
    factor=m['summary']['common_scale']
    if r['accepted']:
        assert ratios and all(.95<=v<=1.06 for v in ratios), (key,ratios)
        assert r['face_verified'] and r['pose_ok'] and r['costume_ok']
        assert margin>=4 and detail>=.9 and not any(m['summary']['remaining_spill_pixels'])
        p=Path('art/bakeoff/rio')/(key+'-v1.png');source=base/(key+'.png')
        if p.exists():
            assert p.read_bytes()==source.read_bytes(), 'Do not replace an exported candidate'
        else:
            shutil.copyfile(source,p)
        fps,loop,label=ROWS[row]
        metadata={'note':r['note'],'for':label,'frames':6,'fps':fps,'cell':192,'feet':[96,152],'loop':loop,'factor':factor}
        if p.with_suffix('.json').exists():
            assert read(p.with_suffix('.json'))==metadata
        else:
            dump(p.with_suffix('.json'),metadata)
        stage += [p.as_posix(),p.with_suffix('.json').as_posix()]
    checks={'selection':r,'metrics':m,'face':face,'head':h,'extraction':read(base/'extraction.json'),'sheet_sha256':hashlib.sha256((base/(key+'.png')).read_bytes()).hexdigest()}
    fixes=ROOT/(key+'-fixes.json')
    if fixes.exists():checks['fix_checks']=read(fixes)
    dump(ROOT/(key+'-checks.json'),checks)
    shutil.copyfile(base/('face-measured.png' if r['face_verified'] else 'face-landmarks-proposed.png'), ROOT/(key+'-faces4x.png'))
    stage += [(ROOT/(key+s)).as_posix() for s in ['.png','-checks.json','-faces4x.png']]
    ratio=f'{min(ratios):.3f}–{max(ratios):.3f}' if ratios else '측정 불가'
    if not r['face_verified']:ratio+=' (자동 제안)'
    lines.append(f'| {key} | {"전달" if r["accepted"] else "보류"} | {ratio} | {h["median"]} | {factor} | {margin}px | {detail:.3f} |')
    details += ['',f'### {key}','',r['note'],'','- 관찰: '+r['observation'],'- 사람 판단: '+r['human_review'],'- 얼굴 비교 프레임: '+', '.join('F'+str(x) for x in r['face_frames'])+'. 전신은 F1–F6를 직접 확인했다.']
    if fixes.exists():
        fx=read(fixes)
        if stem=='rio_male':
            details += ['', '| 프레임 | 검 끝 픽셀 (x,y) | 검 끝에서 바깥 셀 경계 | 전신 최소 여백 |','|---|---|---:|---:|']
            for f in fx['frames']:
                details.append(f'| F{f["frame"]} | {f["tip_pixel"]} | {f["distance_to_outward_cell_edge"]}px | {f["whole_sprite_minimum_margin"]}px |')
            details += ['','검 끝 주변 영역은 육안으로 골랐고, 그 안의 가장 바깥 불투명 픽셀과 x0 또는 x191의 거리를 계산했다. 전신 알파 경계 상자도 따로 검사해 검 전체가 셀 안임을 확인했다.']
        else:
            details += ['', '손 개수 육안 관찰: F1–F6 모두 2개. R은 오른손 검 손잡이, L은 빈 왼손이며, F2에는 귀 옆 손과 검을 쥔 손만 남았다. 원본·정규화 4배 판을 확인했다. 손 인식 자동 검사는 아니다.']
        details += ['',f'![{key} 수정 검수]({key}-fixes.png)','', '표식은 이번 수정 지점을 가리킨다. 여성 손 중심 표식은 대략적인 위치이며, 남성 검 끝 좌표는 픽셀 계산값이다.']
lines += details+['','## 측정 방법과 한계','',
    '- SKM-08 Python 도구를 복사해 재사용했다. 실루엣 연결 덩어리별 추출이며 고정 폭으로 자르지 않았다. 행 전체 공통 배율 하나, 192px 셀, 발 y152, 기준 x96, LANCZOS / sharpen 60 / despill auto / palette none / #00ff00.',
    '- 얼굴 폭은 눈 아래 부근의 좌우 경계 표식 사이 수평 간격이다. 자동 제안을 4배 보드와 픽셀 격자에서 검토했다. 좌표·원래 제안·보정 이유는 checks JSON에 남겼다. 여성 기준 10px·남성 16px여서 한 픽셀 차이는 각각 10%·6.25%다. 1.000은 지정한 표식의 비율이지 얼굴 전체가 완전히 같다는 뜻이 아니다.',
    '- 반대쪽 눈은 앞머리와 겹쳐 눈 사이 거리를 확정하지 못했다. 측정 불가이며 통과 수치로 세지 않는다. 자동 머리 정합은 보조 지표다.',
    '- 디테일은 내부 색 대비 계산값이며 미술 품질 점수가 아니다. 손 개수·검 연결·의상 일치는 확대판의 육안 관찰이다. 실제 게임 재생은 하지 않았다.', '',
    '## 시각적 확인','', '![두 행 개요](overview.png)','',
    '왼쪽은 해당 체형 대기 기준이고 오른쪽은 새 후보 F1–F6다. 빨간 선은 발 기준이다.', '',
    '상세 4배 판은 각 프레임마다 왼쪽부터 같은 체형 대기 기준, 전달된 반대 체형 동작, 이번 후보를 비교한다. 후보 PNG는 192px 셀 그대로다.']
for r in rows:
    key=r['stem']+'-'+r['row'];lines += ['',f'- [{key} 4배 비교판]({key}.png)']
if (ROOT/'audit.json').exists():
    a=read(ROOT/'audit.json')
    lines += ['','## 확인 및 테스트','',f'파일·알파·여백·번짐·디테일·메타데이터·경로 검증: {a["status"]}. commit.ps1은 문법만 검사했고 실행하지 않았다.',f'검증 시각: {a["checked_at_utc"]}, 경과 {a["elapsed_minutes"]}분. 생성 {a["generation_count"]}회.',f'작업 클론 `{a["workspace_path"]}`: {a["workspace_gb"]}GB. 이번 작업 파일: {a["task_mb"]}MB.']
lines += ['','## 남은 작업과 다음 권장 단계','',
    '리드가 비교판과 측정 근거를 검토하고 시안 월드컵에서 사람이 20fps 동작 연결과 외형 일치를 판단한다. 채택·게임 연결은 하지 않았다. 기존 웹 예산 결정 #223 뒤 게임에 넣는 절차는 리드의 후속 작업이다. 새 할 일 위젯 항목은 만들지 않았다.', '',
    '커밋 준비: `powershell -ExecutionPolicy Bypass -File reports/codex-skm-09/commit.ps1`. 원본·attempt 폴더는 포함하지 않는다.']
write(ROOT/'README.md','\n'.join(lines))

if '--text-only' not in sys.argv:
    subprocess.run([sys.executable,'-B',str(ROOT/'compare_boards.py')],check=True)

if '--text-only' not in sys.argv:
    subprocess.run([sys.executable,'-B',str(ROOT/'overview.py')],check=True)
names=['config.py','process.py','face_check.py','face_grid.py','review_faces.py','board.py','ingest_result.py','publish.py','decide.py','audit.py','overview.py','finalize.py','handoff.py','compare_boards.py','fix_checks.py','overview.png','README.md','prompts.txt','selection.json','generation-ledger.json','time-limit.json','audit.json','commit.ps1','files-to-stage.json','face-corrections-female.json','face-corrections-male.json']
for name in names:
    if (ROOT/name).exists() or name in ['audit.json','commit.ps1','files-to-stage.json']:
        stage.append((ROOT/name).as_posix())
for p in ROOT.glob('*-fixes.*'):stage.append(p.as_posix())
stage=sorted(set(stage));dump(ROOT/'files-to-stage.json',stage)
ps=['# Explicit reviewed files only. Prepared by Codex; not executed.',"$ErrorActionPreference = 'Stop'", "$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path",'Set-Location -LiteralPath $repo',"if ((git branch --show-current) -ne 'codex/skm-09') { throw 'Wrong branch' }",'$files = @']
ps[-1]='$files = @('
ps += ["    '"+p+"'" for p in stage]+[')','$alreadyStaged = @(git diff --cached --name-only)',"if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths' }",'$outside = @($alreadyStaged | Where-Object { $files -notcontains $_ })',"if ($outside.Count) { throw ('Unrelated staged paths: ' + ($outside -join ', ')) }",'git add -- @files',"if ($LASTEXITCODE -ne 0) { throw 'git add failed' }",'git diff --cached --check',"if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed' }","git commit -m 'art: redraw Rio female throw and male pierce candidates'","if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
write(ROOT/'commit.ps1','\n'.join(ps))
print('Updated handoff:',len(rows),'reviewed rows;',len(stage),'explicit stage paths')
