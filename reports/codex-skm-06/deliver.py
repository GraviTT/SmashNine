"""Publish one reviewed row at a time and prepare an explicit, unexecuted commit script."""
import os, json, hashlib, shutil, subprocess, sys
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
from config import ROWS
root = Path('reports/codex-skm-06')
rows = json.loads((root/'selection.json').read_text(encoding='utf-8'))
ledger = json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
for g in ledger:
    g['sha256'] = hashlib.sha256(Path(g['raw']).read_bytes()).hexdigest()
    assert g['sha256'] == hashlib.sha256(Path(g['original']).read_bytes()).hexdigest()
(root/'generation-ledger.json').write_text(json.dumps(ledger, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
(root/'prompts.txt').write_text('\n\n'.join(f'{g["stem"]} {g["row"]} attempt {g["attempt"]}\nReferences: '+', '.join(g['references'])+'\n'+g['prompt'] for g in ledger)+'\n', encoding='utf-8')
failures_path=root/'generation-failures.json'
if failures_path.exists():
    failures=json.loads(failures_path.read_text(encoding='utf-8'))
    with (root/'prompts.txt').open('a',encoding='utf-8') as stream:
        for failure in failures:
            stream.write('\nFAILED '+failure['row']+' attempt '+str(failure['attempt'])+'\n'+failure['error']+'\n'+Path(failure['prompt_file']).read_text(encoding='utf-8').strip()+'\n')
stage = ['design/tasks/CODEX-SKM-06.md']
done = sum(r['accepted'] for r in rows)
timing = json.loads((root/'time-limit.json').read_text(encoding='utf-8'))
slow = [c for c in timing['calls'] if c.get('elapsed_minutes',0)>20]
new_done=sum(r['accepted'] for r in rows if r['row'] not in ['shot','shot_alt'])
time_note = f'**시간 제한:** 이번 재개 {timing["start_local"]}, 마감 {timing["deadline_local"]} (180분). 매 행 시작 전과 image_gen 반환 직후 Get-Date를 기록한다. 이전 중단은 사용자 설명에 따른 PC 절전 및 image_gen 대기이며 이번 회차와 별도다. [시각 기록](time-limit.json).'
time_note += (' 이번 실행의 20분 초과 호출: '+', '.join(f'{c["row"]} #{c["attempt"]}: {c["elapsed_minutes"]:.1f}분' for c in slow)) if slow else ' 이번 실행에서 반환된 호출 중 20분 초과 없음.'
if timing.get('finished_local'):
    time_note += f' **이번 작업 종료: {timing["finished_local"]}, 경과 {timing["elapsed_minutes"]:.1f}분.**'
if timing.get('status')=='hard_stop_passed':
    time_note += f' **마감 초과 확인: {timing["stop_observed_local"]}.** 마지막 image_gen 반환 직후 시각은 07:25:42 KST였고, 정규화·검토 중 다음 명시적 Get-Date는 14:34:22 KST였다. 이 시각 간격의 원인은 확인하지 못했으므로 이미지 생성 지연으로 단정하지 않는다. 확인 즉시 새 행 제작을 중단하고 기존 결과 보고와 커밋 스크립트만 마무리했다. 180분 안에 종료했다고 주장하지 않는다.'
lines = ['# SKM-06 시온 신규 기술 몸 동작 후보', '', f'**이번 회차 완료: 추가 전달 {new_done}행, 보류 {len(rows)-done}행, 미도달 {11-len(rows)}행.** 이미 병합된 shot·shot_alt 2행을 합치면 전체 전달 후보는 {done}/11행이다. 내장 image_gen을 사용했다. 이번 재개의 모든 생성은 idle-b2와 전달된 shot-v1 두 이미지를 실제 참조 인수로 사용한다. 이전 생성은 idle와 일러스트를 참조했다. 게임 파일은 수정하지 않았고, 게임 실행·뷰어 채택·커밋 실행은 하지 않았다.', '', time_note, '', '커밋 스크립트는 이번 브랜치에서 실제 추가·수정된 명시 경로만 포함한다. 이미 병합된 두 사격 행과 원본·시도 폴더는 포함하지 않는다. 위 사격 첫 요청의 필터 거절(이미지 없음)은 [generation-failures.json](generation-failures.json)에 기록했다.', '', '## 현재 상태', '', '| 행 | 결과 | fps | 공통 축소 배율 | 노출 얼굴 폭 | 자동 머리 중앙값 | 최소 여백 | 디테일 |', '|---|---|---:|---:|---|---:|---:|---|']
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
        assert margin >= 4 and all(v['interior_detail_ratio_to_reference_mean'] >= .9 for v in m['frames']) and not any(m['summary']['remaining_spill_pixels'])
        assert 0 < r['factor'] <= 1 and r['factor'] == m['summary']['common_scale']
        p = Path('art/bakeoff/xion/b')/(key+'-v1.png')
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
    subprocess.run([sys.executable, str(root/'board.py'), row, str(r['attempt'])], check=True)
    cp = root/(key+'-checks.json')
    checks = {'selection':r, 'metrics':m, 'face':f, 'head':h, 'extraction':json.loads((base/'extraction.json').read_text()), 'sheet_sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
    cp.write_text(json.dumps(checks, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    fp = root/(key+'-faces4x.png')
    shutil.copyfile(base/('face-measured.png' if (base/'face-measured.png').exists() else 'face-landmarks-proposed.png'), fp)
    stage += [(root/(key+'.png')).as_posix(), cp.as_posix(), fp.as_posix()]
    wr = f'{min(widths):.3f}–{max(widths):.3f}' if widths else '측정 불가'
    if not r['face_verified']:
        wr += ' (제안값)'
    result='이전 병합' if row in ['shot','shot_alt'] else '후보 전달' if r['accepted'] else '보류'
    lines.append(f'| [{key}]({key}.png) | {result} | {r["fps"]} | {r["factor"]} | {wr} | {h["median"] if h["median"] is not None else "유효값 없음"} | {margin}px | {detail[0]}–{detail[1]} |')
    details += [f'### {key}', '', r['note'], '', '- 생성·선정: '+r['attempt_notes'], '- 사람 판단: '+r['human_review'], '- 직접 본 프레임: '+', '.join('F'+str(i) for i in r['reviewed_frames'])+'. 얼굴 비교 프레임: '+', '.join('F'+str(i) for i in r['face_frames'])+'.', '']
lines += ['']+details+['## 검사 방법과 제한', '', '- SKM-05의 Python 스크립트를 복사해 시온용으로 변경했다. 원본 생성, 덩어리별 추출, 정규화, 얼굴 표식, 검토 보드, 전달 기록 순서다.', '- 실측·계산: 얼굴 경계 좌표와 비율, 자동 머리 정합, 여백, 번짐, 디테일을 checks JSON에 기록한다. 얼굴 폭은 기준 좌표 (62.5,46)–(72.5,46), 폭 10px의 눈 아래 노출 얼굴 경계를 사용한다.', '- 육안 판단·불확실성: 전신·얼굴을 4배 판에서 확인했다. 동작의 자연스러움, 펌프 조작의 설득력, 실제 재생 속도의 느낌은 사람 판단 대상으로 남긴다. 작은 얼굴에서 1px는 비율 0.1이므로 소수 자릿수는 측정 정확도 보증이 아니다.', '- 한 행을 한 번에 6자세로 생성했다. 각 원본 실루엣 덩어리별 추출이며 고정 폭 자르기·머리 붙이기·프레임별 배율 변경은 하지 않았다.', '- LANCZOS / sharpen 60 / despill auto / palette none / #00ff00. 192px 셀, 몸 중심 x96, 발끝 y152. 행 전체 배율 하나를 적용했다.', '- 얼굴 목표 0.96–1.04, 전달 허용 0.95–1.06. 기준의 먼 눈은 검은 앞머리와 겹쳐 독립된 눈 중심을 확정하지 못했으므로 눈 사이 거리는 측정 불가로 기록했다. 이것을 통과로 계산하지 않는다.', '- 얼굴 표식은 검토 판에서 확인한 값만 확정한다. 돌아서거나 뒤집힌 얼굴은 측정 제외로 기록하고 직립 프레임을 기준으로 배율을 확인한다.', '- 디테일은 파이프라인의 내부 색 대비 지표이며 미술 품질 점수가 아니다. 기준 프레임 대비 각 프레임 90% 이상을 검사한다.', '- 원본은 art/raw/skm-06/에 보존하고 커밋에서 제외한다. 시도 폴더·캐시·실행 로그도 제외한다. 전체 프롬프트는 [prompts.txt](prompts.txt), 원본 해시는 [generation-ledger.json](generation-ledger.json)에 있다.', '', '## 남은 작업', '']
order = [('xion', row) for row in ROWS]
pending = [s+'-'+r for s,r in order if not any(v['stem']==s and v['row']==r for v in rows)]
lines += ['미도달: '+(', '.join(pending) if pending else '없음')+'.', '', '## 다음 권장 단계', '', '리드가 전달 후보 8행을 검토하고 시안 월드컵에서 사람이 동작 연결과 얼굴·의상을 판단한 뒤 리드가 게임에 연결한다. shot_air_down은 F3 상승량 약 15px를 약 4px로 줄이는 별도 재작업이 필요하다. 이번 회차의 해당 행 생성 2회는 소진했다.', '', '사람이 특히 볼 것: tumble·barrage의 F6→F1 연결, recoil_jump에서 펴진 몸의 길이, double_cast의 열린 손과 총 손잡이 접촉, shot_up F5에서 두 총이 한 긴 총처럼 보이는지. 재생 검증은 하지 않았으며 모두 후보 단계다.', '', '## 시각적 확인', '', '![이번 추가 후보 예시](continuation-preview.png)', '', '위에서부터 구르기·난사·수평 비행의 실제 전달 시트다. 원본 후보는 변경하지 않고 보고서용 빈 셀 여백만 줄였다.', '']
for r in rows:
    key = r['stem']+'-'+r['row']
    lines += [f'![{key} 4배 검토]({key}.png)', '', '각 단 왼쪽은 idle 기준, 오른쪽은 두 프레임이다. 빨간 선은 발끝 y152이며 반복 동작 보드 마지막 단은 F6→F1 연결이다.', '']
if (root/'audit.json').exists():
    audit = json.loads((root/'audit.json').read_text(encoding='utf-8'))
    if audit.get('passed'):
        lines += ['## 확인 및 테스트', '', f'파일·규격·쓰기 범위·커밋 스크립트 구문 검사 {len(audit["checks"])}개 통과. [audit.json](audit.json). 이는 보류 행의 미술 판정을 통과로 바꾸지 않는다. 게임과 commit.ps1은 실행하지 않았다.', '']
        lines += [f'디스크: 이번 보고서·중간 검토 파일·원본 합계 약 {sum(audit["folder_bytes"].values())/1e6:.1f} MB. 기존 파일을 포함한 작업 클론 `{Path.cwd().as_posix()}`은 약 {audit["workspace_bytes"]/1e9:.2f} GB다.', '']
(root/'README.md').write_text('\n'.join(x.rstrip() for x in lines)+'\n', encoding='utf-8')
scripts = ['config.py','process.py','face_check.py','board.py','face_grid.py','review_faces.py','deliver.py','ingest.py','verify_skm.py','select_row.py','overview.py']
for name in scripts+['README.md','prompts.txt','selection.json','commit.ps1','generation-ledger.json','files-to-stage.json','audit.json','time-limit.json','clock.ps1','resume_setup.py']:
    p = root/name
    if p.exists() or name in ['commit.ps1','files-to-stage.json']:
        stage.append(p.as_posix())
stage = sorted(set(stage + [(root/'continue_c.py').as_posix(),(root/'continuation-preview.png').as_posix()] + ([failures_path.as_posix()] if failures_path.exists() else [])))
base_commit = timing['base_commit']
changed_tracked=set(subprocess.run(['git','diff','--name-only',base_commit],capture_output=True,text=True,check=True).stdout.splitlines())
tracked=set(subprocess.run(['git','ls-files'],capture_output=True,text=True,check=True).stdout.splitlines())
def branch_changed(path):
    return path not in tracked or path in changed_tracked
stage = [p for p in stage if p.endswith(('commit.ps1','files-to-stage.json','audit.json')) or branch_changed(p)]
(root/'files-to-stage.json').write_text(json.dumps(stage, indent=2)+'\n', encoding='utf-8')
ps = ['# Prepared for lead review. Codex does not run this script.', "$ErrorActionPreference = 'Stop'", "$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path", 'Set-Location -LiteralPath $repo', '$files = @(']
ps += ["    '"+p+"'" for p in stage]
ps += [')', '$alreadyStaged = @(git diff --cached --name-only)', "if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths' }", '$outside = @($alreadyStaged | Where-Object { $files -notcontains $_ })', "if ($outside.Count) { throw ('Unrelated staged paths: ' + ($outside -join ', ')) }", 'git add -- @files',"if ($LASTEXITCODE -ne 0) { throw 'git add failed' }", "$message = @'", 'art: add Xion SKM-06 body motion candidates and review', '', 'Co-Authored-By: Codex <noreply@openai.com>', "'@", 'git commit -m $message', "if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }"]
(root/'commit.ps1').write_text('\n'.join(ps)+'\n', encoding='utf-8')
print(json.dumps({'delivered':[r['stem']+'-'+r['row'] for r in rows if r['accepted']], 'held':[r['stem']+'-'+r['row'] for r in rows if not r['accepted']], 'not_reached':pending}, ensure_ascii=False))
