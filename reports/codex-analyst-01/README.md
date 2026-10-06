# CODEX-ANALYST-01 결과 — M1 diff review 및 밸런스 스윕

분석일: 2026-10-06  
분석 브랜치: `codex/analyst-01` (`db48b18`, 비교 기준 `97130b3`)  
제품 소스 변경: 없음

## 결론

M1 매치 루프는 **측정한 8인 30판과 16인 5판 모두 420초 전에 최후 생존자로 끝났고**, NaN 위치도 없었다. 첫 PvP 피해 중앙값은 8인 4.6초로 M1 기준인 20초 이하를 충분히 만족했다.

그러나 현재 상태를 M1 완료로 승인하기는 어렵다.

1. 같은 붕괴에서 최후의 두 명이 함께 죽으면 **이미 죽은 플레이어가 승자로 확정되는 P0 규칙 결함**이 재현됐다.
2. 결과 화면 뒤에도 전투 physics가 계속되어 **확정된 승자가 다시 죽을 수 있다.**
3. 8인 30판 승자는 Frey 17, Nova 8, Luna 5, Yuki 0으로 크게 치우쳤다.
4. 매치 길이 중앙값은 4분 11초이고 30판 중 23판(76.7%)이 5분 전에 끝나, 목표 5~7분과 후반 페이즈를 충분히 사용하지 못한다.
5. 모든 Godot 프로세스가 `ERROR: Failed to read the root certificate store.`를 출력했다. 카드 규칙상 exit code 0이어도 실패이므로 엄격한 엔진 오류 게이트는 통과하지 못했다.

## 측정 방법

- 실제 `scenes/Main.tscn`을 인스턴스화하고 실제 `MatchDirector`, `PlayerBase`, 캐릭터 스크립트, `EnemyAI`, `SoulGrowth`를 실행했다.
- 제품 규칙은 바꾸지 않았다. 분석 러너는 신호와 공개 상태를 관찰해 JSONL만 기록한다.
- 8인: seed 1~30, `--fixed-fps 60`, 시뮬레이션 상한 480초.
- 16인: seed 101~105, 같은 조건.
- 프로세스는 항상 한 번에 하나만 실행했다.
- 첫 PvP 피해는 기존 `hp_changed + last_attacker` 추정 대신 플레이어의 실제 `damage_dealt` 증가를 프레임별로 관찰했다.
- 분석 코드: `smash-nine-prototype/tests/analysis/`.
- 원시 결과: `raw/results-8p.jsonl`, `raw/results-16p.jsonl`, 전체 stdout/stderr 로그는 `raw/sweep-*.log`.
- 가공 CSV: `data/`.

재현 명령:

```powershell
cd smash-nine-prototype
powershell -ExecutionPolicy Bypass -File tests/analysis/run_sweep.ps1 -Players 8 -FirstSeed 1 -SeedCount 30 -Seconds 480 -OutputJsonl '../reports/codex-analyst-01/raw/results-8p.jsonl' -OutputLog '../reports/codex-analyst-01/raw/sweep-8p.log'
powershell -ExecutionPolicy Bypass -File tests/analysis/run_sweep.ps1 -Players 16 -FirstSeed 101 -SeedCount 5 -Seconds 480 -OutputJsonl '../reports/codex-analyst-01/raw/results-16p.jsonl' -OutputLog '../reports/codex-analyst-01/raw/sweep-16p.log'
```

## Findings — 심각도 순

### P0 — 같은 붕괴에서 최후의 두 명이 죽으면 패배자가 승자가 된다

- 위치: `smash-nine-prototype/scripts/match/MatchDirector.gd:182-193`, `:228-235`.
- 측정 재현: `tests/analysis/rule_probes.gd`, `collapse_last_two`.
- 조건: 실제 Frey와 Yuki를 같은 모서리 렐름에 배치하고 각각 HP 20, `advance(150)`.
- 결과: 두 명 모두 `is_defeated=true`, 생존자 0명인데 `finish_reason="last survivor"`, `winner_id=2`, `winner_is_defeated=true`.
- 원인: 첫 번째 30 피해 사망 콜백이 남은 한 명을 즉시 승자로 확정하지만, `_relocate_trapped_combatants()` 루프가 계속되어 그 승자에게도 30 피해를 적용한다. 이후 콜백은 `match_over` 때문에 무시된다.
- 수정 제안: 붕괴 배치 전체의 이동·피해를 먼저 끝낸 다음 생존자를 한 번만 판정한다. 루프 중간의 `_finish()`를 막는 배치 처리 플래그 또는 MatchDirector 소유의 원자적 환경 피해 단계가 적절하다. 단순히 루프를 `match_over`에서 중단하면 아직 처리되지 않은 플레이어가 피해를 피하므로 우회책이다.
- 소유자: **MatchDirector**.

### P1 — 결과 화면 뒤에도 승자와 봇이 계속 싸우며 승자가 죽을 수 있다

- 위치: `smash-nine-prototype/scripts/Main.gd:170-176`; `PlayerBase.gd:260` 이후 physics는 계속 활성이다.
- 측정 재현: probe seed 801, 2인 실제 Main. 한 명을 탈락시켜 결과를 확정한 뒤 승자의 상태를 검사하고 환경 피해를 적용했다.
- 결과: `winner_physics_processing_after_finish=true`, 추가 피해 후 `winner_can_be_defeated_after_finish=true`, 생존자 0명.
- 영향: 결과 오버레이와 내부 플레이 상태가 모순되고, 백그라운드 AI·투사체·공격 콜백이 결과 통계를 바꿀 수 있다.
- 수정 제안: `_on_match_finished`에서 모든 전투 입력/AI/physics 및 공격 생성만 명시적으로 동결하고, 이미 생성된 공격·투사체를 정리한다. 승자 HP를 사후 보정하는 것은 우회책이다.
- 소유자: **Main의 매치 흐름/종료 전환**. 승자 선정 규칙 자체는 MatchDirector에 유지한다.

### P1 — 포털/붕괴 이동이 공격 선딜레이를 취소하지 않아 새 렐름에서 옛 공격이 발동한다

- 위치: `smash-nine-prototype/characters/common/PlayerBase.gd:728-738`, `:1206-1229`.
- 측정 재현: 실제 Yuki가 기본 공격을 시작한 직후 `reset_for_map(Vector2(5000, 500), ...)`; 0.14초 대기.
- 결과: 공격 시작 위치는 `(100,100)`이었지만 Yuki 투사체가 이동 후 위치 `(5074,466)`에서 생성됐다.
- 영향: 붕괴 강제 이동과 포털 이동이 공격을 정리한 것처럼 보여도 이전 `await` 콜백이 새 렐름의 상대를 공격할 수 있다. 보호 시간은 받는 피해만 막고 이 공격 생성을 막지 않는다.
- 수정 제안: PlayerBase가 공격 세대 ID/cancellation token을 소유하고 `_start_attack` 진입 시 캡처한 ID를 `await` 뒤 확인한다. `reset_for_map`, `_respawn`, `_defeat`, match end에서 ID를 증가시킨다. Main이나 포털 코드에서 특정 캐릭터 공격을 개별 정리하는 방식은 우회책이다.
- 소유자: **PlayerBase 공통 공격 스케줄러**.

### P1 — 모든 시작 2인 페어가 같은 캐릭터라 초기 전투가 전부 미러전이다

- 위치: `smash-nine-prototype/scripts/Main.gd:243-256`.
- 측정 재현: 실제 Main seed 711(8인), 716(16인).
- 결과: 8인은 4/4 렐름, 16인은 8/8 렐름에서 두 캐릭터 ID가 동일했다.
- 원인: 캐릭터 ID 주기 4와 렐름 배치 주기 4(8인) 또는 8(16인)가 맞물려 `i`와 `i+4/8`이 같은 캐릭터로 같은 렐름에 들어간다.
- 영향: 초반 상성 다양성이 사라지고 캐릭터 밸런스 스윕이 교차 매치업 대신 미러전 위주가 된다.
- 수정 제안: 렐름 슬롯 배열과 캐릭터 로스터를 독립적으로 셔플하되 각 렐름의 두 슬롯이 서로 다른 캐릭터가 되도록 제약한다. AI 순간이동이나 사후 캐릭터 보정은 우회책이다.
- 소유자: **Main의 roster/spawn 배치**(향후 SpawnDirector).

### P1 — Frey 과강세, Yuki 무승 및 컨트롤러 AI의 사거리 상실

- 위치: `smash-nine-prototype/scripts/EnemyAI.gd:377-417`; 특히 `_combat_profile()`이 모든 캐릭터에 `attack_range=235`를 반환한다.
- 측정: 8인 30판에서 Frey 17승(56.7%), Yuki 0승. 동일 25% 가정의 단측 확률은 각각 약 0.000216, 0승 확률은 약 0.000179이다. 시드 독립성과 현재 봇 정책을 전제로 한 참고값이다.
- 추가 측정: Frey 평균 PvP 피해 117.4 / 소울 101.4 / 카드 2.23, Yuki 27.7 / 28.8 / 0.57. Yuki 60생명 중 39명(65%)은 카드 한 장도 받지 못했고 전체 빌드 완성은 5명(8.3%)뿐이다.
- 코드 관찰: Yuki 기본 투사체 수명과 속도는 원거리 교전을 지원하지만 AI는 235px 안까지 추격한 뒤 공격한다. 이것이 측정 격차의 단독 원인이라는 것은 아직 가설이다. 낮은 HP/방어/무게와 미러 스폰도 함께 작용한다.
- 수정 제안: 먼저 EnemyAI에 캐릭터별 최소/최대/공격 사거리와 후퇴 선호를 넣어 컨트롤러가 실제 키트 사거리를 사용하게 한다. 그 다음 혼합 스폰으로 다시 측정한 후 캐릭터 수치를 조정한다. 곧바로 Frey 스탯만 낮추면 AI 계약 결함을 가리는 우회책이 된다.
- 소유자: **EnemyAI 전투 프로필 우선**, 이후 각 **캐릭터 데이터/캐릭터 스크립트**.

### P1 — 목표보다 판이 짧고 후반 페이즈가 거의 사용되지 않는다

- 위치: 매치 페이스는 `smash-nine-prototype/scripts/match/MatchDirector.gd:43-67`, 몬스터 위협은 `scripts/RealmMonster.gd:21-27,52-68`이 소유한다.
- 측정: 매치 길이 P10 176.0초(2:56), 중앙값 251.3초(4:11), P90 328.2초(5:28). 23/30판(76.7%)이 5분 전에 종료됐다.
- 페이즈 도달: 2차 붕괴 240초 19/30(63.3%), 서든데스 360초 2/30(6.7%), 최종 판정 420초 0/30.
- 탈락 원인: 플레이어 111/210(52.9%), 몬스터 80/210(38.1%), 환경 19/210(9.0%). 몬스터가 보조 소울 원천이라는 의도에 비해 탈락 기여가 크다.
- 수정 제안: MatchDirector의 전역 피해/회복 페이스와 RealmMonster의 피해·추적을 각각 소유 위치에서 조정하고 30시드를 재실행한다. 타임라인 자체를 앞당겨 짧은 판에 맞추는 것은 5~7분 목표를 포기하는 우회책이다.
- 소유자: **MatchDirector(전역 페이스)** + **RealmMonster(몬스터 위협)**.

### P2 — Last Stand 중첩이 곱연산되어 서든데스 링아웃 피해를 65.7% 줄인다

- 위치: `smash-nine-prototype/scripts/match/SoulCards.gd:6-27`, `characters/common/PlayerBase.gd:242-256`.
- 측정 재현: 실제 Frey에게 `last_stand` 3회 적용 후 40 링아웃 피해를 호출.
- 결과: `ringout_damage_scale=0.343`, 실제 피해 13.72. 동시에 세 카드 공통 성장으로 최대 HP가 151까지 증가했다.
- 스윕 관찰: 2중첩 9명, 3중첩 1명. 중복 보유자 10명 중 승자는 1명뿐이어서 이번 봇 샘플에서 지배적 승리 수단으로 관측되지는 않았다. 반면 Last Stand 보유자 61명 중 52명은 선택 뒤 실제 링아웃을 한 번 이상 겪어 효과 자체는 자주 발동했다.
- 수정 제안: 카드 정의/드로우 단계에서 1회 제한 또는 명시적 감쇠 중첩을 적용하고 카드 문구에 누적식을 표시한다. PlayerBase의 전역 링아웃 피해를 별도 보정하는 것은 다른 규칙까지 흔드는 우회책이다.
- 소유자: **SoulCards 카드 정책**.

### P2 — 봇 자동 선택 신호가 `auto_picked=false`로 기록된다

- 위치: `smash-nine-prototype/scripts/match/SoulGrowth.gd:44-53`.
- 재현: 봇의 0.6초 타임아웃 선택을 `offer_closed`에서 관찰하면 모든 이벤트의 `auto=false`.
- 원인: 타임아웃인데도 `_close_offer(..., player.is_human)`을 전달해 봇은 false, 시간 초과 인간만 true가 된다.
- 영향: 게임 효과는 적용되지만 분석/업적/UI가 신호 의미를 신뢰할 수 없다.
- 수정 제안: 시간 만료 경로는 인간/봇 모두 `auto_picked=true`로 전달한다. 봇만 별도 보정하지 않는다.
- 소유자: **SoulGrowth**.

### P2 — 기존 소크의 `pvp_hits`가 환경 피해를 PvP 피해로 중복 집계한다

- 위치: `smash-nine-prototype/tests/soak_match.gd:137-145`, 공격자 기억은 `characters/common/PlayerBase.gd:1119-1128`.
- 측정 재현: 실제 Frey가 Yuki를 한 번 때린 뒤, 8초 기억 시간 안에 Yuki에게 공격자 없는 환경 피해를 한 번 적용했다.
- 결과: 실제 플레이어 타격 1회 + 환경 피해 1회인데 기존 소크 분류식은 두 `hp_changed`를 모두 플레이어 이벤트로 셌다.
- 영향: 기존 `pvp_hits`/`monster_hits` 총합은 실제 타격 수가 아니다. 첫 PvP 시각은 첫 플레이어 타격 전에는 player `last_attacker`가 존재할 수 없어 상대적으로 안전하지만, 이번 분석은 더 확실한 `damage_dealt` 증가를 사용했다.
- 수정 제안: PlayerBase가 피해 이벤트에 이번 피해의 원인/공격자를 함께 싣거나, 공격자의 `damage_dealt` 증가를 텔레메트리에서 관찰한다. 8초 기억 시간을 줄이는 것은 KO credit 규칙을 바꾸는 우회책이다.
- 소유자: **PlayerBase 피해 이벤트 계약 + soak telemetry**.

### 실행 게이트 차단 — 모든 Godot 실행에 인증서 저장소 오류

- 재현: 분석 35판, 규칙 프로브, 10회 재시작, 기존 테스트 러너의 모든 개별 Godot 프로세스.
- 오류: `ERROR: Failed to read the root certificate store.` / `os_windows.cpp:2582`.
- 로그: `raw/sweep-8p.log`, `raw/sweep-16p.log`.
- 결과: exit code는 대부분 0이고 게임 결과도 생성됐지만, “ERROR 한 줄이면 실패” 규칙 때문에 공식 통과 수는 0이다.
- 수정 제안: 실행 계정이 Windows 루트 인증서 저장소를 읽을 수 있는지 확인하고 Godot 실행 환경에서 해결한다. 테스트 러너가 이 오류를 예외 처리하거나 문자열을 숨기는 것은 카드 규칙을 위반한다.
- 소유자: **테스트 실행 환경 / Godot 런타임 설정**. 제품 룰 소유 컴포넌트가 아니다.

## 8인 밸런스 요약

### 매치 전체

| 항목 | 결과 |
|---|---:|
| 완료 | 30/30, 모두 최후 생존자 |
| 420초 이전 승자 | 30/30 |
| 길이 P10 / 중앙값 / P90 | 176.0 / 251.3 / 328.2초 |
| 5분 미만 종료 | 23/30 (76.7%) |
| 첫 PvP P10 / 중앙값 / P90 | 0.9 / 4.6 / 9.2초 |
| 첫 PvP 20초 이내 | 30/30 |
| 총 링아웃 / 생명당 | 705 / 2.94 |
| NaN 위치 | 0 |
| 엄격한 엔진 오류 통과 | 0/30 (인증서 오류 1건씩) |

### 캐릭터

각 캐릭터는 매치마다 2명, 총 60회 노출됐다. `승자 비중`의 균등 기대값은 25%다.

| 캐릭터 | 승 | 승자 비중 | 평균 PvP 피해 | 평균 소울 | 평균 카드 | 3카드 완성 | 0카드 생명 | 평균 링아웃 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Frey | 17 | **56.7%** | **117.4** | **101.4** | 2.23 | 36/60 | 6/60 | 3.70 |
| Nova | 8 | 26.7% | 84.0 | 98.5 | **2.27** | **39/60** | 6/60 | 2.72 |
| Luna | 5 | 16.7% | 55.9 | 68.9 | 1.78 | 24/60 | 11/60 | 3.13 |
| Yuki | 0 | **0.0%** | **27.7** | **28.8** | **0.57** | **5/60** | **39/60** | 2.20 |

### 소울 카드

- 총 선택 411회. 1/2/3번째 선택 도달자는 각각 178/129/104명이다.
- 선택 시각 중앙값은 49.2 / 87.6 / 131.6초다.
- 전체 생명 240개 중 104개(43.3%)가 3카드를 완성했고 62개(25.8%)는 한 장도 선택하지 못했다.

| 카드 | 선택 수 | 선택 시각 중앙값 | 확인된 의미 |
|---|---:|---:|---|
| Swiftness | 88 | 69.0초 | 즉시 속도 증가; 직접 효용 이벤트는 미계측 |
| Anchor | 74 | 77.4초 | 즉시 넉백 저항 증가; 직접 효용 이벤트는 미계측 |
| Last Stand | 72 | 81.7초 | 보유자 61명 중 52명이 이후 링아웃을 겪어 실제 발동 |
| Sky Step | 68 | 71.2초 | 추가 공중 점프 사용 여부는 미계측 |
| Power | 57 | 76.7초 | 즉시 공격 배율 증가 |
| Vitality | 52 | 93.3초 | 즉시 최대 HP 및 회복 증가 |

완전히 선택되지 않은 카드는 없었다. 다만 카드 선택 빈도는 봇의 시드 기반 무작위 결과이며 효용 순위를 뜻하지 않는다.

## 비정상적으로 강한 것 / 보상받지 못하는 것

### 비정상적으로 강함

- **Frey**: 30판 중 17승, Yuki의 4.2배 PvP 피해. 현 상태에서는 명확한 과강세다.
- **강자 성장 스노우볼**: 피해량과 KO가 소울을 주므로 이미 강한 Frey/Nova가 더 많은 카드를 얻는다. Frey와 Nova는 평균 2.23/2.27장, Yuki는 0.57장이다. 측정된 상관이며 인과 크기는 별도 실험이 필요하다.
- **Last Stand 의도적 중첩 가능성**: 3중첩 시 40 피해가 13.72가 된다. 봇 샘플에서는 지배적 승률로 이어지지 않았지만 인간이 제안될 때마다 고르면 공간 생존 규칙을 크게 약화시킬 수 있다.
- **이동 뒤 지연 공격**: 포털/붕괴 직전 공격 입력으로 새 렐름에서 투사체를 발생시킬 수 있어 재현 가능한 전투 악용 경로다.

### 거의 보상받지 못함 / 사용되지 않음

- **Yuki의 원거리 컨트롤러 정체성**: 공용 235px AI 프로필 때문에 원거리 키트가 봇전에서 사실상 근접 교전하며 0승, 평균 0.57카드에 그쳤다.
- **Yuki의 성장 루프**: 65%가 첫 카드에도 도달하지 못했고 3카드 완성은 8.3%뿐이다. 핵심 성장 시스템이 이 캐릭터에게 거의 작동하지 않는다.
- **6~7분 후반부**: 서든데스는 2/30판에서만 사용됐고 최종 판정은 0/30판이었다. 최종 판정은 안전장치라 미발동 자체가 결함은 아니지만, 5~7분 목표와 합치면 현재 후반 콘텐츠 투자 효율이 낮다.
- **완전히 무효인 카드**는 이번 계측에서 확인되지 않았다. Sky Step의 실제 추가 점프 사용, Anchor가 막은 링아웃 수처럼 직접 효용 이벤트가 없는 항목은 판단할 수 없다.

## 16인 5시드 결과

| seed | 종료(초) | 종료 사유 | 승자 | 첫 PvP(초) | 링아웃 | 벽시계(초) | wall/sim | 최대 노드 | NaN | 엔진 오류 |
|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|
| 101 | 264.7 | last survivor | Nova | 1.8 | 38 | 30.377 | 0.1148 | 1226 | 0 | 1 |
| 102 | 239.1 | last survivor | Yuki | 8.2 | 42 | 36.842 | 0.1541 | 1230 | 0 | 1 |
| 103 | 268.1 | last survivor | Luna | 1.4 | 29 | 51.519 | 0.1922 | 1210 | 0 | 1 |
| 104 | 270.6 | last survivor | Nova | 4.0 | 37 | 58.307 | 0.2155 | 1222 | 0 | 1 |
| 105 | 218.9 | last survivor | Frey | 0.4 | 36 | 43.820 | 0.2002 | 1235 | 0 | 1 |

- 5/5가 420초 전에 끝났고 결과 JSON을 생성했다.
- wall/sim 평균은 0.1754로, 측정 환경에서는 모두 실시간보다 빨랐다.
- 5/5 NaN 0, 중단 0.
- 플레이어 탈락 75건 중 플레이어 59(78.7%), 몬스터 13(17.3%), 환경 3(4.0%).
- 다만 tester의 windowed Godot가 동시에 실행되는 공유 머신이므로 이 값은 상대 성능 신호일 뿐 물리 프레임 P95가 아니다.
- 인증서 오류 때문에 엄격한 성공 판정은 0/5다.

## 검토했으나 별도 결함을 찾지 못한 항목

- 소울을 한 번에 25/50/75 이상 올리면 세 threshold가 모두 발생하고 SoulGrowth가 제안을 순서대로 큐잉한다. 기존 `test_match_rules.gd` 내부 assertion 통과.
- Nova 궁극기는 단계 1→2→3으로 후속 입력되고 Luna는 변신→하트 레이저가 동작하면서 쿨다운은 30초로 유지됐다. `raw/probes.json` 참고.
- 포털/붕괴 이동 시 `layout.assign_combatant()`가 새 렐름 크기·스폰·blast line을 넣고 `ai_controller.reset()`이 경로를 비운다. stale geometry 자체는 재현하지 못했다.
- 10회 `reload_current_scene()`에서 반환 코드가 모두 0이고, 매번 플레이어 8명, 노드 수 1071로 복귀했다. 이전 씬의 pending attack도 별도 `SCRIPT ERROR`를 만들지 않았다. `raw/restart-result.json` 참고.
- 기존 테스트 중 5종은 내부 통과 메시지를 냈고 `visual_preview`도 exit code 0 및 별도 스크립트 오류 없이 끝났다. 하지만 모든 프로세스의 인증서 ERROR 때문에 `tests/run_all.ps1 -SkipSoak` 최종 exit code는 1이었다.

## 시각적 요약

```text
0:00                  2:30          4:00                 6:00        7:00
시작 ───────────────── 1차 붕괴 ───── 2차 붕괴 ─────────── 서든데스 ─── 최종판정
 │                       │             │                    │           │
 ├─ 첫 PvP 중앙값 0:04.6 │             ├─ 19/30 도달        ├─ 2/30     └─ 0/30
 └─ 8인 2명 페어 전부 미러전           └─ 매치 중앙값 4:11

결과 분포:  P10 2:56 ───── 중앙값 4:11 ───── P90 5:28
목표 구간:                              5:00 ─────────────── 7:00
```

위 흐름은 전투 진입은 매우 빠르지만 대부분의 판이 목표 구간 전에 끝나고, 서든데스와 최종 판정이 거의 사용되지 않는다는 뜻이다.

## 사람이 직접 확인해야 할 것

- Frey의 높은 생존/피해가 실제 조작에서도 과강세인지, 아니면 봇이 근접 캐릭터에 유리해서 생긴 것인지.
- Yuki가 사람이 조작할 때 사거리·설치기를 활용하면 회복되는지.
- 2인 미러전 대신 혼합 매치업으로 시작할 때 첫 전투가 읽기 쉽고 재미있는지.
- 30초 붕괴 경고와 30 고정 피해가 납득 가능한지.
- 카드 선택이 실제 전술을 바꾸는지. 특히 Sky Step 사용률, Anchor가 방지한 링아웃, Power가 만든 추가 KO를 이벤트로 계측할 필요가 있다.
- 16인 중앙 난전의 시각적 가독성과 조작감.

## 수행하지 못했거나 확정할 수 없는 것

- windowed Godot 및 실제 입력 검증은 병렬 tester의 범위이므로 실행하지 않았다.
- 인증서 저장소 ERROR를 이 클론의 허용 경로 안에서 해결할 수 없었다. 따라서 “엔진 오류 0” 성공 선언은 할 수 없다.
- 공유 머신에서 tester가 동시에 windowed Godot를 실행했으므로 절대 성능, physics frame P95 16.7ms 기준은 측정하지 못했다.
- 조작감, 타격 명료성, 붕괴 공정성, 중앙전 가독성은 headless 봇으로 판단하지 않았다.
- 카드별 인과 효과는 무작위 관찰 데이터만으로 확정하지 않았다. 직접 효과 이벤트가 없는 Sky Step/Anchor 등은 추가 계측이 필요하다.
- 제품 소스와 기존 테스트는 권한 범위 밖이라 수정하지 않았다. 수정안은 리드에게 제안만 한다.

## 산출물

- `smash-nine-prototype/tests/analysis/analysis_soak.gd`: 실제 매치 관찰 러너.
- `smash-nine-prototype/tests/analysis/run_sweep.ps1`: 순차 시드 실행, 엄격 오류 기록.
- `smash-nine-prototype/tests/analysis/rule_probes.gd`: 붕괴/종료/이동 공격/스폰/카드/궁극기 재현.
- `smash-nine-prototype/tests/analysis/restart_stress.gd`: 10회 실제 씬 reload.
- `smash-nine-prototype/tests/analysis/summarize_results.ps1`: JSONL→CSV 요약.
- `reports/codex-analyst-01/raw/`: 원시 JSONL, 전체 로그, 프로브 결과.
- `reports/codex-analyst-01/data/`: 매치·캐릭터·카드·탈락 원인 CSV.
- `.git`은 쓰기 불가이므로 `reports/codex-analyst-01/commit.ps1`을 준비했다. 허용된 두 경로만 add하고 영어 커밋 메시지 및 `Co-Authored-By`를 포함한다.

## 리드에게 권장하는 수정 순서

1. MatchDirector의 동시 붕괴 승자 판정(P0).
2. Main의 match-over 전투 동결.
3. PlayerBase의 await 공격 취소 토큰.
4. 시작 페어를 혼합 캐릭터로 변경.
5. 캐릭터별 AI 사거리 적용 후 동일 30시드 재측정.
6. 그 다음 Frey/Yuki 수치, 초반 사망 페이스, Last Stand 중첩을 조정.
7. 인증서 저장소 오류를 해결하고 전체 게이트를 오류 0으로 다시 실행.
