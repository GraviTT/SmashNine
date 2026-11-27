"""Publish inspected rows and maintain an explicit commit script, never execute git writes."""
import os,json,shutil,hashlib,subprocess,sys
from pathlib import Path
from config import ROOT,ROWS,ORDER
os.environ['PYTHONDONTWRITEBYTECODE']='1'
selection=ROOT/'selection.json'
rows=json.loads(selection.read_text(encoding='utf-8')) if selection.exists() else []
stage=['design/tasks/CODEX-SKM-08.md']
lines=['# SKM-08 리오 키트 v3 몸 동작 후보','',f'전달 {sum(r["accepted"] for r in rows)}행 · 보류 {sum(not r["accepted"] for r in rows)}행 · 미도달 {10-len(rows)}행. 내장 image_gen으로 제작했다. 게임 파일·재생 속도 설정·Git 커밋은 변경하지 않았다.','', '시작 2026-11-27 00:08:25 KST, 마감 02:38:25 KST(150분). 각 생성 직전·직후 시각과 실제 참조 이미지 경로는 generation-ledger.json에 기록했다.','', '## 실측·계산 결과','', '| 행 | 상태 | 얼굴 폭/기준 | 머리 자동 중앙값 | 배율 | 여백 | 디테일/기준 |','|---|---|---:|---:|---:|---:|---:|']
details=[]
for r in rows:
    stem,row,attempt=r['stem'],r['row'],r['attempt'];key=stem+'-'+row;base=ROOT/stem/row/f'attempt-{attempt}'
    m=json.loads((base/'metrics.json').read_text(encoding='utf-8'));h=json.loads((base/'head-scale.json').read_text(encoding='utf-8'))
    face=json.loads((base/('face-measured.json' if r['face_verified'] else 'face-proposed.json')).read_text(encoding='utf-8'))
    ratios=[f['face_width_ratio'] for f in face['frames'] if f['frame'] in r['face_frames'] and f['face_width_ratio'] is not None]
    fw=f'{min(ratios):.3f}–{max(ratios):.3f}' if ratios else '측정 불가'
    if not r['face_verified']:fw+=' (자동 제안)'
    margin=min(f['margin']['minimum'] for f in m['frames']);detail=min(f['interior_detail_ratio_to_reference_mean'] for f in m['frames'])
    fps,loop,label=ROWS[row];factor=m['summary']['common_scale']
    if r['accepted']:
        assert ratios and all(.95<=v<=1.06 for v in ratios),(key,ratios)
        assert r['face_verified'] and r['pose_ok'] and r['costume_ok']
        assert margin>=4 and detail>=.9 and not any(m['summary']['remaining_spill_pixels'])
        p=Path('art/bakeoff/rio')/(key+'-v1.png');src=base/(key+'.png')
        if p.exists():assert p.read_bytes()==src.read_bytes(),'Do not overwrite a delivered row'
        else:shutil.copyfile(src,p)
        meta={'note':r['note'],'for':label,'frames':6,'fps':fps,'cell':192,'feet':[96,152],'loop':loop,'factor':factor}
        encoded=json.dumps(meta,ensure_ascii=False,indent=2)+'\n';jp=p.with_suffix('.json')
        if jp.exists():assert jp.read_text(encoding='utf-8')==encoded
        else:jp.write_text(encoded,encoding='utf-8',newline='\n')
        stage.extend([p.as_posix(),jp.as_posix()])
    subprocess.run([sys.executable,'-B',str(ROOT/'board.py'),stem,row,str(attempt)],check=True)
    checks=ROOT/(key+'-checks.json');checks.write_text(json.dumps({'selection':r,'metrics':m,'face':face,'head':h,'extraction':json.loads((base/'extraction.json').read_text(encoding='utf-8')),'sheet_sha256':hashlib.sha256((base/(key+'.png')).read_bytes()).hexdigest()},ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    fp=ROOT/(key+'-faces4x.png');shutil.copyfile(base/('face-measured.png' if r['face_verified'] else 'face-landmarks-proposed.png'),fp)
    stage.extend([(ROOT/(key+'.png')).as_posix(),checks.as_posix(),fp.as_posix()])
    lines.append(f'| [{key}]({key}.png) | {"후보 전달" if r["accepted"] else "보류"} | {fw} | {h["median"]} | {factor} | {margin}px | {detail:.3f} |')
    details.extend([f'### {key}','',r['note'],'','- 관찰: '+r['observation'],'- 사람 판단: '+r['human_review'],'- 직접 본 프레임: F1–F6. 얼굴 수치에 사용한 프레임: '+', '.join('F'+str(i) for i in r['face_frames'])+'.',''])
pending=[s+'-'+r for s,r in ORDER if not any(v['stem']==s and v['row']==r for v in rows)]
lines+=['']+details+['## 측정 방법과 한계','', '- SKM-06 Python 도구를 복사하고 리오용으로 변경했다. 고정 폭 자르기 없이 원본의 여섯 실루엣 덩어리별 추출을 사용한다.', '- 행별 공통 배율 하나, 192px 셀, 몸 중심 x96, 접지 y152. LANCZOS / sharpen 60 / despill auto / palette none / #00ff00.', '- 얼굴 폭은 눈 아래 부근의 좌우 볼 표식 사이 수평 간격이다. 자동 제안을 격자와 4배 확대에서 검토하고, 잘못 잡힌 표식은 근거를 남겨 수정했다. 기준과 각 프레임의 좌표·수정 이유는 checks JSON에 남긴다. 1.000은 선택한 좌표로 계산한 비율이며 정확도 보증이 아니다. 기준 폭은 남성 16px·여성 10px여서 한 픽셀 차이만으로 각각 약 6%·10%가 변한다. 얼굴 가림·회전과 경계 선택 오차가 있으므로 사람 검수가 필요하다.', '- 반대쪽 눈은 앞머리와 겹쳐 독립된 중심을 확정하지 못했다. 눈 사이 거리는 측정 불가로 기록하며 통과로 세지 않는다. 돌아선 얼굴은 명시적으로 제외한다.', '- 디테일 수치는 내부 색 대비이며 미술 품질 점수가 아니다. 각 프레임이 기준의 90% 이상인지 검사한다.', '- 전신 4배 판에서 손·검·의상·실루엣을 관찰했다. 동작의 자연스러움과 실제 게임 재생의 느낌은 아직 검증하지 않았다.', '', '## 남은 작업','', '미도달: '+(', '.join(pending) if pending else '없음')+'.','', '## 다음 권장 단계','', '리드가 검토한 뒤 시안 월드컵에서 사람이 얼굴·의상 일치와 동작 연결을 판단한다. 게임 연결은 리드의 후속 작업이다.','', '## 시각적 확인','', '![전체 검수표](overview.png)', '', '초록은 전달 후보, 주황은 보류다. 각 행 왼쪽은 대기 기준이고 오른쪽 여섯 장은 순서대로 F1–F6다.','']
for r in rows:
    key=r['stem']+'-'+r['row'];lines += [f'![{key} 검토]({key}.png)','','각 단 왼쪽은 대기 기준, 오른쪽은 두 프레임이다. 빨간 선은 발 기준 y152다.','']
if (ROOT/'audit.json').exists():
    audit=json.loads((ROOT/'audit.json').read_text(encoding='utf-8'));lines+=['## 확인 및 테스트','',f'파일·규격·경로 검증: {audit.get("status")}. 게임 실행 및 commit.ps1 실행은 하지 않았다.',f'작업 클론 전체 크기: {audit.get("workspace_gb")} GB. 이번 작업 파일: {audit.get("task_mb")} MB.', f'검증 시각(UTC): {audit.get("checked_at_utc")}. 시작 후 {audit.get("elapsed_minutes")}분, 생성 {audit.get("generation_count")}회. 작업 폴더: `{audit.get("workspace_path")}`.','']
(ROOT/'README.md').write_text('\n'.join(l.rstrip() for l in lines)+'\n',encoding='utf-8',newline='\n')
for name in ['config.py','process.py','face_check.py','face_grid.py','review_faces.py','board.py','ingest_result.py','publish.py','decide.py','audit.py','overview.py','finalize.py','overview.png','README.md','prompts.txt','selection.json','generation-ledger.json','audit.json','commit.ps1','files-to-stage.json']:
    if (ROOT/name).exists() or name in ['commit.ps1','files-to-stage.json']:stage.append((ROOT/name).as_posix())
stage=sorted(set(stage));(ROOT/'files-to-stage.json').write_text(json.dumps(stage,indent=2)+'\n',encoding='utf-8',newline='\n')
ps=['# Prepared for lead review; not executed by Codex.',"$ErrorActionPreference = 'Stop'","$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path",'Set-Location -LiteralPath $repo',"if ((git branch --show-current) -ne 'codex/skm-08') { throw 'Wrong branch' }",'$files = @(']+["    '"+p+"'" for p in stage]+[')','$alreadyStaged = @(git diff --cached --name-only)',"if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths' }",'$outside = @($alreadyStaged | Where-Object { $files -notcontains $_ })',"if ($outside.Count) { throw ('Unrelated staged paths: ' + ($outside -join ', ')) }",'git add -- @files',"if ($LASTEXITCODE -ne 0) { throw 'git add failed' }",'git diff --cached --check',"if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed' }","git commit -m 'art: add Rio SKM-08 body motion candidates and review'", "if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
(ROOT/'commit.ps1').write_text('\n'.join(ps)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'delivered':sum(r['accepted'] for r in rows),'held':sum(not r['accepted'] for r in rows),'not_reached':pending},ensure_ascii=False))
