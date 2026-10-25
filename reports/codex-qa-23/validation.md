# 검증 기록

- 원자료: 현재 이미지 43개, 후보 349개. 입력 해시는 `metrics/input_hashes.json`에 기록했다(사후 식별용이며 변경 전후 대조라고 주장하지 않음).
- 치수/남는 그림 셀/빈 사용 셀 오류: 0. 인접 완전 동일 프레임: 현재 0, 후보 0.
- 현재 캐릭터 머리 비교: 658프레임 계산, 신뢰도≥0.6 445프레임. 나머지는 숫자로 크기를 확정하지 않았다. 비인간형 몬스터와 초상화에는 같은 얼굴 템플릿을 적용하지 않았다.
- 원 머리 추정 함수와 FFT 구현을 서로 다른 배율/자세 4칸에서 대조: 배율 일치, 점수 차이 최대 4.44e-16. 이 확인은 계산 동등성 검사이며 얼굴 비율의 진실성을 증명하지 않는다.
- 교정한 검사기 문제: 동점인 스케일의 부동소수점 오차로 0.02 다른 배율이 선택되는 경우가 있어 1e-12 이내 동점은 작은 배율을 사용하도록 고쳤다. 현재/후보 머리 수치를 모두 재계산했다. Nova 남성 meteor_kick의 중앙값은 1.05→1.04가 되어 경계 밖 경고에서 제외했다.
- 직접 본 접촉 이미지: 현재 43, 후보 70. 목록과 관찰 메모는 `metrics/review_log.json`에 있다. 추가 확대 이미지와 요약 조합도 직접 확인했다.
- 현재 수리 항목 38건, 후보 중복 제거 23건. 자동 경고 수와 확정 수리 수를 섞지 않았다.
- Godot, git, 네트워크, 병렬 Python, 아트/제품 코드 수정은 하지 않았다. Python 프로세스 하나씩 사용했다.

재현용 스크립트는 `smash-nine-prototype/tests/analysis/codex_qa_23/`에 있다. `audit.py live`, `audit.py candidates`, `detail.py geometry`, `detail.py crops`, `candidate_contacts.py`, `head_check.py --force`, `head_candidates.py`, `supplement.py`, `build_report.py`, `verify_report.py`, `finalize.py` 순서로 한 번에 한 프로세스만 실행한다. Python은 카드의 Codex 런타임 경로를 사용한다. 육안 판정은 `findings.py`와 `candidate_notes.py`에 수기로 기록했으므로 재계측만으로 새 판정이 생성되지는 않는다.

시작: 2026-10-25 07:35:39 UTC. 완료: 2026-10-25 08:41:36 UTC. 카드의 120분 한도 안에서 완료했다.
