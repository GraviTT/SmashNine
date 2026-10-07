# CODEX-ANALYST-03 독립 검증 보고

검토 기준: `git diff 3cf868d..HEAD -- smash-nine-prototype/scripts smash-nine-prototype/characters`

결론부터 말하면 P0는 없고, P1 두 건을 재현했다. 가장 큰 제품 결함은 소울 크리스탈이 직접 메서드 호출로는 깨지지만 실제 공격 판정과는 충돌하지 않아 게임 안에서 파괴되지 않는다는 점이다. 또한 카드가 지정한 기존 1:1 분석기는 크리스탈을 제거하지 않아 현재는 순수 결투를 측정하지 않는다.

## Findings

| 심각도 | 컴포넌트 / 규칙 소유자 | 재현 (명령·시드) | 측정 사실 / 추정 | 제안 수정 및 담당 |
|---|---|---|---|---|
| **P1** | 소울 크리스탈 피격·충돌: `SoulCrystal.gd`가 목적물 규칙 소유자. 필요하면 공통 `Attack.gd` 충돌 설정도 함께 확인 | `godot --headless --path . --fixed-fps 60 -s tests/analysis/review03/crystal_ai_access_probe.gd` (seed 303) | **측정:** Frey 봇이 크리스탈을 현재 목표로 잡고 57 px까지 접근해 17회 공격했지만 HP는 3→3, 소울 +0이었다. 이어 크리스탈 중심에 100×100 실제 공격 Area를 강제 생성해도 overlap은 공격자 Frey만 포함하고 크리스탈은 없었다. 실제 8봇 seed 1–3, 각 180초에서도 관찰한 초기 크리스탈 24개 중 파괴 0회였다. 기존 `test_soul_crystals.gd`는 `crystal.apply_hit(...)`를 직접 호출하므로 물리 충돌 결함을 검출하지 못한다. | 리드가 `SoulCrystal`의 실제 PhysicsBody 등록/RID/shape 상태와 공격 mask를 우선 수정. 회귀 테스트는 직접 `apply_hit` 호출이 아니라 실제 `Attack`/`Projectile` Area를 겹쳐 HP 감소와 지급을 확인해야 한다. 소유자는 목적물 규칙상 `SoulCrystal`; 공통 공격 쪽 원인이면 `Attack`에서 고친다. |
| **P1** | 밸런스 분석기: `tests/analysis/duel_probe.gd` (테스트 하네스 소유) | 기존: `... -s tests/analysis/duel_probe.gd -- --seed=1 --first=rio`; 보정: `... -s tests/analysis/review03/duel_probe_clean.gd -- --seed=1 --first=rio` | **측정:** 기존 분석기는 몬스터만 삭제하고 크리스탈은 남긴다. Rio–Frey 8시드 중 4시드는 상호 피해 0, 완료는 1경기뿐이었다. 크리스탈까지 제거한 보정판은 완료 6경기 모두 Frey 승(2회 시간초과)이고 평균 피해 Rio 85.4 / Frey 128.6이었다. 즉 기존 결과는 현재 “순수 1:1” 근거로 쓸 수 없다. | 리드가 기존 분석기에서 크리스탈도 계속 제거하거나 `Main`에 분석용 목적물 비활성 옵션을 둔다. 분석 규칙이므로 수정 소유자는 테스트 하네스이며 제품 전투 규칙을 우회 패치하면 안 된다. |
| **P2** | 크리스탈 붕괴 생명주기: `SoulCrystalSpawner.gd` 소유 | `godot --headless --path . --fixed-fps 60 -s tests/analysis/review03/adversarial_probe.gd` (probe seed 303) | **측정:** `sync_playable_realms([])` 뒤 크리스탈은 삭제 예약되고 다음 프레임에는 사라지지만, 그 프레임 안에서는 `is_realm_active=true`인 채 3타를 받고 10 소울을 지급했다. **추정:** 현재 붕괴는 `Main._process`에서 동기화되고 삭제가 프레임 끝에 일어나므로 일반 물리 공격이 이 창을 실제로 이용할 가능성은 낮다. 직접 호출 경로의 상태 불변식은 깨져 있다. | `queue_free()` 전에 `set_realm_active(false)`로 collision layer와 hit admission을 즉시 닫는다. 수정 소유자는 `SoulCrystalSpawner`/`SoulCrystal` 생명주기다. |
| **P2 (튜닝 신호, 결함 확정 아님)** | Rio 키트·봇: `Rio.gd`, `EnemyAI.gd` | 10시드 스윕: `run_sweep.ps1 -Players 8 -FirstSeed 1 -SeedCount 10 -Seconds 480`; 보정 결투 1–8: `duel_probe_clean.gd` | **측정:** 8인 스윕에서 각 캐릭터 16석으로 동일했고 Rio는 0승, 평균 피해 116.9, 평균 소울 64.8이었다(Frey 5승/195.5, Luna 4승/134.6, Nova 1승/136.3, Yuki 0승/69.8). 보정 결투에서는 Frey에 완료 경기 0–6, Nova에는 완료 경기 3–0이었고 5회 시간초과였다. **추정:** 표본이 작고 서로 다른 상대 신호가 엇갈려 즉시 수치 변경 근거로는 부족하다. Frey 강세는 사용자 보류 사항이다. | 크리스탈과 결투 하네스 P1을 먼저 고친 뒤 30시드 이상 재측정한다. 지금은 Rio 수치를 바꾸지 않는 것이 안전하다. 이후 조정이 필요하면 캐릭터 수치는 `Rio.gd`, 봇 사용성은 `EnemyAI`가 각각 소유한다. |

## 확인했고 정상인 항목

- 차원의 베기: 고체 벽 앞 x=1088.3에서 멈춰 벽 내부로 들어가지 않았다(벽 가까운 면의 안전 중심 한계 x≈1090). 일방통행 발판은 아래→위 이동 시 통과해 y=-150에 도착했고, 위→아래 이동 시 y=-110.5에서 멈췄다. 이후 낙하 test move도 발판 위에서 충돌해 고착이 없었다.
- 블래스트 라인: x=250에서 오른쪽 200 px 사용 시 x=450으로 라인 300을 넘었지만 다음 물리 프레임에 링아웃 1회 후 (0,0)으로 복귀했다. 지형 고착은 없으며 사람의 바깥 방향 사용은 자해성 선택으로 남는다.
- 룬 방패 특수 피격: 일반·강제 발사·스턴·Yuki seal burst 모두 피해 절반, 넉백 0, 경직 0으로 동일했다. 환경 피해 API는 방패를 우회해 7 전부 적용됐고 흡수 횟수는 늘지 않았다. 고정 하자드 `apply_hit`은 설계 문서대로 피해 절반(7→3.5), 넉백 0이었다.
- 룬 방패 다단: 6타를 흡수해도 반격은 문서 상한인 피해 15 / 넉백 820에서 멈췄다. 무한 증폭은 재현되지 않았다.
- 오버드라이브: 시작 시 검 6개, 일반 피격 후 0개로 취소됐다. 방패로 흡수한 타격은 공통 훅 설명(“no ... cancel”)대로 6개가 유지됐다.
- 수풀 은신: 붕괴와 포털 상당의 렐름 변경 뒤 다음 hazard tick에서 즉시 해제됐다. 링아웃 respawn 직후 같은 프레임에는 `concealed=true`가 남았지만 다음 tick에 false가 되어 지속 고착은 아니었다.
- 크리스탈 메서드 규칙 자체: 몬스터 그룹 공격은 거부됐고 HP 3 유지, 플레이어 3타는 보상 10을 한 번만 지급, 추가 4타째는 거부됐다. 다만 실제 물리 공격이 닿지 않는 P1 때문에 현재 게임 플레이에서는 이 정상 경로가 사용되지 않는다.
- 10시드 8인 스윕은 비인증서 엔진 오류 0, NaN 위치 0이었다. 모든 run이 실패로 표시된 유일한 이유는 안내된 샌드박스 인증서 저장소 ERROR 1줄이다.
- 기존 새 기능 테스트 `test_rio_prototype.gd`, `test_soul_crystals.gd`, `test_hazards.gd`는 exit 0이었다. 각 실행에는 알려진 인증서 ERROR 1줄만 있었다.

## 스윕 요약

- 10경기: 마지막 생존 9, 최종 판정 1; 길이 중앙값 297초(P10 254 / P90 414), 300초 미만 5/10.
- 승자: Frey 5, Luna 4, Nova 1, Rio 0, Yuki 0.
- 탈락 원인: 플레이어 58, 몬스터 7, 환경 4.
- 소울 카드 선택 총 161회; 최종 소울 75 이상인 좌석 38/80.
- 실제 크리스탈 파괴는 별도 계측 3시드×180초에서 0회라 크리스탈 파밍 과다는 재현되지 않았다. 이는 경제가 안전해서가 아니라 P1 물리 충돌 결함의 결과다.

## 확인하지 못했거나 제한된 항목

- 실제 사람 조작 감각, 시작 화면 V 체형 전환의 시각 결과, 원본 스프라이트 렌더링은 헤드리스 분석 범위에서 확인하지 않았다.
- 가드 패링과 룬 방패가 동시에 성립하는 실제 입력 상태는 독립 물리 probe로 만들지 않았다. 정적 경로상 패링 판정이 흡수 훅보다 먼저지만, 이를 실행 검증 완료로 간주하지 않는다.
- 전체 `tests/run_all.ps1`은 실행하지 않았다. 대신 변경 기능의 기존 테스트 3개, 신규 adversarial probe, 결투 32회(기존 16 + 보정 16), 8인 스윕 10회, 크리스탈 경제/접근 probe를 실행했다.
- 30시드 이상 통계, 장시간 사람 수풀 캠핑의 재미/공정성 평가는 하지 않았다. Midgard는 타임라인상 붕괴하므로 영구 캠핑은 아니지만 플레이 감각 판단은 남아 있다.

## 산출물

- `smash-nine-prototype/tests/analysis/review03/adversarial_probe.gd`
- `smash-nine-prototype/tests/analysis/review03/duel_probe_clean.gd`
- `smash-nine-prototype/tests/analysis/review03/crystal_economy_probe.gd`
- `smash-nine-prototype/tests/analysis/review03/crystal_ai_access_probe.gd`
- `reports/codex-analyst-03/raw/sweep-8p-s1-10.jsonl`
- `reports/codex-analyst-03/raw/sweep-8p-s1-10.log`

샌드박스에서 `.git`이 쓰기 불가이므로 커밋 대신 `commit.ps1`을 준비했다.
