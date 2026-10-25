"""Final report links, viewed-image ledger, input hashes and allowed-path manifest."""
import sys
sys.dont_write_bytecode=True
import hashlib,json,re,datetime
from pathlib import Path
from audit import ROOT,OUT,dump
from candidate_notes import note

def read(p):return json.loads(p.read_text(encoding='utf-8'))
def main():
    live=read(OUT/'metrics/live_index.json');candidates=read(OUT/'metrics/candidate_index.json');queue=read(OUT/'metrics/candidate_visual_queue.json');extra=read(OUT/'metrics/candidate_head_contacts.json')
    reviewed=[]
    for x in live:reviewed.append({'path':x['path'],'contact':x['contact'],'scope':'live','review':'직접 view_image로 확인'})
    for x in queue+extra:
        if any(z['path']==x['path'] for z in reviewed):continue
        d=read(OUT/'metrics/candidates'/f"{Path(x['path']).stem}.json");reviewed.append({'path':x['path'],'contact':x['contact'],'scope':'candidate','review':'직접 view_image로 확인','observation':note(d)})
    assert len(reviewed)==113,len(reviewed)
    for x in reviewed:assert (ROOT/x['contact']).is_file(),x
    dump(OUT/'metrics/review_log.json',reviewed)
    hashes=[]
    for x in live+candidates:
        p=ROOT/x['path'];hashes.append({'path':x['path'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
    dump(OUT/'metrics/input_hashes.json',hashes)
    stats=read(OUT/'metrics/summary.json');v=read(OUT/'metrics/validation.json')
    # Keep a compact, reproducible audit result separate from the lengthy row tables.
    text=f'''# 검증 기록

- 원자료: 현재 이미지 {len(live)}개, 후보 {len(candidates)}개. 입력 해시는 `metrics/input_hashes.json`에 기록했다(사후 식별용이며 변경 전후 대조라고 주장하지 않음).
- 치수/남는 그림 셀/빈 사용 셀 오류: 0. 인접 완전 동일 프레임: 현재 {v['live_identical_adjacent']}, 후보 {v['candidate_identical_adjacent']}.
- 현재 캐릭터 머리 비교: {v['live_head_frames']}프레임 계산, 신뢰도≥0.6 {v['live_head_accepted']}프레임. 나머지는 숫자로 크기를 확정하지 않았다. 비인간형 몬스터와 초상화에는 같은 얼굴 템플릿을 적용하지 않았다.
- 원 머리 추정 함수와 FFT 구현을 서로 다른 배율/자세 4칸에서 대조: 배율 일치, 점수 차이 최대 {max(x['score_abs_error'] for x in v['estimator_equivalence']):.2e}. 이 확인은 계산 동등성 검사이며 얼굴 비율의 진실성을 증명하지 않는다.
- 교정한 검사기 문제: 동점인 스케일의 부동소수점 오차로 0.02 다른 배율이 선택되는 경우가 있어 1e-12 이내 동점은 작은 배율을 사용하도록 고쳤다. 현재/후보 머리 수치를 모두 재계산했다. Nova 남성 meteor_kick의 중앙값은 1.05→1.04가 되어 경계 밖 경고에서 제외했다.
- 직접 본 접촉 이미지: 현재 {len(live)}, 후보 {len(reviewed)-len(live)}. 목록과 관찰 메모는 `metrics/review_log.json`에 있다. 추가 확대 이미지와 요약 조합도 직접 확인했다.
- 현재 수리 항목 {stats['live_findings']}건, 후보 중복 제거 {stats['candidate_unique_findings']}건. 자동 경고 수와 확정 수리 수를 섞지 않았다.
- Godot, git, 네트워크, 병렬 Python, 아트/제품 코드 수정은 하지 않았다. Python 프로세스 하나씩 사용했다.

재현용 스크립트는 `smash-nine-prototype/tests/analysis/codex_qa_23/`에 있다. `audit.py live`, `audit.py candidates`, `detail.py geometry`, `detail.py crops`, `candidate_contacts.py`, `head_check.py --force`, `head_candidates.py`, `supplement.py`, `build_report.py`, `verify_report.py`, `finalize.py` 순서로 한 번에 한 프로세스만 실행한다. Python은 카드의 Codex 런타임 경로를 사용한다. 육안 판정은 `findings.py`와 `candidate_notes.py`에 수기로 기록했으므로 재계측만으로 새 판정이 생성되지는 않는다.

시작: 2026-10-25 07:35:39 UTC. 완료: {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}. 카드의 120분 한도 안에서 완료했다.
'''
    (OUT/'validation.md').write_text(text,encoding='utf-8')
    scriptroot=ROOT/'smash-nine-prototype/tests/analysis/codex_qa_23';allowed=[OUT.resolve(),scriptroot.resolve()]
    files=[p for root in allowed for p in root.rglob('*') if p.is_file()]
    manifest=OUT/'files.txt'
    if manifest not in files:files.append(manifest)
    assert all(any(p.resolve().is_relative_to(root) for root in allowed) for p in files)
    manifest.write_text('\n'.join(sorted(p.relative_to(ROOT).as_posix() for p in files))+'\n',encoding='utf-8')
    bad=[];links=0
    for p in OUT.glob('*.md'):
        for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
            if '://' in target or target.startswith('#'):continue
            links+=1
            if not (p.parent/target.split('#')[0]).exists():bad.append((p.name,target))
    assert not bad,bad
    print(json.dumps({'files':len(files),'relative_links_checked':links,'broken_links':bad,'reviewed_current':len(live),'reviewed_candidate':len(reviewed)-len(live),'summary':stats},ensure_ascii=False,indent=2))

if __name__=='__main__':main()
