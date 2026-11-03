"""Publish one reviewed row at a time and prepare an explicit, unexecuted commit script."""
import os, json, hashlib, shutil, subprocess, sys
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
root = Path('reports/codex-skm-05')
rows = json.loads((root/'selection.json').read_text(encoding='utf-8'))
ledger = json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
for g in ledger:
    g['sha256'] = hashlib.sha256(Path(g['raw']).read_bytes()).hexdigest()
    assert g['sha256'] == hashlib.sha256(Path(g['original']).read_bytes()).hexdigest()
(root/'generation-ledger.json').write_text(json.dumps(ledger, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(root/'prompts.txt').write_text('\n\n'.join(f'{g["stem"]} {g["row"]} attempt {g["attempt"]}\nReferences: '+', '.join(g['references'])+'\n'+g['prompt'] for g in ledger)+'\n', encoding='utf-8')
stage = ['design/tasks/CODEX-SKM-05.md']
done = sum(r['accepted'] for r in rows)
lines = ['# SKM-05 Nova 신규 기술 몸 동작 후보', '', f'**완료: 후보 {done}/6행, 보류 {len(rows)-done}행, 미착수 {6-len(rows)}행.** 내장 image_gen을 사용했다. 게임 파일은 수정하지 않았고, 게임 실행·뷰어 채택·커밋 실행은 하지 않았다.', '', '## 현재 상태', '', '| 행 | 결과 | fps | 공통 축소 배율 | 노출 얼굴 폭 | 자동 머리 중앙값 | 최소 여백 | 디테일 |', '|---|---|---:|---:|---|---:|---:|---|']
details = []
for r in rows:
    stem, row = r['stem'], r['row']
    key = stem+'-'+row
    base = root/stem/row/f'attempt-{r["attempt"]}'
    m = json.loads((base/'metrics.json').read_text())
    facepath = base/('face-measured.json' if (base/'face-measured.json').exists() else 'face-proposed.json')
    f = json.loads(facepath.read_text(encoding='utf-8'))
    h = json.loads((base/'head-scale.json').read_text())
    widths = [x['face_width_ratio'] for x in f['frames'] if x['frame'] in r['face_frames'] and x['face_width_ratio'] is not None]
    margin = min(x['margin']['minimum'] for x in m['frames'])
    detail = m['summary']['interior_detail_range']
    source = base/(key+'.png')
    if r['accepted']:
        assert r['face_verified'] and r['costume_ok'] and r['pose_ok']
        assert widths and all(.95 <= v <= 1.06 for v in widths), (key, widths)
        assert margin >= 4 and min(detail) >= 79 and not any(m['summary']['remaining_spill_pixels'])
        assert 0 < r['factor'] <= 1 and r['factor'] == m['summary']['common_scale']
        p = Path('art/bakeoff/nova')/(key+'-v1.png')
        if p.exists():
            assert p.read_bytes() == source.read_bytes(), 'Never overwrite an existing candidate'
        else:
            shutil.copyfile(source, p)
        metadata = {k:r[k] for k in ['note','for','fps','loop','factor']}
        metadata.update(frames=6, cell=192, feet=[96,152])
        encoded = json.dumps(metadata, ensure_ascii=False, indent=2)+'\n'
        jp = p.with_suffix('.json')
        if jp.exists():
            assert jp.read_text(encoding='utf-8') == encoded
        else:
            jp.write_text(encoded, encoding='utf-8')
        stage += [p.as_posix(), jp.as_posix()]
    subprocess.run([sys.executable, str(root/'board.py'), row, str(r['attempt']), stem.removeprefix('nova_')], check=True)
    cp = root/(key+'-checks.json')
    checks = {'selection':r, 'metrics':m, 'face':f, 'head':h, 'extraction':json.loads((base/'extraction.json').read_text()), 'sheet_sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
    cp.write_text(json.dumps(checks, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    fp = root/(key+'-faces4x.png')
    shutil.copyfile(base/('face-measured.png' if (base/'face-measured.png').exists() else 'face-landmarks-proposed.png'), fp)
    stage += [(root/(key+'.png')).as_posix(), cp.as_posix(), fp.as_posix()]
    wr = f'{min(widths):.3f}–{max(widths):.3f}' if widths else '측정 불가'
    if not r['face_verified']:
        wr += ' (제안값)'
    lines.append(f'| [{key}]({key}.png) | {"후보 전달" if r["accepted"] else "보류"} | {r["fps"]} | {r["factor"]} | {wr} | {h["median"]} | {margin}px | {detail[0]}–{detail[1]} |')
    details += [f'### {key}', '', r['note'], '', '- 생성·선정: '+r['attempt_notes'], '- 사람 판단: '+r['human_review'], '- 직접 본 프레임: '+', '.join('F'+str(i) for i in r['reviewed_frames'])+'. 얼굴 비교 프레임: '+', '.join('F'+str(i) for i in r['face_frames'])+'.', '']
lines += ['']+details+['## 검사 방법과 제한', '', '- SKM-04의 process.py·face_check.py·board.py·face_grid.py를 복사하고 Nova용으로 변경했다. 얼굴 표식과 가려진 눈 처리 기준은 SKM-02의 face_check_ny.py를 따랐다.', '- 한 행을 한 번에 6자세로 생성했다. 각 원본 실루엣 덩어리별 추출이며 고정 폭 자르기·확대·머리 붙이기·프레임별 배율 변경은 하지 않았다.', '- LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. 192px 셀, 몸 중심 x96, 발끝 y152. 비행도 발 기준선은 같으며 게임이 띄운다.', '- 얼굴 목표 0.96–1.04, 전달 허용 0.95–1.06. 양쪽 idle 기준 모두 반대쪽 눈이 앞머리에 가려져 눈 간 거리는 측정 불가이며 통과로 계산하지 않는다. 노출 얼굴 폭을 눈 아래 경계에서 비교한다. 소수점은 계산 출력 정밀도이며 측정 오차를 보증하지 않는다.', '- 전신 4배 판에서 한 얼굴·양손·양발·의상·동작 의미를 확인한다. 얼굴 자동 제안은 표식을 직접 확인한 뒤만 채택한다. 보류 행의 제안값은 확정 실측이 아니다.', '- 원본은 art/raw/skm-05/에 보존하고 커밋에서 제외한다. 시도 폴더·캐시·실행 로그도 제외한다. 전체 프롬프트는 [prompts.txt](prompts.txt), 원본 해시는 [generation-ledger.json](generation-ledger.json)에 있다.', '', '## 남은 작업', '']
order = [(f'nova_{b}', row) for row in ['gravity_beam','orb_throw','field_fly'] for b in ['male','female']]
pending = [s+'-'+r for s,r in order if not any(v['stem']==s and v['row']==r for v in rows)]
lines += ['미착수: '+(', '.join(pending) if pending else '없음')+'.', '', '## 다음 권장 단계', '', '사람이 모션 뷰어에서 전달 후보의 동작 연결과 얼굴·의상을 판단한 뒤 리드가 게임에 연결한다. 보류 행은 명시한 원인을 해결하는 후속 제작이 필요하다.', '', '## 시각적 확인', '']
for r in rows:
    key = r['stem']+'-'+r['row']
    lines += [f'![{key} 4배 검토]({key}.png)', '', '각 단 왼쪽은 idle 기준, 오른쪽은 두 프레임이다. 빨간 선은 발끝 y152이며 비행 보드 마지막 단은 F6→F1 연결이다.', '']
if (root/'audit.json').exists():
    audit = json.loads((root/'audit.json').read_text(encoding='utf-8'))
    if audit.get('passed'):
        lines += ['## 확인 및 테스트', '', f'파일·규격·쓰기 범위·커밋 스크립트 구문 검사 {len(audit["checks"])}개 통과. [audit.json](audit.json). 이는 보류 행의 미술 판정을 통과로 바꾸지 않는다. 게임과 commit.ps1은 실행하지 않았다.', '']
        lines += [f'디스크: 이번 보고서·중간 검토 파일·원본 합계 약 {sum(audit["folder_bytes"].values())/1e6:.1f} MB. 기존 파일을 포함한 작업 클론 `{Path.cwd().as_posix()}`은 약 {audit["workspace_bytes"]/1e9:.2f} GB다.', '']
(root/'README.md').write_text('\n'.join(x.rstrip() for x in lines)+'\n', encoding='utf-8')
scripts = ['process.py','face_check.py','board.py','face_grid.py','review_faces.py','deliver.py','ingest.py','verify_skm.py']
for name in scripts+['README.md','prompts.txt','selection.json','commit.ps1','generation-ledger.json','files-to-stage.json','audit.json']:
    p = root/name
    if p.exists() or name in ['commit.ps1','files-to-stage.json']:
        stage.append(p.as_posix())
stage = sorted(set(stage))
(root/'files-to-stage.json').write_text(json.dumps(stage, indent=2)+'\n', encoding='utf-8')
ps = ['# Prepared for lead review. Codex does not run this script.', "$ErrorActionPreference = 'Stop'", "$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path", 'Set-Location -LiteralPath $repo', '$files = @(']
ps += ["    '"+p+"'" for p in stage]
ps += [')','git add -- @files',"if ($LASTEXITCODE -ne 0) { throw 'git add failed' }", "$message = @'", 'art: add Nova SKM-05 body motion candidates and review', '', 'Co-Authored-By: Codex <noreply@openai.com>', "'@", 'git commit -m $message', "if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
(root/'commit.ps1').write_text('\n'.join(ps)+'\n', encoding='utf-8')
print(json.dumps({'delivered':[r['stem']+'-'+r['row'] for r in rows if r['accepted']], 'held':[r['stem']+'-'+r['row'] for r in rows if not r['accepted']], 'not_reached':pending}, ensure_ascii=False))
